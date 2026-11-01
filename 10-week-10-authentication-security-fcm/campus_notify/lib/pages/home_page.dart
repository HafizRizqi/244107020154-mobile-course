
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../providers/announcement_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _subscribed = true;

  Future<void> _toggleTopic(bool value) async {
    try {
      if (value) {
        await subscribeTopic();
      } else {
        await unsubscribeTopic();
      }

      if (!mounted) return;

      setState(() => _subscribed = value);

      _snack(
        value
            ? 'Berhasil berlangganan pengumuman.'
            : 'Berhasil berhenti berlangganan.',
      );
    } catch (e) {
      if (!mounted) return;

      _snack(
        'Gagal mengubah langganan: ${friendlyErrorMessage(e)}',
      );
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Tanggal belum tersedia';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final push = ref.watch(pushSetupProvider);
    final ready = push.value == PushStatus.ready;

    // Mengambil daftar pengumuman dari Cloud Firestore.
    final announcements = ref.watch(
      publishedAnnouncementsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref
                    .read(authStateProvider.notifier)
                    .logout();
              } catch (e) {
                if (!mounted) return;

                _snack(
                  'Gagal logout: ${friendlyErrorMessage(e)}',
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Daftar Pengumuman',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Daftar pengumuman dari Cloud Firestore.
          announcements.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gagal memuat pengumuman.',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friendlyErrorMessage(error),
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref.invalidate(
                          publishedAnnouncementsProvider,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada pengumuman.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pengumuman yang dipublikasikan '
                          'akan muncul di sini.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(12),
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.campaign_outlined,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                            const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(item.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () {
                        context.push(
                          Routes.announcementOf(item.id),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Pengaturan FCM',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status FCM: ${push.when(
                      data: (status) => switch (status) {
                        PushStatus.ready => 'siap',
                        PushStatus.permissionDenied =>
                          'izin notifikasi ditolak',
                        PushStatus.firebaseNotConfigured =>
                          'Firebase belum dikonfigurasi',
                      },
                      loading: () => 'menyiapkan...',
                      error: (error, _) =>
                          'gagal: ${friendlyErrorMessage(error)}',
                    )}',
                  ),
                  const SizedBox(height: 8),

                  // Token ditampilkan dalam bentuk tersamarkan.
                  ValueListenableBuilder<String?>(
                    valueListenable: latestFcmToken,
                    builder: (context, token, _) {
                      return Text(
                        'FCM token: ${maskToken(token)}',
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Topik $topicPengumuman',
                    ),
                    subtitle: const Text(
                      'Menerima pesan yang dikirim '
                      'ke topik ini.',
                    ),
                    value: _subscribed,
                    onChanged: ready
                        ? _toggleTopic
                        : null,
                  ),

                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(pushSetupProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ulangi setup FCM'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

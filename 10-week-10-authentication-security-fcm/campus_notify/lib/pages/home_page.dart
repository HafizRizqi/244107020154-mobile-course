
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
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
      _snack('Gagal mengubah langganan: ${friendlyErrorMessage(e)}');
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final push = ref.watch(pushSetupProvider);
    final ready = push.value == PushStatus.ready;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
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

          // Data sementara. Tahap berikutnya akan menggunakan Firestore.
          for (final id in ['1', '2', '3'])
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text('Pengumuman #$id'),
                subtitle: const Text('Contoh pengumuman'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  Routes.announcementOf(id),
                ),
              ),
            ),

          const SizedBox(height: 16),

          Text(
            'Pengaturan FCM',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Token hanya ditampilkan dalam bentuk tersamarkan.
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
                    title: const Text(
                      'Topik $topicPengumuman',
                    ),
                    subtitle: const Text(
                      'Menerima pesan yang dikirim ke topik ini.',
                    ),
                    value: _subscribed,
                    onChanged: ready ? _toggleTopic : null,
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

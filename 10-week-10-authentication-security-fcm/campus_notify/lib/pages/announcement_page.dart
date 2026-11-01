
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/announcement_provider.dart';
import '../routes.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({
    super.key,
    required this.id,
  });

  final String id;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Tanggal belum tersedia';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(
      announcementDetailProvider(id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.home);
            }
          },
        ),
      ),
      body: announcement.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat detail pengumuman.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(
                      announcementDetailProvider(id),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Pengumuman tidak ditemukan '
                  'atau belum dipublikasikan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 52,
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(_formatDate(item.createdAt)),
                ],
              ),
              const Divider(height: 32),
              Text(
                item.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        },
      ),
    );
  }
}

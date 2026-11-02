import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../providers/notification_provider.dart';
import '../routes.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final currentItems = notifications.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (currentItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAllAsRead(currentItems);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(friendlyErrorMessage(e)),
                    ),
                  );
                }
              },
              child: const Text('Baca semua'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Gagal memuat notifikasi:\n'
              '${friendlyErrorMessage(error)}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56),
                  SizedBox(height: 12),
                  Text('Belum ada notifikasi baru.'),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.notifications_active),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.blue,
                ),
                onTap: () async {
                  try {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(
                          item.id,
                          announcementId: item.announcementId,
                        );

                    if (!context.mounted) return;

                    if (item.announcementId.isNotEmpty) {
                      context.push(
                        Routes.announcementOf(item.announcementId),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(friendlyErrorMessage(e)),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final loggedIn = authState.value ?? false;
  if (!loggedIn) {
    return Stream.value(const <AppNotification>[]);
  }

  return ref.watch(notificationRepositoryProvider).watchNotifications();
});

final unreadNotificationCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(notificationsProvider).whenData(
        (items) => items.where((item) => !item.isRead).length,
      );
});

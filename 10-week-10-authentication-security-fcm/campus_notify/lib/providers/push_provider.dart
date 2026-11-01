
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';

/// Status konfigurasi FCM.
final firebaseReadyProvider = Provider<bool>((ref) => false);

enum PushStatus {
  firebaseNotConfigured,
  permissionDenied,
  ready,
}

final pushSetupProvider = FutureProvider<PushStatus>((ref) async {
  if (!ref.watch(firebaseReadyProvider)) {
    return PushStatus.firebaseNotConfigured;
  }

  final granted = await requestNotificationPermission();

  if (!granted) {
    return PushStatus.permissionDenied;
  }

  await initFcmToken(
    onToken: (token) async {
      // Pengujian FCM tanpa backend API.
      debugPrint('FCM Token: $token');
      debugPrint('Platform: ${Platform.isIOS ? 'ios' : 'android'}');
    },
  );

  return PushStatus.ready;
});

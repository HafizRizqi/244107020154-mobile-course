
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';

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

  if (!granted) return PushStatus.permissionDenied;

  await initFcmToken(
    onToken: (token) async {
      // Token tidak dikirim ke backend contoh.
      // Firebase Messaging tetap mengelola token perangkat.
      debugPrint('[FCM] Token siap: ${maskToken(token)}');
    },
  );

  return PushStatus.ready;
});

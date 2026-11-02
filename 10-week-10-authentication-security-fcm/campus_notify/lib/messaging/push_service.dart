import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'route_parser.dart';

const topicPengumuman = 'pengumuman-kampus';

/// Menyimpan ID notifikasi yang sudah dibunyikan pada sesi ini agar tidak berbunyi ganda.
final Set<String> alreadyNotifiedIds = <String>{};

/// Stream agar saat pesan FCM masuk, daftar notifikasi & ikon lonceng langsung ter-update
/// tanpa perlu menulis ke Firestore (menghindari PERMISSION_DENIED dari Firestore).
final StreamController<void> fcmIncomingStreamController =
    StreamController<void>.broadcast();

const _fcmStorageKey = 'local_fcm_notifications_v1';
const _secureStorage = FlutterSecureStorage();

/// Channel ID baru khusus untuk suara custom `bell_small.wav`
/// (File berada di android/app/src/main/res/raw/bell_small.wav).
const _channel = AndroidNotificationChannel(
  'pengumuman_bell_small_v3', // sama dengan default_notification_channel_id di AndroidManifest.xml
  'Pengumuman Kampus',
  description: 'Notifikasi pengumuman dari kampus',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('bell_small'),
  audioAttributesUsage: AudioAttributesUsage.notification,
);

final _local = FlutterLocalNotificationsPlugin();
bool _localInitialized = false;

/// Token FCM terakhir, untuk ditampilkan (terpotong) di halaman Debug.
final latestFcmToken = ValueNotifier<String?>(null);

/// Deep link yang menunggu router siap (mis. klik banner sebelum router ada).
String? pendingDeepLink;
void Function(String route)? _navigate;

/// Token tidak boleh tampil/log penuh: 12 karakter pertama + ...
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '-';
  return token.length <= 12 ? '$token...' : '${token.substring(0, 12)}...';
}

/// Menyimpan pesan FCM secara lokal agar langsung muncul di ikon lonceng dan daftar notifikasi
/// tanpa memicu error PERMISSION_DENIED di Firestore.
Future<String?> saveFcmMessageLocally(RemoteMessage message) async {
  try {
    final title =
        message.notification?.title ??
        (message.data['title'] as String?) ??
        'Pengumuman Kampus';
    final body =
        message.notification?.body ??
        (message.data['body'] as String?) ??
        (message.data['content'] as String?) ??
        '';
    final announcementId =
        (message.data['id'] as String?) ??
        (message.data['announcementId'] as String?) ??
        '';

    final rawDocId = announcementId.isNotEmpty
        ? announcementId
        : (message.messageId?.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_') ??
              'fcm_${DateTime.now().millisecondsSinceEpoch}');

    alreadyNotifiedIds.add(rawDocId);

    final rawList = await _secureStorage.read(key: _fcmStorageKey);
    final List<Map<String, dynamic>> currentList = [];
    if (rawList != null && rawList.isNotEmpty) {
      final decoded = jsonDecode(rawList);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            currentList.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    final exists = currentList.any((item) => item['id'] == rawDocId);
    if (!exists) {
      currentList.insert(0, {
        'id': rawDocId,
        'title': title,
        'body': body,
        'announcementId': announcementId,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });
      await _secureStorage.write(
        key: _fcmStorageKey,
        value: jsonEncode(currentList),
      );
      fcmIncomingStreamController.add(null);
    }

    return rawDocId;
  } catch (e) {
    debugPrint('[FCM] gagal menyimpan notifikasi lokal: $e');
    return null;
  }
}

/// Membaca daftar pesan FCM yang tersimpan secara lokal.
Future<List<Map<String, dynamic>>> loadLocalFcmMessages() async {
  try {
    final rawList = await _secureStorage.read(key: _fcmStorageKey);
    if (rawList == null || rawList.isEmpty) return const [];
    final decoded = jsonDecode(rawList);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  } catch (e) {
    debugPrint('[FCM] gagal memuat notifikasi lokal: $e');
  }
  return const [];
}

/// Menampilkan notifikasi lokal dengan suara custom `bell_small.wav` (di res/raw/bell_small.wav).
Future<void> showCustomNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  try {
    if (!_localInitialized) {
      await initLocalNotifications();
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('bell_small'),
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'bell_small.wav',
      ),
    );

    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  } catch (e) {
    debugPrint('[Notification] gagal menampilkan notifikasi lokal: $e');
  }
}

// ---------------------------------------------------------------------------
// Background handler: WAJIB fungsi top-level, berjalan di isolate terpisah.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message id=${message.messageId}');
  try {
    await saveFcmMessageLocally(message);
  } catch (e) {
    debugPrint('[FCM] background save error: $e');
  }
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ---------------------------------------------------------------------------
// Permission + local notifications
// ---------------------------------------------------------------------------

/// Android 13+ (POST_NOTIFICATIONS) dan iOS wajib meminta izin runtime.
/// Android <= 12 otomatis "authorized".
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  // Minta izin POST_NOTIFICATIONS juga melalui plugin local notifications di Android 13+
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route != null && route.isNotEmpty) _goOrQueue(route);
    },
  );

  // Android 8+: buat channel dengan custom sound bell_small.wav.
  final androidPlugin = _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_channel);

  _localInitialized = true;

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: false,
  );

  final launch = await _local.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    pendingDeepLink = launch!.notificationResponse?.payload;
  }
}

// ---------------------------------------------------------------------------
// Token lifecycle
// ---------------------------------------------------------------------------
StreamSubscription<String>? _tokenRefreshSub;

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  Future<void> handle(String token) async {
    latestFcmToken.value = token;
    debugPrint('[FCM] token=${maskToken(token)}');
    try {
      await onToken(token);
    } catch (e) {
      debugPrint('[FCM] gagal kirim token ke backend: $e');
    }
  }

  // ignore: deprecated_member_use
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await handle(token);

  await _tokenRefreshSub?.cancel();
  // ignore: deprecated_member_use
  _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(handle);

  await subscribeTopic();
}

Future<void> subscribeTopic() =>
    FirebaseMessaging.instance.subscribeToTopic(topicPengumuman);

Future<void> unsubscribeTopic() =>
    FirebaseMessaging.instance.unsubscribeFromTopic(topicPengumuman);

// ---------------------------------------------------------------------------
// Tiga app state: foreground, background (klik), terminated (klik)
// ---------------------------------------------------------------------------
StreamSubscription<RemoteMessage>? _foregroundSub;
StreamSubscription<RemoteMessage>? _openedAppSub;

void listenForeground(void Function(String route) go) {
  _navigate = go;

  _foregroundSub?.cancel();
  _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
    await saveFcmMessageLocally(message);

    final route = routeFromMessage(message.data);
    await showCustomNotification(
      id: message.hashCode,
      title:
          message.notification?.title ??
          (message.data['title'] as String?) ??
          'Pengumuman',
      body:
          message.notification?.body ??
          (message.data['body'] as String?) ??
          '',
      payload: route,
    );
  });

  _openedAppSub?.cancel();
  _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    await saveFcmMessageLocally(message);
    go(routeFromMessage(message.data));
  });
}

/// Panggil SETELAH router siap.
Future<void> handleTerminated(void Function(String route) go) async {
  _navigate = go;
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    await saveFcmMessageLocally(initial);
    go(routeFromMessage(initial.data));
  }
  final pending = pendingDeepLink;
  if (pending != null) {
    pendingDeepLink = null;
    go(pending);
  }
}

void _goOrQueue(String route) {
  final go = _navigate;
  if (go != null) {
    go(route);
  } else {
    pendingDeepLink = route;
  }
}

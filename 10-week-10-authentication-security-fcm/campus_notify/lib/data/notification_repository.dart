import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../messaging/push_service.dart';
import '../models/announcement.dart';
import '../models/app_notification.dart';
import '../routes.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterSecureStorage _storage;

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FlutterSecureStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? const FlutterSecureStorage();

  final Set<String> _localReadIds = <String>{};
  final Set<String> _existingUnreadUserNotifIds = <String>{};
  bool _localReadLoaded = false;
  String? _loadedUid;
  bool _canUpdateFirestoreNotifs = true;

  String? _baselineUid;
  bool _initialUserNotifsBaselineDone = false;
  bool _initialAnnouncementsBaselineDone = false;

  final StreamController<void> _localChangeController =
      StreamController<void>.broadcast();

  String get _storageKey =>
      'read_notifications_${_auth.currentUser?.uid ?? "guest"}';

  Future<void> _ensureLocalReadLoaded() async {
    final currentUid = _auth.currentUser?.uid;
    if (_baselineUid != currentUid) {
      _baselineUid = currentUid;
      _initialUserNotifsBaselineDone = false;
      _initialAnnouncementsBaselineDone = false;
    }

    if (_localReadLoaded && _loadedUid == currentUid) return;

    _localReadIds.clear();
    _loadedUid = currentUid;
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _localReadIds.addAll(decoded.map((e) => e.toString()));
        }
      }
    } catch (e) {
      debugPrint('[NotificationRepository] gagal memuat read state lokal: $e');
    }
    _localReadLoaded = true;
  }

  Future<void> _saveLocalReadIds() async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_localReadIds.toList()),
      );
    } catch (e) {
      debugPrint('[NotificationRepository] gagal menyimpan read state: $e');
    }
  }

  CollectionReference<Map<String, dynamic>>? _userNotificationsRef() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  /// Memantau daftar notifikasi yang BELUM DIBACA dari:
  /// 1. Subkoleksi `users/{uid}/notifications`
  /// 2. Koleksi `announcements` yang `isPublished == true` (jika diisi manual di Firestore)
  /// 3. Pesan FCM yang diterima dari Firebase Cloud Messaging
  Stream<List<AppNotification>> watchNotifications() {
    late StreamController<List<AppNotification>> controller;
    StreamSubscription? userNotifSub;
    StreamSubscription? announcementSub;
    StreamSubscription? localChangeSub;
    StreamSubscription? fcmIncomingSub;

    List<AppNotification> latestUserNotifs = const [];
    List<Announcement> latestAnnouncements = const [];

    Future<void> emitCombined() async {
      await _ensureLocalReadLoaded();
      final localFcmList = await loadLocalFcmMessages();

      final Map<String, AppNotification> merged = {};
      _existingUnreadUserNotifIds.clear();

      // 1. Data dari users/{uid}/notifications di Firestore
      for (final notif in latestUserNotifs) {
        if (!notif.isRead) {
          _existingUnreadUserNotifIds.add(notif.id);
        }

        final isRead =
            notif.isRead ||
            _localReadIds.contains(notif.id) ||
            (notif.announcementId.isNotEmpty &&
                _localReadIds.contains(notif.announcementId));

        merged[notif.id] = AppNotification(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          announcementId: notif.announcementId,
          isRead: isRead,
          createdAt: notif.createdAt,
        );
      }

      // 2. Data dari koleksi `announcements` yang diisi manual di Firestore
      for (final ann in latestAnnouncements) {
        final alreadyInMerged = merged.values.any(
          (n) => n.id == ann.id || n.announcementId == ann.id,
        );

        final isRead = _localReadIds.contains(ann.id);

        if (!alreadyInMerged) {
          merged[ann.id] = AppNotification(
            id: ann.id,
            title: ann.title,
            body: ann.content,
            announcementId: ann.id,
            isRead: isRead,
            createdAt: ann.createdAt != null
                ? Timestamp.fromDate(ann.createdAt!)
                : null,
          );
        }
      }

      // 3. Data dari pesan FCM yang dikirim lewat Firebase Messaging
      for (final fcmItem in localFcmList) {
        final id = (fcmItem['id'] as String?) ?? '';
        if (id.isEmpty) continue;

        final announcementId = (fcmItem['announcementId'] as String?) ?? '';
        final alreadyInMerged = merged.values.any(
          (n) =>
              n.id == id ||
              (announcementId.isNotEmpty &&
                  (n.id == announcementId ||
                      n.announcementId == announcementId)),
        );

        if (!alreadyInMerged) {
          final isRead =
              _localReadIds.contains(id) ||
              (announcementId.isNotEmpty &&
                  _localReadIds.contains(announcementId));
          final createdAtMs = fcmItem['createdAtMs'] as int?;

          merged[id] = AppNotification(
            id: id,
            title: (fcmItem['title'] as String?) ?? 'Pengumuman Kampus',
            body: (fcmItem['body'] as String?) ?? '',
            announcementId: announcementId,
            isRead: isRead,
            createdAt: createdAtMs != null
                ? Timestamp.fromMillisecondsSinceEpoch(createdAtMs)
                : null,
          );
        }
      }

      final allItems = merged.values.toList();

      // Filter hanya yang BELUM DIBACA (!item.isRead) agar jika sudah dibaca
      // langsung hilang dari list notifikasi dan ikon lonceng.
      final unreadList = allItems.where((item) => !item.isRead).toList();

      unreadList.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

      if (!controller.isClosed) {
        controller.add(unreadList);
      }
    }

    controller = StreamController<List<AppNotification>>.broadcast(
      onListen: () {
        final userRef = _userNotificationsRef();
        if (userRef != null) {
          userNotifSub = userRef.snapshots().listen(
            (snapshot) async {
              await _ensureLocalReadLoaded();
              final docs = snapshot.docs
                  .map(AppNotification.fromFirestore)
                  .toList();

              if (!_initialUserNotifsBaselineDone) {
                for (final d in docs) {
                  alreadyNotifiedIds.add(d.id);
                  if (d.announcementId.isNotEmpty) {
                    alreadyNotifiedIds.add(d.announcementId);
                  }
                }
                _initialUserNotifsBaselineDone = true;
              } else {
                for (final d in docs) {
                  final isNew =
                      !alreadyNotifiedIds.contains(d.id) &&
                      (d.announcementId.isEmpty ||
                          !alreadyNotifiedIds.contains(d.announcementId));
                  if (isNew) {
                    alreadyNotifiedIds.add(d.id);
                    if (d.announcementId.isNotEmpty) {
                      alreadyNotifiedIds.add(d.announcementId);
                    }
                    final isRead =
                        d.isRead ||
                        _localReadIds.contains(d.id) ||
                        (d.announcementId.isNotEmpty &&
                            _localReadIds.contains(d.announcementId));
                    if (!isRead) {
                      showCustomNotification(
                        id: d.id.hashCode,
                        title: d.title,
                        body: d.body,
                        payload: d.announcementId.isNotEmpty
                            ? Routes.announcementOf(d.announcementId)
                            : Routes.notifications,
                      );
                    }
                  }
                }
              }

              latestUserNotifs = docs;
              await emitCombined();
            },
            onError: (_) {
              _initialUserNotifsBaselineDone = true;
              emitCombined();
            },
          );
        } else {
          _initialUserNotifsBaselineDone = true;
        }

        announcementSub = _firestore
            .collection('announcements')
            .where('isPublished', isEqualTo: true)
            .snapshots()
            .listen(
              (snapshot) async {
                await _ensureLocalReadLoaded();
                final docs = snapshot.docs
                    .map(Announcement.fromFirestore)
                    .toList();

                if (!_initialAnnouncementsBaselineDone) {
                  for (final a in docs) {
                    alreadyNotifiedIds.add(a.id);
                  }
                  _initialAnnouncementsBaselineDone = true;
                } else {
                  for (final a in docs) {
                    if (!alreadyNotifiedIds.contains(a.id)) {
                      alreadyNotifiedIds.add(a.id);
                      if (!_localReadIds.contains(a.id)) {
                        showCustomNotification(
                          id: a.id.hashCode,
                          title: a.title,
                          body: a.content,
                          payload: Routes.announcementOf(a.id),
                        );
                      }
                    }
                  }
                }

                latestAnnouncements = docs;
                await emitCombined();
              },
              onError: (_) {
                _initialAnnouncementsBaselineDone = true;
                emitCombined();
              },
            );

        localChangeSub = _localChangeController.stream.listen((_) {
          emitCombined();
        });

        fcmIncomingSub = fcmIncomingStreamController.stream.listen((_) {
          emitCombined();
        });
      },
      onCancel: () async {
        await userNotifSub?.cancel();
        await announcementSub?.cancel();
        await localChangeSub?.cancel();
        await fcmIncomingSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> markAsRead(
    String notificationId, {
    String? announcementId,
  }) async {
    await _ensureLocalReadLoaded();
    _localReadIds.add(notificationId);
    if (announcementId != null && announcementId.isNotEmpty) {
      _localReadIds.add(announcementId);
    }
    await _saveLocalReadIds();
    _localChangeController.add(null);

    if (_canUpdateFirestoreNotifs &&
        _existingUnreadUserNotifIds.contains(notificationId)) {
      try {
        final userRef = _userNotificationsRef();
        if (userRef != null) {
          await userRef.doc(notificationId).update({'isRead': true});
        }
      } catch (_) {
        _canUpdateFirestoreNotifs = false;
      }
    }
  }

  Future<void> markAllAsRead(List<AppNotification> currentItems) async {
    await _ensureLocalReadLoaded();
    for (final item in currentItems) {
      _localReadIds.add(item.id);
      if (item.announcementId.isNotEmpty) {
        _localReadIds.add(item.announcementId);
      }
    }
    await _saveLocalReadIds();
    _localChangeController.add(null);

    if (_canUpdateFirestoreNotifs && _existingUnreadUserNotifIds.isNotEmpty) {
      try {
        final userRef = _userNotificationsRef();
        if (userRef == null) return;

        final batch = _firestore.batch();
        for (final docId in _existingUnreadUserNotifIds) {
          batch.update(userRef.doc(docId), {'isRead': true});
        }
        await batch.commit();
      } catch (_) {
        _canUpdateFirestoreNotifs = false;
      }
    }
  }
}

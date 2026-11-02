import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Announcement>> watchPublishedAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(Announcement.fromFirestore)
          .toList();

      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  Stream<Announcement?> watchAnnouncement(String id) {
    return _firestore
        .collection('announcements')
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final announcement = Announcement.fromFirestore(doc);

      if (!announcement.isPublished) return null;

      return announcement;
    });
  }
}


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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(Announcement.fromFirestore)
          .toList();
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

      // Dokumen draft tidak ditampilkan pada halaman detail.
      if (!announcement.isPublished) return null;

      return announcement;
    });
  }
}

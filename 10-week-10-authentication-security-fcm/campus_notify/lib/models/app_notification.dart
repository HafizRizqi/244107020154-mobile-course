import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String announcementId;
  final bool isRead;
  final Timestamp? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.announcementId,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    Timestamp? parsedTimestamp;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedTimestamp = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      final parsedDate = DateTime.tryParse(rawCreatedAt);
      if (parsedDate != null) {
        parsedTimestamp = Timestamp.fromDate(parsedDate);
      }
    }

    final rawTitle = (data['title'] as String?)?.trim();
    final rawBody =
        (data['body'] as String?) ?? (data['content'] as String?) ?? '';

    return AppNotification(
      id: doc.id,
      title: (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : 'Notifikasi Kampus',
      body: rawBody,
      announcementId:
          (data['announcementId'] as String?) ??
          (data['id'] as String?) ??
          '',
      isRead: data['isRead'] is bool ? data['isRead'] as bool : false,
      createdAt: parsedTimestamp,
    );
  }
}

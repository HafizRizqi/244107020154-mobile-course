import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isPublished,
  });

  final String id;
  final String title;
  final String content;
  final DateTime? createdAt;
  final bool isPublished;

  factory Announcement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawCreatedAt = data['createdAt'];

    DateTime? parsedDate;
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt);
    }

    final rawTitle = (data['title'] as String?)?.trim();
    final rawContent =
        (data['content'] as String?) ?? (data['body'] as String?) ?? '';

    return Announcement(
      id: doc.id,
      title: (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : 'Tanpa judul',
      content: rawContent,
      createdAt: parsedDate,
      // Default true jika dibuat manual di Firestore tanpa field isPublished
      isPublished: data['isPublished'] is bool
          ? data['isPublished'] as bool
          : true,
    );
  }
}


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
    final timestamp = data['createdAt'];

    return Announcement(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa judul',
      content: data['content'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : null,
      isPublished: data['isPublished'] as bool? ?? false,
    );
  }
}

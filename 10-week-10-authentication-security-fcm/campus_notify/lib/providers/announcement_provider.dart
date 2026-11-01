
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcement_repository.dart';
import '../models/announcement.dart';

final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final publishedAnnouncementsProvider =
    StreamProvider<List<Announcement>>((ref) {
  return ref
      .watch(announcementRepositoryProvider)
      .watchPublishedAnnouncements();
});

final announcementDetailProvider =
    StreamProvider.family<Announcement?, String>((ref, id) {
  return ref
      .watch(announcementRepositoryProvider)
      .watchAnnouncement(id);
});

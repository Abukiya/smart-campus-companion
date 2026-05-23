import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../Models/announcement_model.dart';
import '../Models/schedule_model.dart';

class CacheService {
  static const String _scheduleBox = 'schedules';
  static const String _announcementBox = 'announcements';
  static const String _scheduleKey = 'today_schedule';
  static const String _announcementKey = 'announcements_list';

  // Open all Hive boxes - call this in main() after Hive.initFlutter()
  static Future<void> openBoxes() async {
    await Hive.openBox(_scheduleBox);
    await Hive.openBox(_announcementBox);
  }

  // --- Schedule cache ---

  Future<void> cacheSchedule(List<ScheduleModel> schedules) async {
    final box = Hive.box(_scheduleBox);
    final encoded = schedules.map((s) => jsonEncode(s.toMap())).toList();
    await box.put(_scheduleKey, encoded);
  }

  List<ScheduleModel> getCachedSchedule() {
    try {
      final box = Hive.box(_scheduleBox);
      final encoded = box.get(_scheduleKey) as List?;
      if (encoded == null) return [];

      return encoded
          .map((e) => ScheduleModel.fromMap(jsonDecode(e), ''))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- Announcement cache ---

  Future<void> cacheAnnouncements(List<AnnouncementModel> announcements) async {
    final box = Hive.box(_announcementBox);
    final encoded = announcements.map((a) => jsonEncode(a.toMap())).toList();
    await box.put(_announcementKey, encoded);
  }

  List<AnnouncementModel> getCachedAnnouncements() {
    try {
      final box = Hive.box(_announcementBox);
      final encoded = box.get(_announcementKey) as List?;
      if (encoded == null) return [];

      return encoded
          .map((e) => AnnouncementModel.fromMap(jsonDecode(e), ''))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- Clear cache ---

  Future<void> clearAll() async {
    await Hive.box(_scheduleBox).clear();
    await Hive.box(_announcementBox).clear();
  }
}

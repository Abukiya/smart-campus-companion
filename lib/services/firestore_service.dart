import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../models/announcement_model.dart';
import '../models/staff_model.dart';
import '../models/location_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SCHEDULES ────────────────────────────────────────

  // Get today's schedule for a user
  Future<List<ScheduleModel>> getTodaySchedule(String userId) async {
    final today = _getDayName(DateTime.now().weekday);
    try {
      final snap = await _db
          .collection('schedules')
          .where('user_id', isEqualTo: userId)
          .where('day_of_week', isEqualTo: today)
          .where('is_active', isEqualTo: true)
          .get();

      final list = snap.docs
          .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by start time
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    } catch (e) {
      return [];
    }
  }

  // Get full week schedule
  Future<List<ScheduleModel>> getWeekSchedule(String userId) async {
    try {
      final snap = await _db
          .collection('schedules')
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      return snap.docs
          .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────

  // Get announcements stream (real-time)
  Stream<List<AnnouncementModel>> getAnnouncementsStream({
    String? category,
    String? department,
  }) {
    Query query = _db
        .collection('announcements')
        .orderBy('published_at', descending: true)
        .limit(50);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => AnnouncementModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .where((a) =>
              department == null ||
              a.targetDepartment == 'ALL' ||
              a.targetDepartment == department)
          .toList();
    });
  }

  // Get single announcement
  Future<AnnouncementModel?> getAnnouncement(String id) async {
    try {
      final doc = await _db.collection('announcements').doc(id).get();
      if (!doc.exists) return null;
      return AnnouncementModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Post announcement (staff only)
  Future<String?> postAnnouncement({
    required String title,
    required String body,
    required String category,
    required bool isUrgent,
    required String postedBy,
    required String postedByName,
    required String targetDepartment,
  }) async {
    try {
      final doc = await _db.collection('announcements').add({
        'title': title,
        'body': body,
        'category': category,
        'is_urgent': isUrgent,
        'posted_by': postedBy,
        'posted_by_name': postedByName,
        'target_department': targetDepartment,
        'published_at': DateTime.now().toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // Delete announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get staff's own announcements
  Future<List<AnnouncementModel>> getMyAnnouncements(String staffId) async {
    try {
      final snap = await _db
          .collection('announcements')
          .where('posted_by', isEqualTo: staffId)
          .orderBy('published_at', descending: true)
          .get();

      return snap.docs
          .map((doc) =>
              AnnouncementModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── STAFF DIRECTORY ──────────────────────────────────

  // Get all staff
  Future<List<StaffModel>> getStaff({
    String? query,
    String? department,
    String? role,
  }) async {
    try {
      Query q = _db.collection('staff_profiles');

      if (department != null) {
        q = q.where('department', isEqualTo: department);
      }

      final snap = await q.get();
      List<StaffModel> list = snap.docs
          .map((doc) => StaffModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by search query locally
      if (query != null && query.isNotEmpty) {
        final q2 = query.toLowerCase();
        list = list
            .where((s) =>
                s.fullName.toLowerCase().contains(q2) ||
                s.role.toLowerCase().contains(q2) ||
                s.department.toLowerCase().contains(q2) ||
                (s.specialization?.toLowerCase().contains(q2) ?? false))
            .toList();
      }

      if (role != null) {
        list = list.where((s) => s.role.toLowerCase().contains(role)).toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  // Get staff member by ID
  Future<StaffModel?> getStaffById(String id) async {
    try {
      final doc = await _db.collection('staff_profiles').doc(id).get();
      if (!doc.exists) return null;
      return StaffModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ─── LOCATIONS ────────────────────────────────────────

  // Get all campus locations
  Future<List<LocationModel>> getLocations({String? type, String? query}) async {
    try {
      Query q = _db.collection('locations');

      if (type != null) {
        q = q.where('location_type', isEqualTo: type);
      }

      final snap = await q.get();
      List<LocationModel> list = snap.docs
          .map((doc) => LocationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (query != null && query.isNotEmpty) {
        final q2 = query.toLowerCase();
        list = list
            .where((l) =>
                l.name.toLowerCase().contains(q2) ||
                l.buildingCode.toLowerCase().contains(q2) ||
                (l.description?.toLowerCase().contains(q2) ?? false))
            .toList();
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  // Get location by ID
  Future<LocationModel?> getLocationById(String id) async {
    try {
      final doc = await _db.collection('locations').doc(id).get();
      if (!doc.exists) return null;
      return LocationModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ─── HELPERS ──────────────────────────────────────────

  String _getDayName(int weekday) {
    const days = [
      'monday', 'tuesday', 'wednesday',
      'thursday', 'friday', 'saturday', 'sunday'
    ];
    return days[weekday - 1];
  }
}

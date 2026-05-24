import 'package:cloud_firestore/cloud_firestore.dart';

/// Run this once to populate all Firestore collections with test data.
/// Call DataSeeder.seed(userId) from any screen during development.
/// REMOVE before final submission.
class DataSeeder {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seed(String userId) async {
    await Future.wait([
      _seedSchedules(userId),
      _seedAnnouncements(),
      _seedStaffProfiles(),
      _seedLocations(),
    ]);
  }

  // ─── SCHEDULES ────────────────────────────────────────

  static Future<void> _seedSchedules(String userId) async {
    final schedules = [
      // Sunday
      {'user_id': userId, 'course_name': 'Data Structures', 'course_code': 'CSE-302',
       'room': 'Room 204', 'building': 'Block B', 'day_of_week': 'sunday',
       'start_time': '08:00', 'end_time': '09:30', 'lecturer_name': 'Dr. Haile Tadesse',
       'lecturer_id': 'staff_001', 'status': 'active', 'is_active': true},
      {'user_id': userId, 'course_name': 'Software Engineering', 'course_code': 'CSE-401',
       'room': 'Lab 3', 'building': 'Block A', 'day_of_week': 'sunday',
       'start_time': '10:00', 'end_time': '11:30', 'lecturer_name': 'Dr. Meron Alemu',
       'lecturer_id': 'staff_002', 'status': 'active', 'is_active': true},
      {'user_id': userId, 'course_name': 'Computer Networks', 'course_code': 'CSE-310',
       'room': 'Room 110', 'building': 'Block C', 'day_of_week': 'sunday',
       'start_time': '14:00', 'end_time': '15:30', 'lecturer_name': 'Mr. Yonas Bekele',
       'lecturer_id': 'staff_003', 'status': 'active', 'is_active': true},
      // Monday
      {'user_id': userId, 'course_name': 'Data Structures', 'course_code': 'CSE-302',
       'room': 'Room 204', 'building': 'Block B', 'day_of_week': 'monday',
       'start_time': '08:00', 'end_time': '09:30', 'lecturer_name': 'Dr. Haile Tadesse',
       'lecturer_id': 'staff_001', 'status': 'active', 'is_active': true},
      {'user_id': userId, 'course_name': 'Database Systems', 'course_code': 'CSE-305',
       'room': 'Room 301', 'building': 'Block C', 'day_of_week': 'monday',
       'start_time': '11:00', 'end_time': '12:30', 'lecturer_name': 'Dr. Meron Alemu',
       'lecturer_id': 'staff_002', 'status': 'active', 'is_active': true},
      // Tuesday
      {'user_id': userId, 'course_name': 'Software Engineering', 'course_code': 'CSE-401',
       'room': 'Lab 3', 'building': 'Block A', 'day_of_week': 'tuesday',
       'start_time': '10:00', 'end_time': '11:30', 'lecturer_name': 'Dr. Meron Alemu',
       'lecturer_id': 'staff_002', 'status': 'active', 'is_active': true},
      {'user_id': userId, 'course_name': 'Computer Networks', 'course_code': 'CSE-310',
       'room': 'Room 110', 'building': 'Block C', 'day_of_week': 'tuesday',
       'start_time': '14:00', 'end_time': '15:30', 'lecturer_name': 'Mr. Yonas Bekele',
       'lecturer_id': 'staff_003', 'status': 'room_changed', 'new_room': 'Auditorium A', 'is_active': true},
      // Wednesday
      {'user_id': userId, 'course_name': 'Algorithms', 'course_code': 'CSE-401',
       'room': 'Room 204', 'building': 'Block B', 'day_of_week': 'wednesday',
       'start_time': '08:00', 'end_time': '09:30', 'lecturer_name': 'Dr. Haile Tadesse',
       'lecturer_id': 'staff_001', 'status': 'cancelled', 'is_active': true},
      {'user_id': userId, 'course_name': 'Database Systems', 'course_code': 'CSE-305',
       'room': 'Room 301', 'building': 'Block C', 'day_of_week': 'wednesday',
       'start_time': '14:00', 'end_time': '15:30', 'lecturer_name': 'Dr. Meron Alemu',
       'lecturer_id': 'staff_002', 'status': 'active', 'is_active': true},
      // Thursday
      {'user_id': userId, 'course_name': 'Data Structures', 'course_code': 'CSE-302',
       'room': 'Room 204', 'building': 'Block B', 'day_of_week': 'thursday',
       'start_time': '08:00', 'end_time': '09:30', 'lecturer_name': 'Dr. Haile Tadesse',
       'lecturer_id': 'staff_001', 'status': 'active', 'is_active': true},
      // Friday
      {'user_id': userId, 'course_name': 'Computer Networks', 'course_code': 'CSE-310',
       'room': 'Room 110', 'building': 'Block C', 'day_of_week': 'friday',
       'start_time': '10:00', 'end_time': '11:30', 'lecturer_name': 'Mr. Yonas Bekele',
       'lecturer_id': 'staff_003', 'status': 'active', 'is_active': true},
      {'user_id': userId, 'course_name': 'Software Engineering', 'course_code': 'CSE-401',
       'room': 'Lab 3', 'building': 'Block A', 'day_of_week': 'friday',
       'start_time': '13:00', 'end_time': '14:30', 'lecturer_name': 'Dr. Meron Alemu',
       'lecturer_id': 'staff_002', 'status': 'active', 'is_active': true},
    ];

    final batch = _db.batch();
    for (final s in schedules) {
      batch.set(_db.collection('schedules').doc(), s);
    }
    await batch.commit();
    print('✓ Schedules seeded (${schedules.length} documents)');
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────

  static Future<void> _seedAnnouncements() async {
    final now = DateTime.now();
    final announcements = [
      {'title': 'Room change — Data Structures', 'body': 'Today\'s 8:00 AM Data Structures class has been moved from Room 204 to Auditorium A in the Main Block due to a room allocation conflict. Please proceed directly to Auditorium A.',
       'category': 'urgent', 'is_urgent': true, 'posted_by': 'staff_001',
       'posted_by_name': 'Dr. Haile Tadesse', 'target_department': 'CSE',
       'published_at': now.subtract(const Duration(minutes: 15)).toIso8601String(), 'is_read': false},
      {'title': 'Quiz reminder — Software Engineering', 'body': 'A short quiz will be held at the start of Thursday\'s Software Engineering session. Topics covered: UML diagrams and design patterns. Please come prepared.',
       'category': 'academic', 'is_urgent': false, 'posted_by': 'staff_002',
       'posted_by_name': 'Dr. Meron Alemu', 'target_department': 'CSE',
       'published_at': now.subtract(const Duration(hours: 2)).toIso8601String(), 'is_read': false},
      {'title': 'Final exam timetable — May 2026', 'body': 'The official final examination timetable has been released. Please check your exam dates, times, and venues carefully. Any conflicts must be reported to the registrar within 48 hours.',
       'category': 'exam', 'is_urgent': false, 'posted_by': 'admin001',
       'posted_by_name': 'Registrar Office', 'target_department': 'ALL',
       'published_at': now.subtract(const Duration(hours: 5)).toIso8601String(), 'is_read': false},
      {'title': 'Library extended hours during exam week', 'body': 'The university library will remain open until midnight from May 22 to May 30 to support students during the examination period. Quiet study zones are available on all floors.',
       'category': 'general', 'is_urgent': false, 'posted_by': 'admin002',
       'posted_by_name': 'Student Services', 'target_department': 'ALL',
       'published_at': now.subtract(const Duration(days: 1)).toIso8601String(), 'is_read': true},
      {'title': 'Computer Networks — class cancelled', 'body': 'The Computer Networks lecture scheduled for Wednesday 14:00 has been cancelled. Students should review Chapter 7 (TCP/IP) independently. The next session will proceed as normal.',
       'category': 'urgent', 'is_urgent': true, 'posted_by': 'staff_003',
       'posted_by_name': 'Mr. Yonas Bekele', 'target_department': 'CSE',
       'published_at': now.subtract(const Duration(days: 2)).toIso8601String(), 'is_read': true},
      {'title': 'Welcome to Campus Companion', 'body': 'Campus Companion is now live for all ASTU students. You can view your timetable, receive instant alerts for room changes and cancellations, find buildings on the campus map, and contact staff directly. Pull down on any screen to refresh.',
       'category': 'general', 'is_urgent': false, 'posted_by': 'admin001',
       'posted_by_name': 'Admin Office', 'target_department': 'ALL',
       'published_at': now.subtract(const Duration(days: 3)).toIso8601String(), 'is_read': true},
    ];

    final batch = _db.batch();
    for (final a in announcements) {
      batch.set(_db.collection('announcements').doc(), a);
    }
    await batch.commit();
    print('✓ Announcements seeded (${announcements.length} documents)');
  }

  // ─── STAFF PROFILES ───────────────────────────────────

  static Future<void> _seedStaffProfiles() async {
    final staff = [
      {'id': 'staff_001', 'full_name': 'Dr. Haile Tadesse', 'role': 'Lecturer',
       'department': 'CSE', 'school': 'Engineering & IT',
       'email': 'haile.tadesse@astu.edu.et', 'phone_extension': '2045',
       'office_location': 'Block B · Room 312 · 3rd floor',
       'office_hours': 'Mon & Wed 2:00–4:00 PM',
       'specialization': 'Algorithms, Data Structures',
       'courses': ['Data Structures (CSE-302)', 'Algorithms (CSE-401)'],
       'location_id': 'block_b'},
      {'id': 'staff_002', 'full_name': 'Dr. Meron Alemu', 'role': 'Lecturer',
       'department': 'CSE', 'school': 'Engineering & IT',
       'email': 'meron.alemu@astu.edu.et', 'phone_extension': '2046',
       'office_location': 'Block B · Room 310 · 3rd floor',
       'office_hours': 'Tue & Thu 1:00–3:00 PM',
       'specialization': 'Software Engineering, UML',
       'courses': ['Software Engineering (CSE-401)', 'Database Systems (CSE-305)'],
       'location_id': 'block_b'},
      {'id': 'staff_003', 'full_name': 'Mr. Yonas Bekele', 'role': 'Lecturer',
       'department': 'CSE', 'school': 'Engineering & IT',
       'email': 'yonas.bekele@astu.edu.et', 'phone_extension': '2047',
       'office_location': 'Block A · Room 205 · 2nd floor',
       'office_hours': 'Mon, Wed & Fri 9:00–11:00 AM',
       'specialization': 'Computer Networks, Security',
       'courses': ['Computer Networks (CSE-310)'],
       'location_id': 'block_a'},
      {'id': 'staff_004', 'full_name': 'Dr. Tigist Worku', 'role': 'Lecturer',
       'department': 'CHEM', 'school': 'Natural Sciences',
       'email': 'tigist.worku@astu.edu.et',
       'office_location': 'Block C · Room 102',
       'office_hours': 'Tue & Thu 2:00–4:00 PM',
       'courses': ['General Chemistry', 'Organic Chemistry'],
       'location_id': 'block_c'},
      {'id': 'staff_005', 'full_name': 'Ato Biruk Tadesse', 'role': 'Registrar',
       'department': 'ADMIN', 'school': 'Administrative',
       'email': 'registrar@astu.edu.et', 'phone_extension': '1001',
       'office_location': 'Admin Block · Room 001 · Ground floor',
       'office_hours': 'Mon–Fri 8:00 AM–5:00 PM',
       'location_id': 'registrar'},
      {'id': 'staff_006', 'full_name': 'W/ro Selam Girma', 'role': 'Department Secretary',
       'department': 'CSE', 'school': 'Engineering & IT',
       'email': 'cse.secretary@astu.edu.et', 'phone_extension': '2040',
       'office_location': 'Block B · Room 301 · 3rd floor',
       'office_hours': 'Mon–Fri 8:30 AM–4:30 PM',
       'location_id': 'block_b'},
    ];

    final batch = _db.batch();
    for (final s in staff) {
      final id = s['id'] as String;
      final data = Map<String, dynamic>.from(s)..remove('id');
      batch.set(_db.collection('staff_profiles').doc(id), data);
    }
    await batch.commit();
    print('✓ Staff profiles seeded (${staff.length} documents)');
  }

  // ─── CAMPUS LOCATIONS ─────────────────────────────────

  static Future<void> _seedLocations() async {
    final locations = [
      {'id': 'main', 'name': 'Main Block', 'building_code': 'MAIN',
       'location_type': 'building', 'latitude': 8.5648, 'longitude': 39.2921,
       'description': 'Main administrative building · Auditorium A on ground floor'},
      {'id': 'block_a', 'name': 'Block A', 'building_code': 'BLOCK-A',
       'location_type': 'building', 'latitude': 8.5642, 'longitude': 39.2918,
       'description': 'Engineering lectures · Computer Lab 1 on 1st floor'},
      {'id': 'block_b', 'name': 'Block B', 'building_code': 'BLOCK-B',
       'location_type': 'building', 'latitude': 8.5650, 'longitude': 39.2925,
       'description': 'CSE department · Lecturer offices on 3rd floor'},
      {'id': 'block_c', 'name': 'Block C', 'building_code': 'BLOCK-C',
       'location_type': 'building', 'latitude': 8.5638, 'longitude': 39.2924,
       'description': 'Science labs · Room 301 on 3rd floor'},
      {'id': 'library', 'name': 'Library', 'building_code': 'LIB',
       'location_type': 'service', 'latitude': 8.5644, 'longitude': 39.2915,
       'description': 'Main university library · Open until midnight during exam week'},
      {'id': 'cafeteria', 'name': 'Cafeteria', 'building_code': 'CAF',
       'location_type': 'service', 'latitude': 8.5640, 'longitude': 39.2928,
       'description': 'Main cafeteria · Open 7:00 AM – 8:00 PM'},
      {'id': 'admin', 'name': 'Admin Block', 'building_code': 'ADMIN',
       'location_type': 'office', 'latitude': 8.5635, 'longitude': 39.2920,
       'description': 'Administrative offices · Registrar on ground floor'},
      {'id': 'lab1', 'name': 'Computer Lab 1', 'building_code': 'BLOCK-A',
       'location_type': 'lab', 'floor': '1st', 'latitude': 8.5641, 'longitude': 39.2917,
       'description': 'CSE computer laboratory · 40 workstations'},
      {'id': 'hall1', 'name': 'Auditorium A', 'building_code': 'MAIN',
       'location_type': 'lecture_hall', 'floor': 'Ground', 'latitude': 8.5647, 'longitude': 39.2920,
       'description': 'Main auditorium · Capacity 300'},
      {'id': 'registrar', 'name': 'Registrar Office', 'building_code': 'ADMIN',
       'location_type': 'office', 'floor': 'Ground', 'latitude': 8.5634, 'longitude': 39.2919,
       'description': 'Room 001 · Opposite main entrance'},
      {'id': 'room204', 'name': 'Room 204', 'building_code': 'BLOCK-B',
       'location_type': 'lecture_hall', 'floor': '2nd', 'latitude': 8.5651, 'longitude': 39.2926,
       'description': 'Block B · 2nd floor · Capacity 60 · Turn right at top of stairs'},
      {'id': 'lab3', 'name': 'Lab 3', 'building_code': 'BLOCK-A',
       'location_type': 'lab', 'floor': '1st', 'latitude': 8.5643, 'longitude': 39.2919,
       'description': 'Software engineering lab · 30 workstations'},
    ];

    final batch = _db.batch();
    for (final l in locations) {
      final id = l['id'] as String;
      final data = Map<String, dynamic>.from(l)..remove('id');
      batch.set(_db.collection('locations').doc(id), data);
    }
    await batch.commit();
    print('✓ Locations seeded (${locations.length} documents)');
  }
}

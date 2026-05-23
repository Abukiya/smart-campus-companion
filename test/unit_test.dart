import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_compaion/Models/user_model.dart';
import 'package:smart_campus_compaion/Models/schedule_model.dart';
import 'package:smart_campus_compaion/Models/announcement_model.dart';
import 'package:smart_campus_compaion/Models/staff_model.dart';

void main() {
  // ─── USER MODEL TESTS ────────────────────────────────

  group('UserModel', () {
    late UserModel student;
    late UserModel staff;

    setUp(() {
      student = UserModel(
        id: 'uid_001',
        fullName: 'Dawit Alemu',
        email: 'dawit@astu.edu.et',
        role: 'student',
        department: 'CSE',
        yearOfStudy: '3rd',
        createdAt: DateTime(2026, 1, 1),
      );

      staff = UserModel(
        id: 'uid_002',
        fullName: 'Dr. Haile Tadesse',
        email: 'haile@astu.edu.et',
        role: 'staff',
        department: 'CSE',
        createdAt: DateTime(2026, 1, 1),
      );
    });

    test('UT-01: isStudent returns true for student role', () {
      expect(student.isStudent, true);
      expect(student.isStaff, false);
    });

    test('UT-02: isStaff returns true for staff role', () {
      expect(staff.isStaff, true);
      expect(staff.isStudent, false);
    });

    test('UT-03: initials returns correct two-letter initials', () {
      expect(student.initials, 'DA');
      expect(staff.initials, 'DH');
    });

    test('UT-04: fromMap correctly parses Firestore document', () {
      final map = {
        'full_name': 'Yared Kebede',
        'email': 'yared@astu.edu.et',
        'role': 'student',
        'department': 'CIVIL',
        'year_of_study': '2nd',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final user = UserModel.fromMap(map, 'uid_003');
      expect(user.fullName, 'Yared Kebede');
      expect(user.role, 'student');
      expect(user.department, 'CIVIL');
    });

    test('UT-05: toMap produces correct Firestore map', () {
      final map = student.toMap();
      expect(map['full_name'], 'Dawit Alemu');
      expect(map['role'], 'student');
      expect(map['department'], 'CSE');
    });

    test('UT-06: single-name user returns first letter as initials', () {
      final user = UserModel(
        id: 'uid_004',
        fullName: 'Tigist',
        email: 't@astu.edu.et',
        role: 'student',
        department: 'CHEM',
        createdAt: DateTime.now(),
      );
      expect(user.initials, 'T');
    });
  });

  // ─── SCHEDULE MODEL TESTS ─────────────────────────────

  group('ScheduleModel', () {
    late ScheduleModel activeClass;
    late ScheduleModel cancelledClass;
    late ScheduleModel roomChangedClass;

    setUp(() {
      activeClass = ScheduleModel(
        id: 'sch_001',
        userId: 'uid_001',
        courseName: 'Data Structures',
        courseCode: 'CSE-302',
        room: 'Room 204',
        building: 'Block B',
        dayOfWeek: 'monday',
        startTime: '08:00',
        endTime: '09:30',
        lecturerName: 'Dr. Haile Tadesse',
        lecturerId: 'uid_002',
        status: 'active',
      );

      cancelledClass = ScheduleModel(
        id: 'sch_002',
        userId: 'uid_001',
        courseName: 'Software Engineering',
        courseCode: 'CSE-401',
        room: 'Lab 3',
        building: 'Block A',
        dayOfWeek: 'tuesday',
        startTime: '10:00',
        endTime: '11:30',
        lecturerName: 'Dr. Meron Alemu',
        lecturerId: 'uid_003',
        status: 'cancelled',
      );

      roomChangedClass = ScheduleModel(
        id: 'sch_003',
        userId: 'uid_001',
        courseName: 'Computer Networks',
        courseCode: 'CSE-310',
        room: 'Room 110',
        building: 'Block C',
        dayOfWeek: 'wednesday',
        startTime: '14:00',
        endTime: '15:30',
        lecturerName: 'Mr. Yonas Bekele',
        lecturerId: 'uid_004',
        status: 'room_changed',
        newRoom: 'Auditorium A',
      );
    });

    test('UT-07: isActive returns true for active status', () {
      expect(activeClass.isActive, true);
      expect(activeClass.isCancelled, false);
    });

    test('UT-08: isCancelled returns true for cancelled status', () {
      expect(cancelledClass.isCancelled, true);
      expect(cancelledClass.isActive, false);
    });

    test('UT-09: isRoomChanged returns true for room_changed status', () {
      expect(roomChangedClass.isRoomChanged, true);
    });

    test('UT-10: displayRoom returns newRoom when status is room_changed', () {
      expect(roomChangedClass.displayRoom, 'Auditorium A');
    });

    test('UT-11: displayRoom returns original room when status is active', () {
      expect(activeClass.displayRoom, 'Room 204');
    });

    test('UT-12: fromMap correctly parses Firestore document', () {
      final map = {
        'user_id': 'uid_001',
        'course_name': 'Database Systems',
        'course_code': 'CSE-305',
        'room': 'Room 301',
        'building': 'Block C',
        'day_of_week': 'thursday',
        'start_time': '08:00',
        'end_time': '09:30',
        'lecturer_name': 'Dr. Test',
        'lecturer_id': 'uid_005',
        'status': 'active',
      };
      final schedule = ScheduleModel.fromMap(map, 'sch_004');
      expect(schedule.courseName, 'Database Systems');
      expect(schedule.dayOfWeek, 'thursday');
      expect(schedule.status, 'active');
    });
  });

  // ─── ANNOUNCEMENT MODEL TESTS ─────────────────────────

  group('AnnouncementModel', () {
    late AnnouncementModel urgentAnnouncement;
    late AnnouncementModel generalAnnouncement;

    setUp(() {
      urgentAnnouncement = AnnouncementModel(
        id: 'ann_001',
        title: 'Room change — Data Structures',
        body: 'Moved to Auditorium A',
        category: 'urgent',
        isUrgent: true,
        postedBy: 'uid_002',
        postedByName: 'Dr. Haile Tadesse',
        targetDepartment: 'CSE',
        publishedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      );

      generalAnnouncement = AnnouncementModel(
        id: 'ann_002',
        title: 'Library extended hours',
        body: 'Library open until midnight',
        category: 'general',
        isUrgent: false,
        postedBy: 'uid_005',
        postedByName: 'Student Services',
        targetDepartment: 'ALL',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      );
    });

    test('UT-13: categoryLabel returns correct label', () {
      expect(urgentAnnouncement.categoryLabel, 'Urgent');
      expect(generalAnnouncement.categoryLabel, 'General');
    });

    test('UT-14: timeAgo returns correct relative time', () {
      expect(urgentAnnouncement.timeAgo, contains('min ago'));
      expect(generalAnnouncement.timeAgo, contains('hrs ago'));
    });

    test('UT-15: isRead state can be updated', () {
      expect(urgentAnnouncement.isRead, false);
      urgentAnnouncement.isRead = true;
      expect(urgentAnnouncement.isRead, true);
    });

    test('UT-16: fromMap correctly parses announcement', () {
      final map = {
        'title': 'Quiz this Thursday',
        'body': 'Short quiz on UML diagrams',
        'category': 'academic',
        'is_urgent': false,
        'posted_by': 'uid_002',
        'posted_by_name': 'Dr. Meron Alemu',
        'target_department': 'CSE',
        'published_at': DateTime.now().toIso8601String(),
        'is_read': false,
      };
      final ann = AnnouncementModel.fromMap(map, 'ann_003');
      expect(ann.title, 'Quiz this Thursday');
      expect(ann.category, 'academic');
      expect(ann.isUrgent, false);
    });

    test('UT-17: toMap produces all required fields', () {
      final map = urgentAnnouncement.toMap();
      expect(map.containsKey('title'), true);
      expect(map.containsKey('body'), true);
      expect(map.containsKey('category'), true);
      expect(map.containsKey('is_urgent'), true);
      expect(map.containsKey('target_department'), true);
    });
  });

  // ─── STAFF MODEL TESTS ────────────────────────────────

  group('StaffModel', () {
    late StaffModel lecturer;

    setUp(() {
      lecturer = StaffModel(
        id: 'staff_001',
        fullName: 'Dr. Haile Tadesse',
        role: 'Lecturer',
        department: 'CSE',
        school: 'Engineering & IT',
        email: 'haile.tadesse@astu.edu.et',
        phoneExtension: '2045',
        officeLocation: 'Block B · Room 312 · 3rd floor',
        officeHours: 'Mon & Wed 2:00–4:00 PM',
        courses: ['Data Structures (CSE-302)', 'Algorithms (CSE-401)'],
      );
    });

    test('UT-18: initials returns correct letters', () {
      expect(lecturer.initials, 'DH');
    });

    test('UT-19: fromMap correctly parses staff document', () {
      final map = {
        'full_name': 'Mr. Yonas Bekele',
        'role': 'Lecturer',
        'department': 'CSE',
        'school': 'Engineering & IT',
        'email': 'yonas@astu.edu.et',
        'courses': ['Computer Networks'],
      };
      final staff = StaffModel.fromMap(map, 'staff_002');
      expect(staff.fullName, 'Mr. Yonas Bekele');
      expect(staff.courses.length, 1);
    });

    test('UT-20: toMap produces correct output', () {
      final map = lecturer.toMap();
      expect(map['full_name'], 'Dr. Haile Tadesse');
      expect(map['email'], 'haile.tadesse@astu.edu.et');
      expect(map['phone_extension'], '2045');
    });
  });
}

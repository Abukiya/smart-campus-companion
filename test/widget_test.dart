import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_compaion/widgets/class_card.dart';
import 'package:smart_campus_compaion/widgets/announcement_card.dart';
import 'package:smart_campus_compaion/widgets/bottom_nav.dart';
import 'package:smart_campus_compaion/Models/schedule_model.dart';
import 'package:smart_campus_compaion/Models/announcement_model.dart';
import 'package:smart_campus_compaion/core/constants/app_colors.dart';

void main() {
  // ─── CLASS CARD WIDGET TESTS ──────────────────────────

  group('ClassCard widget', () {
    Widget buildCard(ScheduleModel schedule) {
      return MaterialApp(
        home: Scaffold(body: ClassCard(schedule: schedule)),
      );
    }

    testWidgets('IT-01: displays course name', (tester) async {
      final schedule = ScheduleModel(
        id: 's1',
        userId: 'u1',
        courseName: 'Data Structures',
        courseCode: 'CSE-302',
        room: 'Room 204',
        building: 'Block B',
        dayOfWeek: 'monday',
        startTime: '08:00',
        endTime: '09:30',
        lecturerName: 'Dr. Haile Tadesse',
        lecturerId: 'l1',
      );
      await tester.pumpWidget(buildCard(schedule));
      expect(find.text('Data Structures'), findsOneWidget);
    });

    testWidgets('IT-02: displays room and building', (tester) async {
      final schedule = ScheduleModel(
        id: 's2',
        userId: 'u1',
        courseName: 'Software Engineering',
        courseCode: 'CSE-401',
        room: 'Lab 3',
        building: 'Block A',
        dayOfWeek: 'tuesday',
        startTime: '10:00',
        endTime: '11:30',
        lecturerName: 'Dr. Meron Alemu',
        lecturerId: 'l2',
      );
      await tester.pumpWidget(buildCard(schedule));
      expect(find.textContaining('Lab 3'), findsOneWidget);
      expect(find.textContaining('Block A'), findsOneWidget);
    });

    testWidgets('IT-03: shows cancelled badge for cancelled class', (
      tester,
    ) async {
      final schedule = ScheduleModel(
        id: 's3',
        userId: 'u1',
        courseName: 'Networks',
        courseCode: 'CSE-310',
        room: 'Room 110',
        building: 'Block C',
        dayOfWeek: 'wednesday',
        startTime: '14:00',
        endTime: '15:30',
        lecturerName: 'Mr. Yonas',
        lecturerId: 'l3',
        status: 'cancelled',
      );
      await tester.pumpWidget(buildCard(schedule));
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('IT-04: shows room changed badge and new room', (tester) async {
      final schedule = ScheduleModel(
        id: 's4',
        userId: 'u1',
        courseName: 'Algorithms',
        courseCode: 'CSE-401',
        room: 'Room 204',
        building: 'Block B',
        dayOfWeek: 'thursday',
        startTime: '08:00',
        endTime: '09:30',
        lecturerName: 'Dr. Haile',
        lecturerId: 'l1',
        status: 'room_changed',
        newRoom: 'Auditorium A',
      );
      await tester.pumpWidget(buildCard(schedule));
      expect(find.text('Room changed'), findsOneWidget);
      expect(find.textContaining('Auditorium A'), findsOneWidget);
    });

    testWidgets('IT-05: calls onTap when tapped', (tester) async {
      bool tapped = false;
      final schedule = ScheduleModel(
        id: 's5',
        userId: 'u1',
        courseName: 'Test Course',
        courseCode: 'TST-101',
        room: 'Room 1',
        building: 'Block A',
        dayOfWeek: 'friday',
        startTime: '08:00',
        endTime: '09:30',
        lecturerName: 'Dr. Test',
        lecturerId: 'l5',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassCard(schedule: schedule, onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.byType(ClassCard));
      expect(tapped, true);
    });
  });

  // ─── ANNOUNCEMENT CARD TESTS ──────────────────────────

  group('AnnouncementCard widget', () {
    Widget buildCard(AnnouncementModel announcement) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnnouncementCard(announcement: announcement),
          ),
        ),
      );
    }

    testWidgets('IT-06: displays announcement title', (tester) async {
      final ann = AnnouncementModel(
        id: 'a1',
        title: 'Room change — Data Structures',
        body: 'Moved to Auditorium A',
        category: 'urgent',
        isUrgent: true,
        postedBy: 'l1',
        postedByName: 'Dr. Haile',
        targetDepartment: 'CSE',
        publishedAt: DateTime.now(),
        isRead: false,
      );
      await tester.pumpWidget(buildCard(ann));
      expect(find.text('Room change — Data Structures'), findsOneWidget);
    });

    testWidgets('IT-07: shows unread dot for unread announcement', (
      tester,
    ) async {
      final ann = AnnouncementModel(
        id: 'a2',
        title: 'Test announcement',
        body: 'Test body',
        category: 'general',
        isUrgent: false,
        postedBy: 'l1',
        postedByName: 'Admin',
        targetDepartment: 'ALL',
        publishedAt: DateTime.now(),
        isRead: false,
      );
      await tester.pumpWidget(buildCard(ann));
      // Unread dot is a Container with circular decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasUnreadDot = containers.any((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.shape == BoxShape.circle &&
            decoration?.color == AppColors.primary;
      });
      expect(hasUnreadDot, true);
    });

    testWidgets('IT-08: shows correct category label', (tester) async {
      final ann = AnnouncementModel(
        id: 'a3',
        title: 'Quiz reminder',
        body: 'Quiz on UML',
        category: 'academic',
        isUrgent: false,
        postedBy: 'l2',
        postedByName: 'Dr. Meron',
        targetDepartment: 'CSE',
        publishedAt: DateTime.now(),
        isRead: true,
      );
      await tester.pumpWidget(buildCard(ann));
      expect(find.text('Academic'), findsOneWidget);
    });

    testWidgets('IT-09: calls onTap when card is tapped', (tester) async {
      bool tapped = false;
      final ann = AnnouncementModel(
        id: 'a4',
        title: 'Test',
        body: 'Body',
        category: 'general',
        isUrgent: false,
        postedBy: 'l1',
        postedByName: 'Admin',
        targetDepartment: 'ALL',
        publishedAt: DateTime.now(),
        isRead: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementCard(
                announcement: ann,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AnnouncementCard));
      expect(tapped, true);
    });
  });

  // ─── BOTTOM NAV TESTS ─────────────────────────────────

  group('BottomNav widget', () {
    testWidgets('IT-10: renders all 5 nav items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNav(currentIndex: 0, onTap: (_) {}),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Directory'), findsOneWidget);
    });

    testWidgets('IT-11: calls onTap with correct index', (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNav(
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Timetable'));
      expect(tappedIndex, 1);
    });

    testWidgets('IT-12: highlights correct active item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNav(currentIndex: 2, onTap: (_) {}),
          ),
        ),
      );
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 2);
    });
  });
}

class ScheduleModel {
  final String id;
  final String userId;
  final String courseName;
  final String courseCode;
  final String room;
  final String building;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String lecturerName;
  final String lecturerId;
  final String status; // 'active' | 'cancelled' | 'room_changed'
  final String? newRoom; // set when status is room_changed

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.courseCode,
    required this.room,
    required this.building,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.lecturerName,
    required this.lecturerId,
    this.status = 'active',
    this.newRoom,
  });

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isRoomChanged => status == 'room_changed';

  String get displayRoom => isRoomChanged && newRoom != null ? newRoom! : room;

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      userId: map['user_id'] ?? '',
      courseName: map['course_name'] ?? '',
      courseCode: map['course_code'] ?? '',
      room: map['room'] ?? '',
      building: map['building'] ?? '',
      dayOfWeek: map['day_of_week'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      lecturerName: map['lecturer_name'] ?? '',
      lecturerId: map['lecturer_id'] ?? '',
      status: map['status'] ?? 'active',
      newRoom: map['new_room'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'course_name': courseName,
      'course_code': courseCode,
      'room': room,
      'building': building,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'lecturer_name': lecturerName,
      'lecturer_id': lecturerId,
      'status': status,
      'new_room': newRoom,
    };
  }

  // Check if this class is happening now
  bool isNow() {
    final now = DateTime.now();
    final todayDay = _getDayName(now.weekday);
    if (todayDay != dayOfWeek.toLowerCase()) return false;

    final parts1 = startTime.split(':');
    final parts2 = endTime.split(':');
    final start = DateTime(now.year, now.month, now.day,
        int.parse(parts1[0]), int.parse(parts1[1]));
    final end = DateTime(now.year, now.month, now.day,
        int.parse(parts2[0]), int.parse(parts2[1]));

    return now.isAfter(start) && now.isBefore(end);
  }

  // Check if this class is the next upcoming one today
  bool isUpNext() {
    final now = DateTime.now();
    final todayDay = _getDayName(now.weekday);
    if (todayDay != dayOfWeek.toLowerCase()) return false;

    final parts = startTime.split(':');
    final start = DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));

    return now.isBefore(start);
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}

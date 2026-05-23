class StaffModel {
  final String id;
  final String fullName;
  final String role;
  final String department;
  final String school;
  final String email;
  final String? phoneExtension;
  final String? officeLocation;
  final String? officeHours;
  final String? specialization;
  final List<String> courses;
  final String? avatarUrl;
  final String? locationId; // links to CampusLocation for map

  StaffModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.department,
    required this.school,
    required this.email,
    this.phoneExtension,
    this.officeLocation,
    this.officeHours,
    this.specialization,
    this.courses = const [],
    this.avatarUrl,
    this.locationId,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map, String id) {
    return StaffModel(
      id: id,
      fullName: map['full_name'] ?? '',
      role: map['role'] ?? 'Lecturer',
      department: map['department'] ?? '',
      school: map['school'] ?? '',
      email: map['email'] ?? '',
      phoneExtension: map['phone_extension'],
      officeLocation: map['office_location'],
      officeHours: map['office_hours'],
      specialization: map['specialization'],
      courses: List<String>.from(map['courses'] ?? []),
      avatarUrl: map['avatar_url'],
      locationId: map['location_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'role': role,
      'department': department,
      'school': school,
      'email': email,
      'phone_extension': phoneExtension,
      'office_location': officeLocation,
      'office_hours': officeHours,
      'specialization': specialization,
      'courses': courses,
      'avatar_url': avatarUrl,
      'location_id': locationId,
    };
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'student' | 'staff' | 'admin'
  final String department;
  final String? yearOfStudy; // null for staff
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.department,
    this.yearOfStudy,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isStaff => role == 'staff' || role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      department: map['department'] ?? '',
      yearOfStudy: map['year_of_study'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'role': role,
      'department': department,
      'year_of_study': yearOfStudy,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}

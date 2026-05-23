class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String category; // 'urgent' | 'academic' | 'general' | 'exam'
  final bool isUrgent;
  final String postedBy;
  final String postedByName;
  final String targetDepartment; // department code or 'ALL'
  final DateTime publishedAt;
  final DateTime? expiresAt;
  bool isRead;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isUrgent,
    required this.postedBy,
    required this.postedByName,
    required this.targetDepartment,
    required this.publishedAt,
    this.expiresAt,
    this.isRead = false,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      category: map['category'] ?? 'general',
      isUrgent: map['is_urgent'] ?? false,
      postedBy: map['posted_by'] ?? '',
      postedByName: map['posted_by_name'] ?? '',
      targetDepartment: map['target_department'] ?? 'ALL',
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'])
          : DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
      isRead: map['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'is_urgent': isUrgent,
      'posted_by': postedBy,
      'posted_by_name': postedByName,
      'target_department': targetDepartment,
      'published_at': publishedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_read': isRead,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String get categoryLabel {
    switch (category) {
      case 'urgent': return 'Urgent';
      case 'academic': return 'Academic';
      case 'exam': return 'Exam';
      default: return 'General';
    }
  }
}

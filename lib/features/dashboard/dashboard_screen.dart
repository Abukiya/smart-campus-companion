import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../Models/schedule_model.dart';
import '../../Models/announcement_model.dart';
import '../../Models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cache_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/class_card.dart';
import '../../widgets/announcement_card.dart';
import '../timetable/timetable_screen.dart';
import '../announcements/announcements_screen.dart';
import '../map/map_screen.dart';
import '../directory/directory_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _cacheService = CacheService();

  static const _navTransitionDuration = Duration(milliseconds: 240);
  static const _pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  int _currentNavIndex = 0;
  UserModel? _user;
  List<ScheduleModel> _todaySchedule = [];
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _user = await _authService.getCurrentUserModel();
      if (_user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      // Load schedule safely
      try {
        _todaySchedule = await _firestoreService.getTodaySchedule(_user!.id);
      } catch (e) {
        _todaySchedule = [];
      }

      // Load announcements safely
      try {
        final stream = _firestoreService.getAnnouncementsStream(
          department: _user!.department,
        );
        _announcements = await stream.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => [],
        );
      } catch (e) {
        _announcements = [];
      }

      // Cache for offline
      try {
        await _cacheService.cacheSchedule(_todaySchedule);
        await _cacheService.cacheAnnouncements(_announcements);
      } catch (e) {
        // Cache failure is non-critical
      }
    } catch (e) {
      // Fall back to cache on any error
      _isOffline = true;
      _todaySchedule = _cacheService.getCachedSchedule();
      _announcements = _cacheService.getCachedAnnouncements();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDayLabel() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  int get _unreadCount => _announcements.isEmpty
      ? 0
      : _announcements.where((a) => !a.isRead).length;

  ScheduleModel? _findNextClass() {
    for (final schedule in _todaySchedule) {
      if (schedule.isNow()) return schedule;
    }
    for (final schedule in _todaySchedule) {
      if (schedule.isUpNext()) return schedule;
    }
    return _todaySchedule.isEmpty ? null : _todaySchedule.first;
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    final destinations = {
      1: () => const TimetableScreen(),
      2: () => const AnnouncementsScreen(),
      3: () => const MapScreen(),
      4: () => const DirectoryScreen(),
    };

    setState(() => _currentNavIndex = index);

    if (destinations.containsKey(index)) {
      Navigator.push(
        context,
        _fadeRoute(destinations[index]!()),
      ).then((_) => setState(() => _currentNavIndex = 0));
    }
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _navTransitionDuration,
      reverseTransitionDuration: _navTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (_isOffline) _offlineBanner(),
                    _headerSection(),
                    Padding(
                      padding: _pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._urgentAlerts(),
                          _statCards(),
                          const SizedBox(height: 24),
                          _sectionHeader(
                            AppStrings.todaySchedule,
                            () => _onNavTap(1),
                          ),
                          const SizedBox(height: 10),
                          _scheduleList(),
                          const SizedBox(height: 24),
                          _sectionHeader(
                            AppStrings.recentAnnouncements,
                            () => _onNavTap(2),
                          ),
                          const SizedBox(height: 10),
                          _announcementList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _offlineBanner() => Container(
    color: AppColors.primaryLight,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: const Row(
      children: [
        Icon(Icons.wifi_off, size: 14, color: AppColors.primaryDark),
        SizedBox(width: 6),
        Text(
          AppStrings.offlineBanner,
          style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
        ),
      ],
    ),
  );

  Widget _headerSection() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryLight, AppColors.background],
      ),
    ),
    child: Padding(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_topBar(), const SizedBox(height: 16), _overviewCard()],
      ),
    ),
  );

  Widget _topBar() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${_user?.fullName.split(' ').first ?? 'Student'} 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_getDayLabel()} · ${_todaySchedule.length} classes today',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _onNavTap(2),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.urgent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      GestureDetector(
        onTap: _showProfileMenu,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _user?.initials ?? '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _overviewCard() {
    final nextClass = _findNextClass();
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _onNavTap(1),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDayLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.todaySchedule,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _overviewMetric(
                    _todaySchedule.length.toString(),
                    AppStrings.classesToday,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextClass == null
                                ? 'No upcoming class'
                                : nextClass.courseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextClass == null
                                ? 'Enjoy your free time'
                                : '${nextClass.startTime} • ${nextClass.room}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewMetric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );

  List<Widget> _urgentAlerts() {
    final urgent = _announcements
        .where((a) => a.isUrgent && !a.isRead)
        .take(2)
        .toList();
    if (urgent.isEmpty) return [];
    return [
      ...urgent.map(
        (a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.urgentLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.urgent.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.urgent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.urgent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.body,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.urgent.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _statCards() => Row(
    children: [
      _statCard(
        _todaySchedule.length.toString(),
        AppStrings.classesToday,
        Icons.event_available,
        AppColors.primary,
      ),
      const SizedBox(width: 10),
      _statCard(
        _unreadCount.toString(),
        AppStrings.newAlerts,
        Icons.notifications_active,
        AppColors.urgent,
      ),
      const SizedBox(width: 10),
      _statCard(
        '5',
        AppStrings.daysToExam,
        Icons.school_outlined,
        AppColors.warning,
      ),
    ],
  );

  Widget _statCard(String num, String label, IconData icon, Color accent) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(height: 10),
              Text(
                num,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, VoidCallback onSeeAll) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const Spacer(),
      TextButton(
        onPressed: onSeeAll,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: const Text(AppStrings.seeAll),
      ),
    ],
  );

  Widget _scheduleList() {
    if (_todaySchedule.isEmpty) {
      return _emptyCard(Icons.event_available, 'No classes today');
    }
    final items = _todaySchedule.take(3).toList();
    return Column(
      children: List.generate(
        items.length,
        (i) => ClassCard(schedule: items[i]),
      ),
    );
  }

  Widget _announcementList() {
    if (_announcements.isEmpty) {
      return _emptyCard(Icons.notifications_none, AppStrings.noAnnouncements);
    }
    final items = _announcements.take(3).toList();
    return Column(
      children: List.generate(
        items.length,
        (i) => AnnouncementCard(announcement: items[i]),
      ),
    );
  }

  Widget _emptyCard(IconData icon, String label) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _user?.initials ?? '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.fullName ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_user?.department ?? ''} · ${_user?.yearOfStudy ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.urgent,
                size: 20,
              ),
              title: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.urgent, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

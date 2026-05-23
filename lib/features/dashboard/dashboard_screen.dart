import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/schedule_model.dart';
import '../../models/announcement_model.dart';
import '../../models/user_model.dart';
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
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }
      _todaySchedule = await _firestoreService.getTodaySchedule(_user!.id);
      _announcements = await _firestoreService.getAnnouncementsStream(department: _user!.department).first;
      await _cacheService.cacheSchedule(_todaySchedule);
      await _cacheService.cacheAnnouncements(_announcements);
    } catch (e) {
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
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  int get _unreadCount => _announcements.where((a) => !a.isRead).length;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    final screens = <Widget?>[null, const TimetableScreen(), const AnnouncementsScreen(), const MapScreen(), const DirectoryScreen()];
    setState(() => _currentNavIndex = index);
    if (screens[index] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screens[index]!))
          .then((_) => setState(() => _currentNavIndex = 0));
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (_isOffline) _offlineBanner(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topBar(),
                          const SizedBox(height: 16),
                          ..._urgentAlerts(),
                          _statCards(),
                          const SizedBox(height: 20),
                          _sectionHeader(AppStrings.todaySchedule, () => _onNavTap(1)),
                          const SizedBox(height: 8),
                          _scheduleList(),
                          const SizedBox(height: 20),
                          _sectionHeader(AppStrings.recentAnnouncements, () => _onNavTap(2)),
                          const SizedBox(height: 8),
                          _announcementList(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: _currentNavIndex, onTap: _onNavTap),
    );
  }

  Widget _offlineBanner() => Container(
    color: AppColors.primaryLight,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: const Row(children: [
      Icon(Icons.wifi_off, size: 14, color: AppColors.primaryDark),
      SizedBox(width: 6),
      Text(AppStrings.offlineBanner, style: TextStyle(fontSize: 11, color: AppColors.primaryDark)),
    ]),
  );

  Widget _topBar() => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_getGreeting()}, ${_user?.fullName.split(' ').first ?? 'Student'} 👋',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text('${_getDayLabel()} · ${_todaySchedule.length} classes today',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ])),
    Stack(children: [
      IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary), onPressed: () => _onNavTap(2)),
      if (_unreadCount > 0) Positioned(right: 8, top: 8, child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: AppColors.urgent, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 1.5)),
      )),
    ]),
    GestureDetector(
      onTap: _showProfileMenu,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        child: Center(child: Text(_user?.initials ?? '?',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryDark))),
      ),
    ),
  ]);

  List<Widget> _urgentAlerts() {
    final urgent = _announcements.where((a) => a.isUrgent && !a.isRead).take(2).toList();
    if (urgent.isEmpty) return [];
    return [
      ...urgent.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.urgentLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.urgent.withOpacity(0.3), width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.urgent),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.urgent)),
            const SizedBox(height: 2),
            Text(a.body, style: TextStyle(fontSize: 11, color: AppColors.urgent.withOpacity(0.8)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      )),
      const SizedBox(height: 8),
    ];
  }

  Widget _statCards() => Row(children: [
    _statCard(_todaySchedule.length.toString(), AppStrings.classesToday),
    const SizedBox(width: 8),
    _statCard(_unreadCount.toString(), AppStrings.newAlerts),
    const SizedBox(width: 8),
    _statCard('5', AppStrings.daysToExam),
  ]);

  Widget _statCard(String num, String label) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      Text(num, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  ));

  Widget _sectionHeader(String title, VoidCallback onSeeAll) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    const Spacer(),
    GestureDetector(onTap: onSeeAll, child: const Text(AppStrings.seeAll, style: TextStyle(fontSize: 12, color: AppColors.primary))),
  ]);

  Widget _scheduleList() {
    if (_todaySchedule.isEmpty) return _emptyCard(Icons.event_available, 'No classes today');
    return Column(children: _todaySchedule.take(3).map((s) => ClassCard(schedule: s)).toList());
  }

  Widget _announcementList() {
    if (_announcements.isEmpty) return _emptyCard(Icons.notifications_none, AppStrings.noAnnouncements);
    return Column(children: _announcements.take(3).map((a) => AnnouncementCard(announcement: a)).toList());
  }

  Widget _emptyCard(IconData icon, String label) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Center(child: Column(children: [
      Icon(icon, size: 32, color: AppColors.textSecondary),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ])),
  );

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Center(child: Text(_user?.initials ?? '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.primaryDark)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_user?.fullName ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Text('${_user?.department ?? ''} · ${_user?.yearOfStudy ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.urgent, size: 20),
            title: const Text('Sign out', style: TextStyle(color: AppColors.urgent, fontSize: 14)),
            onTap: () { Navigator.pop(context); _logout(); },
          ),
        ]),
      ),
    );
  }
}
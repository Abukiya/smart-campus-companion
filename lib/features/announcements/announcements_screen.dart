import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../Models/announcement_model.dart';
import '../../Models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/announcement_card.dart';
import '../dashboard/dashboard_screen.dart';
import '../timetable/timetable_screen.dart';
import '../map/map_screen.dart';
import '../directory/directory_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  static const _navTransitionDuration = Duration(milliseconds: 240);

  UserModel? _user;
  List<AnnouncementModel> _all = [];
  List<AnnouncementModel> _filtered = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  final _filters = ['all', 'urgent', 'academic', 'exam', 'general'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _user = await _authService.getCurrentUserModel();
      _all = await _firestoreService
          .getAnnouncementsStream(department: _user?.department)
          .first;
      _applyFilter();
    } catch (e) {
      _all = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all.where((a) {
        final matchesFilter =
            _selectedFilter == 'all' || a.category == _selectedFilter;
        final matchesSearch =
            query.isEmpty ||
            a.title.toLowerCase().contains(query) ||
            a.body.toLowerCase().contains(query) ||
            a.postedByName.toLowerCase().contains(query);
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilter();
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final a in _all) {
        a.isRead = true;
      }
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _all.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.announcements),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                AppStrings.markAllRead,
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: Column(
                children: [
                  // Search + filters
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search announcements...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilter();
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Filter chips
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _filters
                                .map((f) => _filterChip(f))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // List
                  Expanded(
                    child: _filtered.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final announcement = _filtered[i];
                              return AnnouncementCard(
                                announcement: announcement,
                                onTap: () => _openDetail(announcement),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNav(currentIndex: 2, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) {
    if (index == 2) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        _fadeRoute(const DashboardScreen()),
        (route) => false,
      );
      return;
    }

    final destinations = {
      1: () => const TimetableScreen(),
      3: () => const MapScreen(),
      4: () => const DirectoryScreen(),
    };

    final destination = destinations[index];
    if (destination == null) return;

    Navigator.pushReplacement(context, _fadeRoute(destination()));
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

  Widget _filterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final label = filter == 'all' ? 'All' : _capitalize(filter);

    Color bg = isSelected ? AppColors.primaryLight : AppColors.surface;
    Color text = isSelected ? AppColors.primaryDark : AppColors.textSecondary;
    Color border = isSelected ? AppColors.primaryBorder : AppColors.border;

    if (isSelected && filter == 'urgent') {
      bg = AppColors.urgentLight;
      text = AppColors.urgent;
      border = AppColors.urgent.withOpacity(0.4);
    }

    return GestureDetector(
      onTap: () => _setFilter(filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: text,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'all'
                ? AppStrings.noAnnouncements
                : 'No ${_capitalize(_selectedFilter)} announcements',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.noAnnouncementsSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _openDetail(AnnouncementModel announcement) {
    // Mark as read
    setState(() => announcement.isRead = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  // Category tag
                  _categoryTag(announcement),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Meta
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${announcement.postedByName} · ${announcement.timeAgo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Body
                  Text(
                    announcement.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Find location on map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryBorder),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share with classmates'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTag(AnnouncementModel a) {
    Color bg;
    Color text;
    switch (a.category) {
      case 'urgent':
        bg = AppColors.urgentLight;
        text = AppColors.urgent;
        break;
      case 'academic':
        bg = const Color(0xFFEEEDFE);
        text = const Color(0xFF3C3489);
        break;
      case 'exam':
        bg = AppColors.warningLight;
        text = AppColors.warning;
        break;
      default:
        bg = AppColors.infoLight;
        text = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        a.categoryLabel,
        style: TextStyle(
          fontSize: 11,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

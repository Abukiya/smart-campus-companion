import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../Models/announcement_model.dart';
import '../../Models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../../features/admin/post_announcement_screen .dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  UserModel? _user;
  List<AnnouncementModel> _myPosts = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;

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
      _myPosts = await _firestoreService.getMyAnnouncements(_user!.id);
    } catch (e) {
      _myPosts = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletePost(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete announcement'),
        content: const Text(
          'This will permanently delete this announcement. Are you sure?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.urgent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteAnnouncement(id);
      _loadData();
    }
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

  // Analytics computed from posts
  int get _totalPosts => _myPosts.length;
  int get _studentsReached => _totalPosts * 247; // approximate per post
  String get _avgReadRate => _totalPosts > 0 ? '91%' : '—';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.staffDashboard),
            if (_user != null)
              Text(
                '${_user!.fullName} · ${_user!.department}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.urgent),
            onPressed: _logout,
            tooltip: 'Sign out',
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
              child: _buildBody(),
            ),
      bottomNavigationBar: _buildAdminNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 1:
        return _buildPostView();
      case 2:
        return _buildAnalyticsView();
      default:
        return _buildDashboardView();
    }
  }

  // ─── DASHBOARD VIEW ───────────────────────────────────

  Widget _buildDashboardView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stat cards
        Row(
          children: [
            _statCard(
              _totalPosts.toString(),
              'Posts this week',
              AppColors.primary,
            ),
            const SizedBox(width: 8),
            _statCard(
              _studentsReached > 0
                  ? '${(_studentsReached / 1000).toStringAsFixed(1)}k'
                  : '0',
              'Students reached',
              AppColors.info,
            ),
            const SizedBox(width: 8),
            _statCard(_avgReadRate, 'Avg read rate', AppColors.primary),
          ],
        ),
        const SizedBox(height: 16),

        // Post buttons
        ElevatedButton.icon(
          onPressed: () => _goToPost(isUrgent: false),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(AppStrings.postAnnouncement),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _goToPost(isUrgent: true),
          icon: const Icon(Icons.warning_amber_rounded, size: 18),
          label: const Text(AppStrings.postUrgent),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.urgent,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Recent posts
        Row(
          children: [
            const Text(
              AppStrings.myRecentPosts,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _currentNavIndex = 2),
              child: const Text(
                'Analytics',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_myPosts.isEmpty)
          _emptyPosts()
        else
          ..._myPosts.take(5).map((post) => _postCard(post)),
      ],
    );
  }

  Widget _emptyPosts() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: const Center(
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the button above to post your first announcement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );

  Widget _postCard(AnnouncementModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _categoryChip(post.category),
              const Spacer(),
              Text(
                post.timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '247 students · 91% read',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToPost(isUrgent: false, editPost: post),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePost(post.id),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.urgent,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(color: AppColors.urgent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── POST VIEW ────────────────────────────────────────

Widget _buildPostView() {
  if (_user == null) {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }
  return PostAnnouncementScreen(
    user: _user,
    onPosted: () {
      setState(() => _currentNavIndex = 0);
      _loadData();
    },
  );
}

  // ─── ANALYTICS VIEW ───────────────────────────────────

  Widget _buildAnalyticsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stats
        Row(
          children: [
            _statCard(_totalPosts.toString(), 'Total posts', AppColors.primary),
            const SizedBox(width: 8),
            _statCard(_avgReadRate, 'Avg read rate', AppColors.info),
            const SizedBox(width: 8),
            _statCard(
              '${_studentsReached > 0 ? (_studentsReached / 1000).toStringAsFixed(1) : 0}k',
              'Total reached',
              AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Read rate by category
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Read rate by category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _rateBar('Urgent alerts', 0.94, AppColors.urgent),
              const SizedBox(height: 8),
              _rateBar('Academic', 0.88, const Color(0xFF534AB7)),
              const SizedBox(height: 8),
              _rateBar('General', 0.76, AppColors.info),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top posts
        const Text(
          'Recent posts performance',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_myPosts.isEmpty)
          _emptyPosts()
        else
          ..._myPosts.map((post) => _analyticsCard(post)),
      ],
    );
  }

  Widget _rateBar(String label, double rate, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: rate,
                  backgroundColor: AppColors.surface,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(rate * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _analyticsCard(AnnouncementModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _categoryChip(post.category),
              const Spacer(),
              Text(
                post.timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '247 reached · ',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '91% read',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' · within 8 min',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────

  Widget _statCard(String num, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            num,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _categoryChip(String category) {
    Color bg;
    Color text;
    switch (category) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _goToPost({required bool isUrgent, AnnouncementModel? editPost}) {
    setState(() => _currentNavIndex = 1);
  }

  Widget _buildAdminNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../Models/staff_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';
import '../map/map_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../timetable/timetable_screen.dart';
import '../announcements/announcements_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});
  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  static const _navTransitionDuration = Duration(milliseconds: 240);

  List<StaffModel> _all = [];
  List<StaffModel> _filtered = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  bool _showDeptView = false;

  final _filters = ['all', 'lecturer', 'admin'];

  // Department colors
  final _deptColors = {
    'CSE': AppColors.info,
    'CIVIL': AppColors.primary,
    'CHEM': AppColors.warning,
    'MECH': const Color(0xFF7F77DD),
    'EE': AppColors.urgent,
    'ADMIN': const Color(0xFF0F6E56),
  };

  final _schools = [
    _School('Engineering & IT', Icons.computer_outlined, AppColors.info, [
      'CSE',
      'EE',
      'MECH',
    ]),
    _School('Natural Sciences', Icons.science_outlined, AppColors.primary, [
      'CHEM',
      'PHYS',
      'MATH',
    ]),
    _School(
      'Civil & Env.',
      Icons.architecture_outlined,
      const Color(0xFF7F77DD),
      ['CIVIL', 'ENV'],
    ),
    _School('Administrative', Icons.business_outlined, AppColors.warning, [
      'ADMIN',
      'HR',
      'FINANCE',
    ]),
  ];

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
      _all = await _firestoreService.getStaff();
      if (_all.isEmpty) _all = _defaultStaff();
      _applyFilter();
    } catch (e) {
      _all = _defaultStaff();
      _applyFilter();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all.where((s) {
        final matchesFilter =
            _selectedFilter == 'all' ||
            (_selectedFilter == 'lecturer' &&
                s.role.toLowerCase().contains('lect')) ||
            (_selectedFilter == 'admin' &&
                !s.role.toLowerCase().contains('lect'));
        final matchesSearch =
            q.isEmpty ||
            s.fullName.toLowerCase().contains(q) ||
            s.role.toLowerCase().contains(q) ||
            s.department.toLowerCase().contains(q) ||
            (s.specialization?.toLowerCase().contains(q) ?? false);
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  // Group staff alphabetically
  Map<String, List<StaffModel>> get _grouped {
    final map = <String, List<StaffModel>>{};
    for (final s in _filtered) {
      final key = s.department.isNotEmpty ? s.department : 'Other';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  Color _avatarColor(String dept) => _deptColors[dept] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(AppStrings.staffDirectory),
        actions: [
          IconButton(
            icon: Icon(
              _showDeptView ? Icons.list : Icons.grid_view_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _showDeptView = !_showDeptView),
            tooltip: _showDeptView ? 'List view' : 'Department view',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Search + filters
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchDirectory,
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
                      Row(
                        children: _filters.map((f) {
                          final isSelected = _selectedFilter == f;
                          final label = f == 'all'
                              ? 'All'
                              : f == 'lecturer'
                              ? 'Lecturers'
                              : 'Admin';
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedFilter = f);
                              _applyFilter();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBorder
                                      : AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: _showDeptView ? _buildDeptView() : _buildListView(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNav(currentIndex: 4, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) {
    if (index == 4) return;

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
      2: () => const AnnouncementsScreen(),
      3: () => const MapScreen(),
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

  // ─── LIST VIEW ────────────────────────────────────────

  Widget _buildListView() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No staff found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name or department',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _grouped;
    final depts = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: depts.fold<int>(
        0,
        (sum, d) => sum + 1 + (grouped[d]?.length ?? 0),
      ),
      itemBuilder: (_, i) {
        int counter = 0;
        for (final dept in depts) {
          if (i == counter) {
            return _deptHeader(dept);
          }
          counter++;
          final staff = grouped[dept]!;
          if (i < counter + staff.length) {
            return _staffTile(staff[i - counter]);
          }
          counter += staff.length;
        }
        return const SizedBox();
      },
    );
  }

  Widget _deptHeader(String dept) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        dept,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _avatarColor(dept),
          letterSpacing: .05,
        ),
      ),
    );
  }

  Widget _staffTile(StaffModel staff) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _avatarColor(staff.department).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            staff.initials,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _avatarColor(staff.department),
            ),
          ),
        ),
      ),
      title: Text(
        staff.fullName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            staff.role,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (staff.department.isNotEmpty)
            Text(
              staff.department,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textSecondary,
      ),
      onTap: () => _openProfile(staff),
    );
  }

  // ─── DEPARTMENT VIEW ──────────────────────────────────

  Widget _buildDeptView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _schools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final school = _schools[i];
        final count = _all
            .where((s) => school.departments.contains(s.department))
            .length;
        return GestureDetector(
          onTap: () {
            setState(() {
              _showDeptView = false;
              _searchController.text = school.departments.first;
              _applyFilter();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: school.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(school.icon, color: school.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count > 0 ? '$count staff members' : 'Tap to browse',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── STAFF PROFILE BOTTOM SHEET ───────────────────────

  void _openProfile(StaffModel staff) {
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
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Profile header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _avatarColor(staff.department).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _avatarColor(staff.department).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _avatarColor(staff.department).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        staff.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _avatarColor(staff.department),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          staff.role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          staff.school.isNotEmpty
                              ? staff.school
                              : staff.department,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & office info
            _infoCard([
              if (staff.email.isNotEmpty)
                _infoRow(
                  Icons.email_outlined,
                  'Email',
                  staff.email,
                  isLink: true,
                ),
              if (staff.phoneExtension != null)
                _infoRow(
                  Icons.phone_outlined,
                  'Extension',
                  'Ext. ${staff.phoneExtension}',
                  isLink: true,
                ),
              if (staff.officeLocation != null)
                _infoRow(
                  Icons.door_back_door_outlined,
                  'Office',
                  staff.officeLocation!,
                ),
              if (staff.officeHours != null)
                _infoRow(
                  Icons.access_time_outlined,
                  'Office hours',
                  staff.officeHours!,
                ),
              if (staff.specialization != null)
                _infoRow(
                  Icons.school_outlined,
                  'Specialization',
                  staff.specialization!,
                ),
              if (staff.courses.isNotEmpty)
                _infoRow(
                  Icons.book_outlined,
                  'Courses',
                  staff.courses.join(', '),
                ),
            ]),
            const SizedBox(height: 12),

            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      highlightLocationId: staff.locationId,
                      highlightLocationName: staff.officeLocation,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text(AppStrings.findOfficeOnMap),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text('View this lecturer\'s classes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLink ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            const Icon(
              Icons.open_in_new,
              size: 12,
              color: AppColors.textSecondary,
            ),
          const Divider(),
        ],
      ),
    );
  }

  // ─── DEFAULT DATA ─────────────────────────────────────

  List<StaffModel> _defaultStaff() => [
    StaffModel(
      id: 's1',
      fullName: 'Dr. Haile Tadesse',
      role: 'Lecturer',
      department: 'CSE',
      school: 'Engineering & IT',
      email: 'haile.tadesse@astu.edu.et',
      phoneExtension: '2045',
      officeLocation: 'Block B · Room 312 · 3rd floor',
      officeHours: 'Mon & Wed 2:00–4:00 PM',
      specialization: 'Algorithms, Data Structures',
      courses: ['Data Structures (CSE-302)', 'Algorithms (CSE-401)'],
      locationId: 'block_b',
    ),
    StaffModel(
      id: 's2',
      fullName: 'Dr. Meron Alemu',
      role: 'Lecturer',
      department: 'CSE',
      school: 'Engineering & IT',
      email: 'meron.alemu@astu.edu.et',
      phoneExtension: '2046',
      officeLocation: 'Block B · Room 310 · 3rd floor',
      officeHours: 'Tue & Thu 1:00–3:00 PM',
      specialization: 'Software Engineering, UML',
      courses: ['Software Engineering (CSE-401)', 'System Design (CSE-450)'],
      locationId: 'block_b',
    ),
    StaffModel(
      id: 's3',
      fullName: 'Mr. Yonas Bekele',
      role: 'Lecturer',
      department: 'CSE',
      school: 'Engineering & IT',
      email: 'yonas.bekele@astu.edu.et',
      phoneExtension: '2047',
      officeLocation: 'Block A · Room 205',
      officeHours: 'Mon, Wed & Fri 9:00–11:00 AM',
      specialization: 'Computer Networks, Security',
      courses: ['Computer Networks (CSE-310)'],
      locationId: 'block_a',
    ),
    StaffModel(
      id: 's4',
      fullName: 'Dr. Tigist Worku',
      role: 'Lecturer',
      department: 'CHEM',
      school: 'Natural Sciences',
      email: 'tigist.worku@astu.edu.et',
      officeLocation: 'Block C · Room 102',
      officeHours: 'Tue & Thu 2:00–4:00 PM',
      courses: ['General Chemistry', 'Organic Chemistry'],
      locationId: 'block_c',
    ),
    StaffModel(
      id: 's5',
      fullName: 'Ato Biruk Tadesse',
      role: 'Registrar',
      department: 'ADMIN',
      school: 'Administrative',
      email: 'registrar@astu.edu.et',
      phoneExtension: '1001',
      officeLocation: 'Admin Block · Room 001 · Ground floor',
      officeHours: 'Mon–Fri 8:00 AM–5:00 PM',
      locationId: 'registrar',
    ),
    StaffModel(
      id: 's6',
      fullName: 'W/ro Selam Girma',
      role: 'Department Secretary',
      department: 'CSE',
      school: 'Engineering & IT',
      email: 'cse.secretary@astu.edu.et',
      phoneExtension: '2040',
      officeLocation: 'Block B · Room 301',
      officeHours: 'Mon–Fri 8:30 AM–4:30 PM',
      locationId: 'block_b',
    ),
  ];
}

class _School {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> departments;
  const _School(this.name, this.icon, this.color, this.departments);
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/schedule_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/class_card.dart';
import '../auth/login_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  late TabController _tabController;
  List<ScheduleModel> _allSchedule = [];
  bool _isLoading = true;
  int _selectedDayIndex = DateTime.now().weekday - 1;
  String? _userId;
  String? _department;

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _daysFull = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }
      _userId = user.id;
      _department = user.department;
      _allSchedule = await _firestoreService.getWeekSchedule(user.id);
    } catch (e) {
      _allSchedule = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<ScheduleModel> _getScheduleForDay(int dayIndex) {
    final day = _daysFull[dayIndex];
    final list = _allSchedule.where((s) => s.dayOfWeek.toLowerCase() == day).toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  List<ScheduleModel> _getExams() {
    // For demo — in production this would come from an exams collection
    return [];
  }

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
        title: const Text(AppStrings.timetable),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Week'),
            Tab(text: 'Calendar'),
            Tab(text: 'Exams'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeekView(),
                _buildCalendarView(),
                _buildExamView(),
              ],
            ),
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) Navigator.pop(context);
        },
      ),
    );
  }

  // ─── WEEK VIEW ────────────────────────────────────────

  Widget _buildWeekView() {
    final schedule = _getScheduleForDay(_selectedDayIndex);
    return Column(
      children: [
        // Week nav
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Week label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    _getWeekLabel(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Day strip
              Row(
                children: List.generate(7, (i) {
                  final isToday = i == DateTime.now().weekday - 1;
                  final isSelected = i == _selectedDayIndex;
                  final daySchedule = _getScheduleForDay(i);
                  final hasClasses = daySchedule.isNotEmpty;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = i),
                      child: Column(
                        children: [
                          Text(
                            _days[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday && !isSelected
                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${_getDayNumber(i)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: hasClasses ? AppColors.warning : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Schedule list
        Expanded(
          child: schedule.isEmpty
              ? _emptyState(Icons.event_available_outlined, 'No classes on ${_days[_selectedDayIndex]}')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedule.length,
                  itemBuilder: (_, i) => ClassCard(schedule: schedule[i]),
                ),
        ),
      ],
    );
  }

  // ─── CALENDAR VIEW ────────────────────────────────────

  Widget _buildCalendarView() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final startWeekday = firstDay.weekday - 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  Text(
                    _getMonthLabel(now),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              // Day headers
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => Expanded(
                          child: Text(d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: startWeekday + lastDay.day,
                itemBuilder: (_, index) {
                  if (index < startWeekday) return const SizedBox();
                  final day = index - startWeekday + 1;
                  final date = DateTime(now.year, now.month, day);
                  final isToday = day == now.day;
                  final dayOfWeek = _daysFull[date.weekday - 1];
                  final hasClass = _allSchedule.any((s) => s.dayOfWeek.toLowerCase() == dayOfWeek);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                              color: isToday ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: hasClass ? (isToday ? AppColors.white : AppColors.primary) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          children: [
            _legendItem(AppColors.primary, 'Classes'),
            const SizedBox(width: 16),
            _legendItem(AppColors.urgent, 'Exams'),
            const SizedBox(width: 16),
            _legendItem(AppColors.primary, 'Today', isCircle: true),
          ],
        ),
        const SizedBox(height: 16),
        // Today's classes
        const Text("Today's classes",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        ..._getScheduleForDay(DateTime.now().weekday - 1)
            .map((s) => ClassCard(schedule: s))
            .toList(),
        if (_getScheduleForDay(DateTime.now().weekday - 1).isEmpty)
          _emptyState(Icons.event_available_outlined, 'No classes today'),
      ],
    );
  }

  // ─── EXAM VIEW ────────────────────────────────────────

  Widget _buildExamView() {
    // Sample exam data — in production load from Firestore exams collection
    final exams = [
      _ExamItem('Data Structures', 'CSE-302', 'Mon, May 27', '08:00 – 10:00', 'Hall 1 · Main Block', 5),
      _ExamItem('Software Engineering', 'CSE-401', 'Thu, May 29', '10:30 – 12:30', 'Hall 2 · Main Block', 7),
      _ExamItem('Computer Networks', 'CSE-310', 'Fri, May 30', '2:00 – 4:00', 'Room 301 · Block C', 8),
      _ExamItem('Database Systems', 'CSE-305', 'Mon, Jun 2', '08:00 – 10:00', 'Hall 1 · Main Block', 11),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: exams.map((e) => _examCard(e)).toList(),
    );
  }

  Widget _examCard(_ExamItem exam) {
    final isClose = exam.daysUntil <= 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isClose ? AppColors.urgentLight : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.urgent, width: 3),
          top: BorderSide(color: AppColors.border, width: 0.5),
          right: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Text(exam.time.split('–')[0].trim(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.courseName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(exam.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.door_back_door_outlined, size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(exam.venue, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.urgentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'In ${exam.daysUntil} days',
                      style: const TextStyle(fontSize: 10, color: AppColors.urgent, fontWeight: FontWeight.w500),
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

  // ─── HELPERS ──────────────────────────────────────────

  Widget _emptyState(IconData icon, String label) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 60),
      Icon(icon, size: 48, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    ]),
  );

  Widget _legendItem(Color color, String label, {bool isCircle = false}) => Row(
    children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: isCircle ? BoxShape.circle : BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );

  String _getWeekLabel() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return 'May ${monday.day} – ${sunday.day}, ${now.year}';
  }

  String _getMonthLabel(DateTime date) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _getDayNumber(int dayIndex) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: dayIndex)).day;
  }
}

class _ExamItem {
  final String courseName;
  final String courseCode;
  final String date;
  final String time;
  final String venue;
  final int daysUntil;
  const _ExamItem(this.courseName, this.courseCode, this.date, this.time, this.venue, this.daysUntil);
}
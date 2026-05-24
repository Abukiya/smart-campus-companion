import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../Models/schedule_model.dart';

class ClassCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback? onTap;

  const ClassCard({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNow = schedule.isNow();
    final isNext = schedule.isUpNext();
    final isCancelled = schedule.isCancelled;
    final isRoomChanged = schedule.isRoomChanged;

    Color accent = AppColors.border;
    if (isNow) accent = AppColors.primary;
    if (isNext) accent = AppColors.warning;
    if (isCancelled) accent = AppColors.urgent;
    if (isRoomChanged) accent = AppColors.urgent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            schedule.courseName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isCancelled
                                  ? AppColors.urgent
                                  : AppColors.textPrimary,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_back_door_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isRoomChanged
                                ? '${schedule.newRoom} • room changed'
                                : '${schedule.room} • ${schedule.building}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isRoomChanged
                                  ? AppColors.urgent
                                  : AppColors.textSecondary,
                              fontWeight: isRoomChanged
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.lecturerName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isNow)
                          _badge(
                            'Now',
                            AppColors.primaryLight,
                            AppColors.primaryDark,
                          ),
                        if (isNext && !isNow)
                          _badge(
                            'Up next',
                            AppColors.warningLight,
                            AppColors.warning,
                          ),
                        if (isCancelled)
                          _badge(
                            'Cancelled',
                            AppColors.urgentLight,
                            AppColors.urgent,
                          ),
                        if (isRoomChanged && !isCancelled)
                          _badge(
                            'Room changed',
                            AppColors.urgentLight,
                            AppColors.urgent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

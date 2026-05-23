import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_model.dart';

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

    Color borderColor = AppColors.border;
    if (isNow) borderColor = AppColors.primary;
    if (isNext) borderColor = AppColors.warning;
    if (isCancelled) borderColor = AppColors.urgent;
    if (isRoomChanged) borderColor = AppColors.urgent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCancelled
              ? AppColors.urgentLight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
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
              // Time column
              SizedBox(
                width: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.startTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      schedule.endTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.courseName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isCancelled
                            ? AppColors.urgent
                            : AppColors.textPrimary,
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Room info
                    Row(
                      children: [
                        const Icon(Icons.door_back_door_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          isRoomChanged
                              ? '${schedule.newRoom} ← changed'
                              : '${schedule.room} · ${schedule.building}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRoomChanged
                                ? AppColors.urgent
                                : AppColors.textSecondary,
                            fontWeight: isRoomChanged
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Lecturer
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          schedule.lecturerName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    if (isNow) _badge('Now', AppColors.primaryLight, AppColors.primaryDark),
                    if (isNext && !isNow) _badge('Up next', AppColors.warningLight, AppColors.warning),
                    if (isCancelled) _badge('Cancelled', AppColors.urgentLight, AppColors.urgent),
                    if (isRoomChanged && !isCancelled)
                      _badge('Room changed', AppColors.urgentLight, AppColors.urgent),
                  ],
                ),
              ),
            ],
          ),
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
        style: TextStyle(fontSize: 10, color: text, fontWeight: FontWeight.w500),
      ),
    );
  }
}

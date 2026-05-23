import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/announcement_model.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = announcement.isUrgent;
    final isUnread = !announcement.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isUrgent ? AppColors.urgent : AppColors.border,
              width: isUrgent ? 3 : 0.5,
            ),
            top: const BorderSide(color: AppColors.border, width: 0.5),
            right: const BorderSide(color: AppColors.border, width: 0.5),
            bottom: const BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: tag + time + unread dot
              Row(
                children: [
                  _categoryTag(),
                  const Spacer(),
                  if (isUnread)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    announcement.timeAgo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Title
              Text(
                announcement.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isUnread ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Preview
              Text(
                announcement.body,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              // Posted by
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    announcement.postedByName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
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

  Widget _categoryTag() {
    Color bg;
    Color text;
    switch (announcement.category) {
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
        announcement.categoryLabel,
        style: TextStyle(fontSize: 10, color: text, fontWeight: FontWeight.w500),
      ),
    );
  }
}

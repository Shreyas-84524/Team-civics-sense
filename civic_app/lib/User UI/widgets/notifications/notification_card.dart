import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/repositories/complaint_repository.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Card widget representing a single citizen notification.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onReadChanged;
  final NotificationRepository? notificationRepository;
  final ComplaintRepository? complaintRepository;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onReadChanged,
    this.notificationRepository,
    this.complaintRepository,
  });

  Future<void> _handleTap(BuildContext context) async {
    final notifRepo = notificationRepository ?? MockNotificationRepository();
    final compRepo = complaintRepository ?? MockComplaintRepository();

    if (!notification.isRead) {
      await notifRepo.markAsRead(notification.id);
      onReadChanged?.call();
    }

    if (!context.mounted) return;

    if (notification.complaintId != null) {
      final complaint = await compRepo.getComplaintById(notification.complaintId!);
      if (context.mounted) {
        if (complaint != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.complaintDetails,
            arguments: complaint,
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.complaintDetails,
            arguments: notification.complaintId,
          );
        }
      }
    } else {
      // General notification info dialog
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
          title: Row(
            children: [
              Icon(notification.type.icon, color: notification.type.color),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  notification.title,
                  style: CivicFixTypography.h3,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: CivicFixTypography.body,
              ),
              CivicFixSpacing.vSpaceMd,
              Text(
                DateFormatter.formatRelativeTime(notification.createdAt),
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Semantics(
      label: '${isUnread ? "Unread notification: " : "Notification: "}${notification.title}. ${notification.message}. ${DateFormatter.formatRelativeTime(notification.createdAt)}',
      button: true,
      child: CivicFixCard(
        onTap: () => _handleTap(context),
        backgroundColor: isUnread ? const Color(0xFFF2F7F4) : CivicFixColors.surface,
        borderColor: isUnread ? CivicFixColors.secondary.withValues(alpha: 0.3) : CivicFixColors.border,
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Type Icon
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.sm),
              decoration: BoxDecoration(
                color: notification.type.color.withValues(alpha: 0.12),
                borderRadius: CivicFixRadius.chipRadius,
              ),
              child: Icon(
                notification.type.icon,
                color: notification.type.color,
                size: 22,
              ),
            ),
            CivicFixSpacing.hSpaceMd,

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        CivicFixSpacing.hSpaceSm,
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: CivicFixColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    notification.message,
                    style: CivicFixTypography.bodySmall.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatRelativeTime(notification.createdAt),
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.disabledText,
                        ),
                      ),
                      if (notification.complaintId != null)
                        Row(
                          children: [
                            Text(
                              'View Details',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: CivicFixColors.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

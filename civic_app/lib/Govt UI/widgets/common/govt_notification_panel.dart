import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_empty_state.dart';

/// Notification event categories for future government real-time alerts.
enum GovtNotificationCategory {
  assignment,
  slaWarning,
  routingTicket,
  escalation,
  crewCompletion,
  criticalIncident;

  IconData get icon {
    switch (this) {
      case GovtNotificationCategory.assignment:
        return Icons.assignment_ind_outlined;
      case GovtNotificationCategory.slaWarning:
        return Icons.timer_outlined;
      case GovtNotificationCategory.routingTicket:
        return Icons.swap_horiz_rounded;
      case GovtNotificationCategory.escalation:
        return Icons.priority_high_rounded;
      case GovtNotificationCategory.crewCompletion:
        return Icons.task_alt_rounded;
      case GovtNotificationCategory.criticalIncident:
        return Icons.warning_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GovtNotificationCategory.assignment:
        return GovtThemeTokens.info;
      case GovtNotificationCategory.slaWarning:
        return const Color(0xFFD97706);
      case GovtNotificationCategory.routingTicket:
        return const Color(0xFF4F46E5);
      case GovtNotificationCategory.escalation:
        return GovtThemeTokens.critical;
      case GovtNotificationCategory.crewCompletion:
        return GovtThemeTokens.success;
      case GovtNotificationCategory.criticalIncident:
        return GovtThemeTokens.critical;
    }
  }
}

/// Notification item shell model for UI development.
class GovtNotificationItem {
  final String id;
  final String title;
  final String description;
  final GovtNotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? targetId;

  const GovtNotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.targetId,
  });
}

/// Frontend shell for government notification popover/panel.
class GovtNotificationPanel extends StatelessWidget {
  final List<GovtNotificationItem> notifications;
  final VoidCallback? onMarkAllRead;
  final ValueChanged<GovtNotificationItem>? onNotificationTap;
  final VoidCallback? onClose;

  const GovtNotificationPanel({
    super.key,
    this.notifications = const [],
    this.onMarkAllRead,
    this.onNotificationTap,
    this.onClose,
  });

  /// Displays the notification panel as an end drawer or modal sheet.
  static void show(
    BuildContext context, {
    List<GovtNotificationItem> notifications = const [],
    VoidCallback? onMarkAllRead,
    ValueChanged<GovtNotificationItem>? onNotificationTap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: GovtNotificationPanel(
            notifications: notifications,
            onMarkAllRead: onMarkAllRead,
            onNotificationTap: onNotificationTap,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
              vertical: CivicFixSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: GovtTypography.cardTitle.copyWith(fontSize: 16),
                      ),
                      if (unreadCount > 0) ...[
                        CivicFixSpacing.hSpaceSm,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (notifications.isNotEmpty && onMarkAllRead != null) ...[
                  TextButton(
                    onPressed: onMarkAllRead,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(
                      'Mark all read',
                      style: GovtTypography.caption.copyWith(
                        color: GovtThemeTokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (onClose != null) ...[
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClose,
                    tooltip: 'Close notifications',
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: GovtThemeTokens.border, height: 1),

          // Content
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: GovtEmptyState(
                      title: 'No operational alerts',
                      message: 'You are all caught up with municipal assignments and SLA notices.',
                      icon: Icons.notifications_none_rounded,
                      isCompact: true,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: GovtThemeTokens.borderLight, height: 1),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationTile(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(GovtNotificationItem item) {
    return InkWell(
      onTap: onNotificationTap != null ? () => onNotificationTap!(item) : null,
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        color: item.isRead ? Colors.transparent : const Color(0xFFF7FBF8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.category.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.category.icon,
                color: item.category.color,
                size: 16,
              ),
            ),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GovtTypography.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: GovtTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.timestamp),
                    style: GovtTypography.caption.copyWith(
                      fontSize: 10,
                      color: GovtThemeTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              CivicFixSpacing.hSpaceXs,
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: GovtThemeTokens.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

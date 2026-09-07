import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';

/// Top header section of the Home screen showing personalized greeting and notification indicator.
class HomeHeader extends StatelessWidget {
  final String greeting;
  final String welcomeMessage;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.welcomeMessage,
    this.unreadNotificationsCount = 0,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticNotificationLabel = unreadNotificationsCount > 0
        ? 'Notifications, $unreadNotificationsCount unread'
        : 'Notifications';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting & Supporting Welcome Message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: CivicFixTypography.h1.copyWith(
                  color: CivicFixColors.primaryText,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                welcomeMessage,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        CivicFixSpacing.hSpaceMd,

        // Notification Indicator Button
        Semantics(
          label: semanticNotificationLabel,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationTap ??
                  () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
              borderRadius: CivicFixRadius.buttonRadius,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CivicFixColors.surface,
                  borderRadius: CivicFixRadius.buttonRadius,
                  border: Border.all(color: CivicFixColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Badge(
                    isLabelVisible: unreadNotificationsCount > 0,
                    label: Text(
                      unreadNotificationsCount > 9 ? '9+' : '$unreadNotificationsCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: CivicFixColors.alertDark,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: CivicFixColors.primaryText,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../models/govt_user_model.dart';
import '../../theme/govt_theme_tokens.dart';

/// Top Application Bar for Government Web and Tablet Views.
class GovtAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final GovtUserModel? user;
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  const GovtAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.user,
    this.onMenuPressed,
    this.showMenuButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(GovtThemeTokens.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GovtThemeTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg),
      decoration: const BoxDecoration(
        color: GovtThemeTokens.surface,
        border: GovtThemeTokens.bottomBorder,
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: GovtThemeTokens.textPrimary),
              onPressed: onMenuPressed,
              tooltip: 'Toggle Menu',
            ),
            CivicFixSpacing.hSpaceSm,
          ],

          // Title & Breadcrumb
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PORTAL',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: GovtThemeTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Department & Ward Badges (Desktop/Tablet)
          if (user != null) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.sm + 2,
                  vertical: CivicFixSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2F8),
                  borderRadius: GovtThemeTokens.chipRadius,
                  border: Border.all(color: const Color(0xFFB8D8EA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: GovtThemeTokens.info,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        user!.departmentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.sm + 2,
                  vertical: CivicFixSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F0),
                  borderRadius: GovtThemeTokens.chipRadius,
                  border: Border.all(color: GovtThemeTokens.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: GovtThemeTokens.secondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user!.assignedWard,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (actions != null) ...[
            CivicFixSpacing.hSpaceMd,
            ...actions!,
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../../widgets/common/govt_card.dart';

/// Clean, structured placeholder destination screen for Phase 1 routing navigation.
class GovtPlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String moduleName;
  final int navIndex;

  const GovtPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.moduleName,
    this.navIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GovernmentAppShell(
      title: title,
      subtitle: subtitle,
      selectedIndex: navIndex,
      breadcrumbs: [
        const GovtBreadcrumbItem(label: 'Government Portal'),
        GovtBreadcrumbItem(label: moduleName),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CivicFixSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GovernmentPageHeader(
              title: title,
              subtitle: subtitle,
              primaryAction: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Module'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: GovtThemeTokens.buttonRadius,
                  ),
                ),
              ),
            ),
            CivicFixSpacing.vSpaceXl,
            GovtCard.info(
              title: '$moduleName Module Prepared',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.infoLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: GovtThemeTokens.info, size: 24),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: Text(
                          'The frontend design system and routing foundation for "$title" is fully established in Phase 1.',
                          style: GovtTypography.body,
                        ),
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceMd,
                  Text(
                    'Role-specific workflows, live operational queues, and municipal data binding will be introduced in subsequent phases in strict alignment with BMC governance specifications.',
                    style: GovtTypography.bodySmall,
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

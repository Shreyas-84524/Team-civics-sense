import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/govt_settings_model.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Notification Preferences Card for Government Portal.
class GovtNotificationSettingsWidget extends StatefulWidget {
  final GovernmentUserRepository? userRepository;

  const GovtNotificationSettingsWidget({
    super.key,
    this.userRepository,
  });

  @override
  State<GovtNotificationSettingsWidget> createState() => _GovtNotificationSettingsWidgetState();
}

class _GovtNotificationSettingsWidgetState extends State<GovtNotificationSettingsWidget> {
  late final GovernmentUserRepository _userRepo;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? MockGovernmentUserRepository();
  }

  void _updateSettings(GovtNotificationSettings newSettings) {
    _userRepo.updateNotificationSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtSettingsModel>(
      valueListenable: _userRepo.settingsListenable,
      builder: (context, settings, _) {
        final notifs = settings.notifications;

        return DashboardCard(
          title: 'Notification Preferences',
          subtitle: 'Configure real-time alerts for municipal grievance workflows',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSwitchTile(
                icon: Icons.assignment_add,
                title: 'New Complaint Alerts',
                subtitle: 'Notify immediately when a citizen files a grievance in your jurisdiction',
                value: notifs.newComplaintAlerts,
                onChanged: (val) => _updateSettings(notifs.copyWith(newComplaintAlerts: val)),
              ),
              const Divider(color: GovtThemeTokens.border, height: 1),
              _buildSwitchTile(
                icon: Icons.person_pin_circle_outlined,
                title: 'Assignment Alerts',
                subtitle: 'Notify when a complaint is dispatched or reassigned to your team',
                value: notifs.assignmentAlerts,
                onChanged: (val) => _updateSettings(notifs.copyWith(assignmentAlerts: val)),
              ),
              const Divider(color: GovtThemeTokens.border, height: 1),
              _buildSwitchTile(
                icon: Icons.sync_alt_rounded,
                title: 'Status Update Alerts',
                subtitle: 'Notify on verification, progress stage shifts, and resolution events',
                value: notifs.statusUpdateAlerts,
                onChanged: (val) => _updateSettings(notifs.copyWith(statusUpdateAlerts: val)),
              ),
              const Divider(color: GovtThemeTokens.border, height: 1),
              _buildSwitchTile(
                icon: Icons.warning_amber_rounded,
                title: 'High-Priority & Emergency Alerts',
                subtitle: 'Urgent notices for severe hazards, open manholes, and flood risks',
                value: notifs.highPriorityAlerts,
                activeColor: GovtThemeTokens.error,
                onChanged: (val) => _updateSettings(notifs.copyWith(highPriorityAlerts: val)),
              ),
              const Divider(color: GovtThemeTokens.border, height: 1),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'System & Maintenance Notifications',
                subtitle: 'Platform updates, scheduled maintenance windows, and compliance advisories',
                value: notifs.systemNotifications,
                onChanged: (val) => _updateSettings(notifs.copyWith(systemNotifications: val)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.sm),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (activeColor ?? GovtThemeTokens.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
          ),
          child: Icon(icon, color: activeColor ?? GovtThemeTokens.primary, size: 20),
        ),
        title: Text(title, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
        ),
        value: value,
        // ignore: deprecated_member_use
        activeColor: activeColor ?? GovtThemeTokens.primary,
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';

/// Screen for managing local citizen notification preferences and alerts.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _complaintUpdates = true;
  bool _hazardAlerts = true;
  bool _generalAnnouncements = false;
  bool _soundHaptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Notification Settings',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: CivicFixSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Complaint Alerts',
                  subtitle: 'Stay informed about progress on your reported issues',
                ),
                CivicFixSpacing.vSpaceSm,
                CivicFixCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Complaint Status Updates',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Receive instant updates when your grievance is verified, assigned, or resolved.',
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        value: _complaintUpdates,
                        activeThumbColor: CivicFixColors.secondary,
                        onChanged: (val) {
                          setState(() => _complaintUpdates = val);
                          _showFeedback('Complaint status alerts ${val ? "enabled" : "disabled"}');
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          'Community Hazard Warnings',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Get alerted about high-severity road hazards and flooding near your location.',
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        value: _hazardAlerts,
                        activeThumbColor: CivicFixColors.secondary,
                        onChanged: (val) {
                          setState(() => _hazardAlerts = val);
                          _showFeedback('Hazard warnings ${val ? "enabled" : "disabled"}');
                        },
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXl,

                const SectionHeader(
                  title: 'General & Sound',
                  subtitle: 'App announcements and feedback sounds',
                ),
                CivicFixSpacing.vSpaceSm,
                CivicFixCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Civic Announcements',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Updates on municipal ward drives, tree planting, and civic perk programs.',
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        value: _generalAnnouncements,
                        activeThumbColor: CivicFixColors.secondary,
                        onChanged: (val) {
                          setState(() => _generalAnnouncements = val);
                          _showFeedback('Announcements ${val ? "enabled" : "disabled"}');
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          'Sound & Haptic Feedback',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Play soft tone and vibration on successful issue submission.',
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        value: _soundHaptics,
                        activeThumbColor: CivicFixColors.secondary,
                        onChanged: (val) {
                          setState(() => _soundHaptics = val);
                          _showFeedback('Sound & haptics ${val ? "enabled" : "disabled"}');
                        },
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

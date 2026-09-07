import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/dashboard/dashboard_card.dart';

/// Government Detailed View Screen for a single Civic Grievance.
class GovtComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;

  const GovtComplaintDetailsScreen({
    super.key,
    this.complaint,
    this.complaintId,
  });

  @override
  State<GovtComplaintDetailsScreen> createState() => _GovtComplaintDetailsScreenState();
}

class _GovtComplaintDetailsScreenState extends State<GovtComplaintDetailsScreen> {
  final GovtComplaintRepository _repository = MockGovtComplaintRepository();
  ComplaintModel? _complaint;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _complaint = widget.complaint;
    } else if (widget.complaintId != null) {
      _loadComplaint(widget.complaintId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null && widget.complaint == null && widget.complaintId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ComplaintModel) {
        setState(() => _complaint = args);
      } else if (args is String) {
        _loadComplaint(args);
      }
    }
  }

  Future<void> _loadComplaint(String id) async {
    setState(() => _isLoading = true);
    final c = await _repository.getComplaintById(id);
    if (mounted) {
      setState(() {
        _complaint = c;
        _isLoading = false;
      });
    }
  }

  void _showVerifyDialog(ComplaintModel c) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verify Grievance ${c.ticketNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that this complaint is verified for departmental triage and action.',
              style: TextStyle(fontSize: 13),
            ),
            CivicFixSpacing.vSpaceMd,
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Verification Notes (Optional)',
                hintText: 'e.g. Field inspection confirmed issue validity.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _repository.verifyComplaint(
                complaintId: c.id,
                notes: notesController.text.trim(),
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grievance ${c.ticketNumber} marked as Verified.')),
                  );
                  _loadComplaint(c.id);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Confirm Verification'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(ComplaintModel c) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Flag Grievance ${c.ticketNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flag this complaint for administrative review or moderation.',
              style: TextStyle(fontSize: 13),
            ),
            CivicFixSpacing.vSpaceMd,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Review',
                hintText: 'e.g. Duplicate report, insufficient photo clarity, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _repository.flagComplaint(
                complaintId: c.id,
                reason: reasonController.text.trim().isEmpty
                    ? 'Flagged for moderation review'
                    : reasonController.text.trim(),
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grievance ${c.ticketNumber} flagged for review.')),
                  );
                  _loadComplaint(c.id);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.alert,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Confirm Flag'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: GovtThemeTokens.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
          ),
        ),
      );
    }

    final c = _complaint;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grievance Details')),
        body: const Center(child: Text('Complaint not found.')),
      );
    }

    return Scaffold(
      backgroundColor: GovtThemeTokens.background,
      appBar: AppBar(
        title: Text('Grievance ${c.ticketNumber}'),
        backgroundColor: GovtThemeTokens.surface,
        foregroundColor: GovtThemeTokens.textPrimary,
        elevation: 0,
        actions: [
          if (c.status == ComplaintStatus.reported) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Flag / Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.alert,
                side: const BorderSide(color: GovtThemeTokens.alert),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => _showFlagDialog(c),
            ),
            CivicFixSpacing.hSpaceSm,
            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: const Text('Verify'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.primary,
                side: const BorderSide(color: GovtThemeTokens.primary),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => _showVerifyDialog(c),
            ),
            CivicFixSpacing.hSpaceSm,
          ],
          TextButton.icon(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text('Assign Crew'),
            style: TextButton.styleFrom(
              foregroundColor: GovtThemeTokens.primary,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.govtComplaintAssignment,
                arguments: c,
              ).then((_) {
                _loadComplaint(c.id);
              });
            },
          ),
          CivicFixSpacing.hSpaceSm,
          Padding(
            padding: const EdgeInsets.only(right: CivicFixSpacing.lg),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.govtStatusUpdate,
                  arguments: c,
                ).then((_) {
                  _loadComplaint(c.id);
                });
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMainInfoCard(c),
                        CivicFixSpacing.vSpaceLg,
                        _buildEvidenceGallery(c),
                      ],
                    ),
                  ),
                  CivicFixSpacing.hSpaceLg,
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDepartmentAssignmentCard(c),
                        CivicFixSpacing.vSpaceLg,
                        _buildTimelineCard(c),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainInfoCard(c),
                  CivicFixSpacing.vSpaceLg,
                  _buildDepartmentAssignmentCard(c),
                  CivicFixSpacing.vSpaceLg,
                  _buildEvidenceGallery(c),
                  CivicFixSpacing.vSpaceLg,
                  _buildTimelineCard(c),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(ComplaintModel c) {
    return DashboardCard(
      title: 'Grievance Overview',
      subtitle: 'Citizen reported information & location data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.ticketNumber,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.primary,
                  ),
                ),
              ),
              const Spacer(),
              PriorityBadge(priority: c.priority),
              CivicFixSpacing.hSpaceSm,
              StatusBadge(status: c.status),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          Text(
            c.title,
            style: CivicFixTypography.h2.copyWith(fontSize: 20),
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            c.description,
            style: CivicFixTypography.body.copyWith(
              color: GovtThemeTokens.textPrimary,
              height: 1.5,
            ),
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.border),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              _buildMetaItem(
                label: 'Category',
                value: c.category.name,
                icon: c.category.icon,
              ),
              CivicFixSpacing.hSpaceXl,
              _buildMetaItem(
                label: 'Ward / Locality',
                value: '${c.location.ward ?? "Ward 14"} (${c.location.address})',
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              _buildMetaItem(
                label: 'Submitted Date',
                value: DateFormatter.formatDateTime(c.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
              CivicFixSpacing.hSpaceXl,
              _buildMetaItem(
                label: 'Citizen Verification',
                value: 'Citizen ID verified via mobile OTP',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: GovtThemeTokens.textSecondary),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceGallery(ComplaintModel c) {
    return DashboardCard(
      title: 'Photo & Geographic Evidence',
      subtitle: '${c.imageUrls.length} image attachments provided',
      child: c.imageUrls.isEmpty
          ? Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GovtThemeTokens.border),
              ),
              child: Text(
                'No photo evidence was attached with this citizen report.',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
              ),
            )
          : Wrap(
              spacing: CivicFixSpacing.md,
              runSpacing: CivicFixSpacing.md,
              children: c.imageUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 140,
                    height: 140,
                    color: const Color(0xFFE0E0E0),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDepartmentAssignmentCard(ComplaintModel c) {
    return DashboardCard(
      title: 'Department & Crew Assignment',
      subtitle: 'Operational ownership',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment_rounded, color: GovtThemeTokens.info, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Department', style: CivicFixTypography.caption),
                    Text(
                      c.effectiveDepartment,
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_pin_rounded, color: GovtThemeTokens.secondary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Field Lead / Crew', style: CivicFixTypography.caption),
                    Text(
                      c.assignedTo ?? 'Pending Assignment',
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.assignedTo != null ? GovtThemeTokens.textPrimary : GovtThemeTokens.alert,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ComplaintModel c) {
    return DashboardCard(
      title: 'Status & Audit Trail',
      subtitle: '${c.timeline.length} milestone events logged',
      child: Column(
        children: c.timeline.map((evt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: evt.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evt.title,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        evt.description,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormatter.formatDateTime(evt.timestamp)}${evt.updatedBy != null ? " • By ${evt.updatedBy}" : ""}',
                        style: CivicFixTypography.caption.copyWith(
                          fontSize: 10,
                          color: GovtThemeTokens.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/ai/models/ai_analysis_status.dart';
import '../../../core/ai/models/ai_authenticity_enums.dart';
import '../../../core/ai/models/ai_authenticity_result.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../theme/govt_theme_tokens.dart';

/// Reusable Government-side UI component for displaying Gemini AI Authenticity Verification.
///
/// Presents an advisory evaluation of whether complaint evidence appears to be
/// a genuine camera photograph, likely AI-generated/manipulated, or uncertain.
///
/// NOTE: This component is presentation-only and strictly advisory. It must NEVER
/// be interpreted as mathematical or forensic proof of image origin.
class AiAuthenticityCard extends StatefulWidget {
  /// The structured AI authenticity result from Gemini.
  final AiAuthenticityResult? authenticity;

  /// The lifecycle status of the AI analysis.
  final AiAnalysisStatus? analysisStatus;

  /// Optional confidence override for display testing or corrupted payload handling.
  final double? confidence;

  /// When true, forces confidence to display as unavailable.
  final bool forceMissingConfidence;

  /// Whether the details section is initially expanded.
  final bool initiallyExpanded;

  const AiAuthenticityCard({
    super.key,
    this.authenticity,
    this.analysisStatus,
    this.confidence,
    this.forceMissingConfidence = false,
    this.initiallyExpanded = false,
  });

  /// Factory constructor taking a domain [ComplaintModel] directly.
  factory AiAuthenticityCard.fromComplaint(
    ComplaintModel complaint, {
    Key? key,
    bool initiallyExpanded = false,
  }) {
    // If complaint has no AI authenticity and is in default pending status,
    // treat as unanalyzed/legacy complaint rather than active pending task.
    final effectiveStatus = (complaint.aiAnalysisStatus == AiAnalysisStatus.processing ||
            complaint.aiAnalysisStatus == AiAnalysisStatus.failed)
        ? complaint.aiAnalysisStatus
        : (complaint.hasAiAuthenticity ? complaint.aiAnalysisStatus : null);

    return AiAuthenticityCard(
      key: key,
      authenticity: complaint.aiAuthenticity,
      analysisStatus: effectiveStatus,
      initiallyExpanded: initiallyExpanded,
    );
  }

  @override
  State<AiAuthenticityCard> createState() => _AiAuthenticityCardState();
}

class _AiAuthenticityCardState extends State<AiAuthenticityCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  _CardVisualState _resolveVisualState() {
    final status = widget.analysisStatus;
    final auth = widget.authenticity;

    // Explicit processing state
    if (status == AiAnalysisStatus.processing) {
      return _CardVisualState.processing;
    }

    // Explicit failure state (either failed lifecycle status or failed result object)
    if (status == AiAnalysisStatus.failed || (auth != null && !auth.isSuccess)) {
      return _CardVisualState.failed;
    }

    // Explicit pending state (when status is explicitly pending without completed result)
    if (status == AiAnalysisStatus.pending && auth == null) {
      return _CardVisualState.pending;
    }

    // Completed / Available Authenticity Result
    if (auth != null && auth.isSuccess) {
      switch (auth.status) {
        case AiAuthenticityStatus.likelyReal:
          return _CardVisualState.likelyReal;
        case AiAuthenticityStatus.likelyAiGenerated:
          return _CardVisualState.likelyAiGenerated;
        case AiAuthenticityStatus.uncertain:
          return _CardVisualState.uncertain;
      }
    }

    // Default: No AI authenticity data available (legacy complaints or unanalyzed)
    return _CardVisualState.notAnalyzed;
  }

  String _formatConfidence() {
    if (widget.forceMissingConfidence) {
      return 'Confidence unavailable';
    }
    final value = widget.confidence ?? widget.authenticity?.confidence;
    if (value == null) {
      return 'Confidence unavailable';
    }
    final pct = (value * 100).round();
    return 'Confidence: $pct%';
  }

  static String _formatModelName(String rawModel) {
    final lower = rawModel.toLowerCase();
    if (lower.contains('3.6-flash') || lower.contains('3.6_flash') || lower.contains('3.6 flash')) {
      return 'Gemini 3.6 Flash';
    }
    if (lower.contains('flash')) {
      return 'Gemini Flash';
    }
    if (lower == 'unknown' || lower.isEmpty) {
      return 'Gemini Multimodal';
    }
    return rawModel;
  }

  static String _formatIndicator(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[_-]'), ' ').trim();
    if (cleaned.isEmpty) return raw;
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final state = _resolveVisualState();

    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: state.borderColor),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Section Title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: state.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'AI IMAGE AUTHENTICITY',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,

                // Status & Confidence Row
                Wrap(
                  spacing: CivicFixSpacing.sm,
                  runSpacing: CivicFixSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Status Badge
                    _buildStatusBadge(state),

                    // Confidence (when applicable)
                    if (state.showsConfidence)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CivicFixSpacing.sm,
                          vertical: CivicFixSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: GovtThemeTokens.borderLight),
                        ),
                        child: Text(
                          _formatConfidence(),
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                CivicFixSpacing.vSpaceSm,

                // Primary Summary / Advisory Text
                Text(
                  state.summaryText,
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    height: 1.45,
                  ),
                ),

                // Additional Guidance for Failed state
                if (state == _CardVisualState.failed) ...[
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    'The complaint itself remains valid and can still be reviewed.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Action Button: View Analysis (only when analysis data exists)
                if (state.hasAnalysisDetails && widget.authenticity != null) ...[
                  CivicFixSpacing.vSpaceMd,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _isExpanded ? 'Hide Analysis' : 'View Analysis',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GovtThemeTokens.primary,
                        side: const BorderSide(color: GovtThemeTokens.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CivicFixSpacing.md,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Expandable Detailed Analysis Section
          if (_isExpanded && widget.authenticity != null)
            _buildExpandedDetails(widget.authenticity!),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_CardVisualState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: state.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: state.badgeBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == _CardVisualState.processing)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.info),
              ),
            )
          else
            Icon(
              state.badgeIcon,
              size: 15,
              color: state.badgeTextColor,
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              state.badgeLabel,
              style: CivicFixTypography.captionMedium.copyWith(
                color: state.badgeTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(AiAuthenticityResult auth) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFCFA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: GovtThemeTokens.border),
        ),
      ),
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Assessment / Reasoning
          Text(
            'Assessment',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            auth.reasoning,
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textPrimary,
              height: 1.45,
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // Section: Observed Indicators
          if (auth.indicators.isNotEmpty) ...[
            Text(
              'Observed indicators',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textPrimary,
              ),
            ),
            CivicFixSpacing.vSpaceXs,
            ...auth.indicators.map((ind) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: GovtThemeTokens.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatIndicator(ind),
                          style: CivicFixTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            CivicFixSpacing.vSpaceMd,
          ],

          // Section: Model & Timestamp Metadata
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.memory_rounded,
                    size: 14,
                    color: GovtThemeTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Model: ${_formatModelName(auth.model)}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: GovtThemeTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Analyzed: ${DateFormatter.formatDateTime(auth.analyzedAt)}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Mandatory Advisory Disclaimer Box (Step 6)
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: GovtThemeTokens.info,
                ),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-assisted assessment',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This result is an automated visual assessment and is not forensic proof of image origin. Use it as a supporting signal during complaint review and apply human judgment.',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal configuration for visual states of [AiAuthenticityCard].
enum _CardVisualState {
  likelyReal(
    badgeLabel: 'Likely Real',
    badgeIcon: Icons.check_circle_outline_rounded,
    summaryText:
        'AI-assisted assessment indicates that the image appears consistent with a genuine photograph.',
    badgeBackgroundColor: Color(0xFFEAF5EE),
    badgeBorderColor: Color(0xFFC3E6D0),
    badgeTextColor: Color(0xFF1B5E20),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.secondary,
    showsConfidence: true,
    hasAnalysisDetails: true,
  ),

  likelyAiGenerated(
    badgeLabel: 'Likely AI-Generated',
    badgeIcon: Icons.warning_amber_rounded,
    summaryText:
        'The image contains visual characteristics associated with synthetic or heavily manipulated imagery.',
    badgeBackgroundColor: Color(0xFFFEF8EC),
    badgeBorderColor: Color(0xFFFAD997),
    badgeTextColor: Color(0xFF8A5B00),
    borderColor: Color(0xFFFAD997),
    accentColor: GovtThemeTokens.alert,
    showsConfidence: true,
    hasAnalysisDetails: true,
  ),

  uncertain(
    badgeLabel: 'Uncertain',
    badgeIcon: Icons.help_outline_rounded,
    summaryText:
        'The available visual evidence was insufficient to reliably determine image authenticity.',
    badgeBackgroundColor: Color(0xFFF0F4F8),
    badgeBorderColor: Color(0xFFCDE0EE),
    badgeTextColor: Color(0xFF1A4B6E),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.info,
    showsConfidence: true,
    hasAnalysisDetails: true,
  ),

  processing(
    badgeLabel: 'Analysis in progress...',
    badgeIcon: Icons.sync_rounded,
    summaryText: 'Gemini is analyzing the submitted image.',
    badgeBackgroundColor: Color(0xFFF0F4F8),
    badgeBorderColor: Color(0xFFCDE0EE),
    badgeTextColor: Color(0xFF1A4B6E),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.info,
    showsConfidence: false,
    hasAnalysisDetails: false,
  ),

  pending(
    badgeLabel: 'Analysis Pending',
    badgeIcon: Icons.schedule_rounded,
    summaryText: 'Authenticity analysis has not been completed yet.',
    badgeBackgroundColor: Color(0xFFEFF3F0),
    badgeBorderColor: Color(0xFFD9E0DC),
    badgeTextColor: Color(0xFF5F6B73),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.textSecondary,
    showsConfidence: false,
    hasAnalysisDetails: false,
  ),

  failed(
    badgeLabel: 'Analysis Unavailable',
    badgeIcon: Icons.info_outline_rounded,
    summaryText: 'Authenticity analysis could not be completed.',
    badgeBackgroundColor: Color(0xFFFDF2F2),
    badgeBorderColor: Color(0xFFF5C2C2),
    badgeTextColor: Color(0xFF991B1B),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.error,
    showsConfidence: false,
    hasAnalysisDetails: false,
  ),

  notAnalyzed(
    badgeLabel: 'Not analyzed',
    badgeIcon: Icons.remove_circle_outline_rounded,
    summaryText: 'Evidence image was submitted without AI authenticity verification.',
    badgeBackgroundColor: Color(0xFFEFF3F0),
    badgeBorderColor: Color(0xFFD9E0DC),
    badgeTextColor: Color(0xFF5F6B73),
    borderColor: Color(0xFFD9E0DC),
    accentColor: GovtThemeTokens.textSecondary,
    showsConfidence: false,
    hasAnalysisDetails: false,
  );

  final String badgeLabel;
  final IconData badgeIcon;
  final String summaryText;
  final Color badgeBackgroundColor;
  final Color badgeBorderColor;
  final Color badgeTextColor;
  final Color borderColor;
  final Color accentColor;
  final bool showsConfidence;
  final bool hasAnalysisDetails;

  const _CardVisualState({
    required this.badgeLabel,
    required this.badgeIcon,
    required this.summaryText,
    required this.badgeBackgroundColor,
    required this.badgeBorderColor,
    required this.badgeTextColor,
    required this.borderColor,
    required this.accentColor,
    required this.showsConfidence,
    required this.hasAnalysisDetails,
  });
}

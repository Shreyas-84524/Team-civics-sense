import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Standardized error presentation state for municipal screens and components.
class GovernmentErrorState extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? errorCode;
  final String? technicalDetails;
  final bool isCompact;

  const GovernmentErrorState({
    super.key,
    this.title = 'Unable to Load Municipal Data',
    this.message = 'An unexpected system error occurred while retrieving government records.',
    this.onRetry,
    this.retryLabel = 'Retry Request',
    this.errorCode,
    this.technicalDetails,
    this.isCompact = false,
  });

  @override
  State<GovernmentErrorState> createState() => _GovernmentErrorStateState();
}

class _GovernmentErrorStateState extends State<GovernmentErrorState> {
  bool _isDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? CivicFixSpacing.md : CivicFixSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.isCompact ? 40 : 52,
                height: widget.isCompact ? 40 : 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: GovtThemeTokens.error,
                  size: widget.isCompact ? 20 : 26,
                ),
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                widget.title,
                style: widget.isCompact
                    ? GovtTypography.cardTitle.copyWith(color: GovtThemeTokens.textPrimary)
                    : GovtTypography.sectionTitle.copyWith(color: GovtThemeTokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.message,
                style: GovtTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.errorCode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GovtThemeTokens.border),
                  ),
                  child: Text(
                    'Code: ${widget.errorCode}',
                    style: GovtTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ],
              if (widget.onRetry != null) ...[
                CivicFixSpacing.vSpaceMd,
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(widget.retryLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.lg,
                      vertical: CivicFixSpacing.sm + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: GovtThemeTokens.buttonRadius,
                    ),
                  ),
                ),
              ],
              if (widget.technicalDetails != null && widget.technicalDetails!.isNotEmpty) ...[
                CivicFixSpacing.vSpaceMd,
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isDetailsExpanded = !_isDetailsExpanded;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isDetailsExpanded ? 'Hide Diagnostics' : 'Show Diagnostics',
                        style: GovtTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _isDetailsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (_isDetailsExpanded) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(CivicFixSpacing.sm),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GovtThemeTokens.border),
                    ),
                    child: SelectableText(
                      widget.technicalDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF374151),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

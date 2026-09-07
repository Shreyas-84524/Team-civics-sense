import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Column definition for GovtDataTable.
class GovtDataColumn {
  final String label;
  final double? width;
  final bool isNumeric;
  final Alignment alignment;

  const GovtDataColumn({
    required this.label,
    this.width,
    this.isNumeric = false,
    this.alignment = Alignment.centerLeft,
  });
}

/// Generic, responsive Data Table Wrapper for Government UI tables.
class GovtDataTable extends StatelessWidget {
  final List<GovtDataColumn> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final Widget? emptyWidget;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String? title;
  final Widget? headerAction;

  const GovtDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyWidget,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = 10,
    this.onPreviousPage,
    this.onNextPage,
    this.title,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar (if title or action is provided)
          if (title != null || headerAction != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.lg,
                vertical: CivicFixSpacing.md,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.h3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ?headerAction,
                ],
              ),
            ),
            const Divider(color: GovtThemeTokens.border, height: 1),
          ],

          // Table Content with horizontal scrollability
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(CivicFixSpacing.xxxl),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
                ),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xxl),
              child: emptyWidget ??
                  Center(
                    child: Text(
                      'No records found.',
                      style: CivicFixTypography.bodySmall,
                    ),
                  ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    for (int i = 0; i < columns.length; i++)
                      i: columns[i].width != null
                          ? FixedColumnWidth(columns[i].width!)
                          : const IntrinsicColumnWidth(),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F2),
                        border: Border(
                          bottom: BorderSide(color: GovtThemeTokens.border, width: 1.5),
                        ),
                      ),
                      children: columns.map((col) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.sm,
                            vertical: CivicFixSpacing.sm + 4,
                          ),
                          child: Align(
                            alignment: col.alignment,
                            child: Text(
                              col.label.toUpperCase(),
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: GovtThemeTokens.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Data Rows
                    for (int r = 0; r < rows.length; r++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: r % 2 == 0 ? Colors.white : const Color(0xFFFAFBFB),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFEBEFEA), width: 1),
                          ),
                        ),
                        children: rows[r].map((cell) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CivicFixSpacing.sm,
                              vertical: CivicFixSpacing.sm + 2,
                            ),
                            child: cell,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

          // Pagination Footer
          const Divider(color: GovtThemeTokens.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
              vertical: CivicFixSpacing.sm + 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Showing ${rows.length} of $totalCount items',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: currentPage > 1 ? onPreviousPage : null,
                      tooltip: 'Previous Page',
                      splashRadius: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    Text(
                      'Page $currentPage',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: (currentPage * pageSize < totalCount) ? onNextPage : null,
                      tooltip: 'Next Page',
                      splashRadius: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

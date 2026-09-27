import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_empty_state.dart';
import 'govt_loading_states.dart';

/// Column definition for [GovernmentDataTable].
class GovtDataColumn {
  final String label;
  final double? width;
  final bool isNumeric;
  final Alignment alignment;
  final bool isSortable;
  final String? tooltip;

  const GovtDataColumn({
    required this.label,
    this.width,
    this.isNumeric = false,
    this.alignment = Alignment.centerLeft,
    this.isSortable = false,
    this.tooltip,
  });
}

/// Generic, highly reusable municipal Data Table component.
class GovernmentDataTable extends StatelessWidget {
  final List<GovtDataColumn> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final void Function(int page)? onPageSelected;
  final String? title;
  final Widget? headerAction;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool selectable;
  final Set<int>? selectedRows;
  final void Function(int rowIndex, bool selected)? onSelectRow;
  final void Function(bool selected)? onSelectAll;
  final bool isDense;
  final double minWidth;

  const GovernmentDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyWidget,
    this.errorWidget,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = 10,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
    this.title,
    this.headerAction,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.selectable = false,
    this.selectedRows,
    this.onSelectRow,
    this.onSelectAll,
    this.isDense = false,
    this.minWidth = 720.0,
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
              padding: EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.lg,
                vertical: isDense ? CivicFixSpacing.sm : CivicFixSpacing.md,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GovtTypography.cardTitle.copyWith(
                          fontSize: isDense ? 15 : 16,
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

          // Table Body: Loading / Error / Empty / Data
          if (isLoading)
            GovtTableSkeleton(
              rowCount: pageSize > 0 && pageSize <= 8 ? pageSize : 5,
              columnCount: columns.length + (selectable ? 1 : 0),
            )
          else if (errorWidget != null)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: errorWidget!,
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xxl),
              child: emptyWidget ??
                  const GovtEmptyState(
                    title: 'No records found',
                    message: 'There are no items to display for the active query.',
                    isCompact: true,
                  ),
            )
          else
            _buildTableBody(context),

          // Pagination Footer
          const Divider(color: GovtThemeTokens.border, height: 1),
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  Widget _buildTableBody(BuildContext context) {
    final allSelected = selectable &&
        selectedRows != null &&
        rows.isNotEmpty &&
        selectedRows!.length == rows.length;

    final cellPaddingVertical = isDense ? 6.0 : 10.0;
    final cellPaddingHorizontal = isDense ? CivicFixSpacing.xs + 2 : CivicFixSpacing.sm;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            if (selectable) 0: const FixedColumnWidth(48.0),
            for (int i = 0; i < columns.length; i++)
              (selectable ? i + 1 : i): columns[i].width != null
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
              children: [
                if (selectable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Center(
                      child: Checkbox(
                        value: allSelected,
                        onChanged: onSelectAll != null
                            ? (val) => onSelectAll!(val ?? false)
                            : null,
                        activeColor: GovtThemeTokens.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ...columns.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final col = entry.value;
                  final isSorted = sortColumnIndex == idx;

                  Widget headerLabel = Text(
                    col.label.toUpperCase(),
                    style: GovtTypography.label.copyWith(
                      color: isSorted ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  );

                  if (col.isSortable) {
                    headerLabel = InkWell(
                      onTap: onSort != null
                          ? () => onSort!(idx, isSorted ? !sortAscending : true)
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: headerLabel),
                          const SizedBox(width: 4),
                          Icon(
                            isSorted
                                ? (sortAscending
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded)
                                : Icons.unfold_more_rounded,
                            size: 14,
                            color: isSorted
                                ? GovtThemeTokens.primary
                                : GovtThemeTokens.textMuted,
                          ),
                        ],
                      ),
                    );
                  }

                  if (col.tooltip != null) {
                    headerLabel = Tooltip(
                      message: col.tooltip!,
                      child: headerLabel,
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cellPaddingHorizontal,
                      vertical: isDense ? 8 : 12,
                    ),
                    child: Align(
                      alignment: col.alignment,
                      child: headerLabel,
                    ),
                  );
                }),
              ],
            ),

            // Data Rows
            for (int r = 0; r < rows.length; r++) ...[
              TableRow(
                decoration: BoxDecoration(
                  color: selectedRows?.contains(r) == true
                      ? const Color(0xFFEFF6FF)
                      : (r % 2 == 0 ? Colors.white : const Color(0xFFFAFBFB)),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFEBEFEA), width: 1),
                  ),
                ),
                children: [
                  if (selectable)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Center(
                        child: Checkbox(
                          value: selectedRows?.contains(r) ?? false,
                          onChanged: onSelectRow != null
                              ? (val) => onSelectRow!(r, val ?? false)
                              : null,
                          activeColor: GovtThemeTokens.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ...rows[r].map((cell) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: cellPaddingHorizontal,
                        vertical: cellPaddingVertical,
                      ),
                      child: cell,
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final startItem = totalCount == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final endItem = ((currentPage - 1) * pageSize) + rows.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.lg,
        vertical: CivicFixSpacing.sm + 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              totalCount > 0
                  ? 'Showing $startItem–$endItem of $totalCount items'
                  : 'Showing ${rows.length} items',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GovtTypography.caption.copyWith(
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
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Text(
                'Page $currentPage',
                style: GovtTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: GovtThemeTokens.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: (currentPage * pageSize < totalCount) ? onNextPage : null,
                tooltip: 'Next Page',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Backwards compatibility typedef so existing code referencing GovtDataTable continues working seamlessly.
typedef GovtDataTable = GovernmentDataTable;

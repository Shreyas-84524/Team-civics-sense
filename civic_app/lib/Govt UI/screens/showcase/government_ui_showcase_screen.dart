import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/complaint_routing_ticket_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import '../../widgets/common/government_alert.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_confirmation_dialog.dart';
import '../../widgets/common/government_data_table.dart';
import '../../widgets/common/government_error_state.dart';
import '../../widgets/common/government_filter_bar.dart';
import '../../widgets/common/government_kpi_card.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/government_section_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../../widgets/common/govt_card.dart';
import '../../widgets/common/govt_empty_state.dart';
import '../../widgets/common/govt_filter_chip.dart';
import '../../widgets/common/govt_jurisdiction_badge.dart';
import '../../widgets/common/govt_loading_states.dart';
import '../../widgets/common/govt_priority_badge.dart';
import '../../widgets/common/govt_search_field.dart';
import '../../widgets/common/govt_sla_badge.dart';
import '../../widgets/common/govt_status_badge.dart';

/// Development showcase screen allowing comprehensive visual auditing
/// of all CivicFix Government Design System tokens, components, and states.
class GovernmentUiShowcaseScreen extends StatefulWidget {
  const GovernmentUiShowcaseScreen({super.key});

  @override
  State<GovernmentUiShowcaseScreen> createState() =>
      _GovernmentUiShowcaseScreenState();
}

class _GovernmentUiShowcaseScreenState extends State<GovernmentUiShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  final Set<int> _selectedTableRows = {0, 2};
  int _sortCol = 0;
  bool _sortAsc = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GovernmentAppShell(
      title: 'Design System & Component Showcase',
      subtitle: 'Visual verification harness for Phase 1 municipal UI components',
      breadcrumbs: const [
        GovtBreadcrumbItem(label: 'Government Portal'),
        GovtBreadcrumbItem(label: 'Developer Showcase'),
      ],
      actions: [
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Design Tokens',
          onPressed: () => _tabController.animateTo(0),
        ),
      ],
      body: Column(
        children: [
          GovernmentPageHeader(
            title: 'Design System & Component Showcase',
            subtitle: 'Visual verification harness for Phase 1 municipal UI components',
            jurisdictionBadge: GovtJurisdictionBadge.zone('Command Center'),
            statusWidget: GovtStatusBadge.complaint(ComplaintStatus.verified, isCompact: true),
          ),
          // Section Tabs
          Container(
            color: GovtThemeTokens.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: GovtThemeTokens.primary,
              unselectedLabelColor: GovtThemeTokens.textSecondary,
              indicatorColor: GovtThemeTokens.primary,
              indicatorWeight: 3,
              labelStyle: GovtTypography.cardTitle.copyWith(fontSize: 13),
              tabs: const [
                Tab(text: 'Tokens & Typography'),
                Tab(text: 'Badges & Context'),
                Tab(text: 'KPI Metric Cards'),
                Tab(text: 'Surfaces & Cards'),
                Tab(text: 'Alerts & Banners'),
                Tab(text: 'Tables & Filters'),
                Tab(text: 'States & Dialogs'),
              ],
            ),
          ),
          const Divider(color: GovtThemeTokens.border, height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTokensAndTypographyTab(),
                _buildBadgesTab(),
                _buildKpiCardsTab(),
                _buildSurfacesTab(),
                _buildAlertsTab(),
                _buildTablesAndFiltersTab(),
                _buildStatesAndDialogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Tokens & Typography
  Widget _buildTokensAndTypographyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Color Palette Tokens',
            subtitle: 'Curated authoritative municipal operations color palette',
          ),
          CivicFixSpacing.vSpaceMd,
          Wrap(
            spacing: CivicFixSpacing.md,
            runSpacing: CivicFixSpacing.md,
            children: [
              _buildColorSwatch('Primary Navy', GovtThemeTokens.primary, '#12304A'),
              _buildColorSwatch('Secondary Green', GovtThemeTokens.secondary, '#2E8B57'),
              _buildColorSwatch('Accent Mint', GovtThemeTokens.accent, '#7ED6A5'),
              _buildColorSwatch('Background', GovtThemeTokens.background, '#F7F9F7'),
              _buildColorSwatch('Surface Muted', GovtThemeTokens.surfaceMuted, '#EFF3F0'),
              _buildColorSwatch('Border Light', GovtThemeTokens.border, '#D9E0DC'),
              _buildColorSwatch('Info Blue', GovtThemeTokens.info, '#2F6F95'),
              _buildColorSwatch('Warning Amber', GovtThemeTokens.warning, '#F4B942'),
              _buildColorSwatch('Error Red', GovtThemeTokens.error, '#C62828'),
              _buildColorSwatch('Critical Red', GovtThemeTokens.critical, '#B71C1C'),
            ],
          ),
          CivicFixSpacing.vSpaceXxl,
          const GovernmentSectionHeader(
            title: 'Typography Hierarchy',
            subtitle: 'Standardized typography scale based on GovtTypography',
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Display Large (32px)', style: GovtTypography.displayLarge),
                CivicFixSpacing.vSpaceSm,
                const Text('Page Title (24px)', style: GovtTypography.pageTitle),
                CivicFixSpacing.vSpaceSm,
                const Text('Section Title (18px)', style: GovtTypography.sectionTitle),
                CivicFixSpacing.vSpaceSm,
                const Text('Card Title (16px)', style: GovtTypography.cardTitle),
                CivicFixSpacing.vSpaceSm,
                const Text(
                  'Body Large (16px) — Municipal grievance records administration and oversight.',
                  style: GovtTypography.bodyLarge,
                ),
                CivicFixSpacing.vSpaceSm,
                const Text(
                  'Body (14px) — Standard administrative descriptive text for complaint workflows.',
                  style: GovtTypography.body,
                ),
                CivicFixSpacing.vSpaceSm,
                const Text(
                  'Body Small (12px) — Supporting secondary metadata and table cell contents.',
                  style: GovtTypography.bodySmall,
                ),
                CivicFixSpacing.vSpaceSm,
                const Text('LABEL UPPERCASE (12PX)', style: GovtTypography.label),
                CivicFixSpacing.vSpaceSm,
                const Text('Caption (11px) — Timestamp 2026-09-27T12:00:00Z',
                    style: GovtTypography.caption),
                CivicFixSpacing.vSpaceSm,
                Row(
                  children: [
                    Text('Metric Large: 1,482', style: GovtTypography.metricLarge),
                    CivicFixSpacing.hSpaceXl,
                    Text('Metric Small: 92.4%', style: GovtTypography.metricSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color, String hex) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x1A000000)),
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            name,
            style: GovtTypography.caption.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hex,
            style: GovtTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Badges & Context
  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Complaint Lifecycle Badges',
            subtitle: 'Standard status chips across municipal complaint workflow',
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: [
              GovtStatusBadge.complaint(ComplaintStatus.reported),
              GovtStatusBadge.complaint(ComplaintStatus.verified),
              GovtStatusBadge.complaint(ComplaintStatus.assigned),
              GovtStatusBadge.complaint(ComplaintStatus.inProgress),
              GovtStatusBadge.fromComplaintStatusString('awaiting_verification'),
              GovtStatusBadge.complaint(ComplaintStatus.resolved),
              GovtStatusBadge.complaint(ComplaintStatus.rejected),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const GovernmentSectionHeader(
            title: 'Routing & Transfer Ticket Badges',
            subtitle: 'Departmental reassignment and cross-jurisdiction routing statuses',
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: [
              GovtStatusBadge.routing(ComplaintRoutingStatus.assigned),
              GovtStatusBadge.routing(ComplaintRoutingStatus.reassignmentRequested),
              GovtStatusBadge.routing(ComplaintRoutingStatus.transferred),
              GovtStatusBadge.ticket(RoutingTicketStatus.pending),
              GovtStatusBadge.ticket(RoutingTicketStatus.approved),
              GovtStatusBadge.ticket(RoutingTicketStatus.rejected),
              GovtStatusBadge.ticket(RoutingTicketStatus.cancelled),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const GovernmentSectionHeader(
            title: 'Priority & SLA Badges',
            subtitle: 'Urgency tier indicators and statutory SLA compliance states',
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: [
              GovtPriorityBadge.fromPriority(ComplaintPriority.low),
              GovtPriorityBadge.fromPriority(ComplaintPriority.medium),
              GovtPriorityBadge.fromPriority(ComplaintPriority.high),
              GovtPriorityBadge.fromPriority(ComplaintPriority.emergency),
              GovtSlaBadge.healthy(remainingText: 'SLA Healthy (36h left)'),
              GovtSlaBadge.warning(remainingText: 'SLA Warning (< 4h left)'),
              GovtSlaBadge.breached(overdueText: 'SLA Breached (+8h)'),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const GovernmentSectionHeader(
            title: 'Administrative Jurisdiction Badges',
            subtitle: 'Compact identifiers for Zone, Ward, Department, and Role',
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: [
              GovtJurisdictionBadge.zone('Zone 4'),
              GovtJurisdictionBadge.ward('N Ward'),
              GovtJurisdictionBadge.department('Solid Waste Management'),
              GovtJurisdictionBadge.department('Roads & Infrastructure'),
              GovtJurisdictionBadge.role('Ward Officer'),
              GovtJurisdictionBadge.role('Assistant Commissioner'),
            ],
          ),
        ],
      ),
    );
  }

  // 3. KPI Metric Cards
  Widget _buildKpiCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Government KPI Metric Cards',
            subtitle: 'Reusable metrics cards supporting values, trends, loading, and error states',
          ),
          CivicFixSpacing.vSpaceMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isTablet = constraints.maxWidth >= 550 && !isDesktop;

              return GridView.count(
                crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
                crossAxisSpacing: CivicFixSpacing.md,
                mainAxisSpacing: CivicFixSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  const GovernmentKpiCard(
                    title: 'Open Complaints',
                    metric: '487',
                    icon: Icons.assignment_outlined,
                    iconColor: GovtThemeTokens.primary,
                    percentageChange: -4.2,
                    percentageLabel: 'vs last week',
                  ),
                  const GovernmentKpiCard(
                    title: 'Resolved Today',
                    metric: '148',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: GovtThemeTokens.success,
                    percentageChange: 12.8,
                    percentageLabel: 'vs average',
                  ),
                  const GovernmentKpiCard(
                    title: 'SLA Compliance',
                    metric: '92.4%',
                    icon: Icons.timer_outlined,
                    iconColor: GovtThemeTokens.info,
                    status: 'Healthy Target',
                    statusColor: GovtThemeTokens.success,
                  ),
                  const GovernmentKpiCard(
                    title: 'Critical Escalations',
                    metric: '19',
                    icon: Icons.warning_amber_rounded,
                    iconColor: GovtThemeTokens.critical,
                    status: 'Requires Action',
                    statusColor: GovtThemeTokens.critical,
                  ),
                  const GovernmentKpiCard(
                    title: 'Async Loading Sample',
                    metric: '---',
                    icon: Icons.refresh,
                    isLoading: true,
                  ),
                  GovernmentKpiCard(
                    title: 'Network Timeout Sample',
                    metric: '0',
                    icon: Icons.sync_problem_rounded,
                    errorMessage: 'Municipal API timed out (504 Gateway)',
                    onRetry: () {},
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Surfaces & Cards
  Widget _buildSurfacesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Surface Variants',
            subtitle: 'Consistent, structured cards for operational widgets',
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard(
            title: 'Standard Surface Card',
            subtitle: 'Default white card container with 1px border and subtle shadow',
            trailing: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {},
            ),
            child: const Text(
              'Used for primary dashboards, data representations, and departmental reports.',
              style: GovtTypography.body,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard.info(
            title: 'Informational Surface Card',
            child: const Text(
              'Used for system notices, SOP instructions, and policy guidance for officers.',
              style: GovtTypography.bodySmall,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard.warning(
            title: 'Operational Warning Card',
            child: const Text(
              'Used for potential SLA breaches, crew reallocations, and resource constraints.',
              style: GovtTypography.bodySmall,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard.critical(
            title: 'Critical Emergency Card',
            child: const Text(
              'Used for severe civic safety hazards, water main ruptures, and collapsed trees.',
              style: GovtTypography.bodySmall,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard.interactive(
            title: 'Clickable Navigation Card',
            subtitle: 'Tap to inspect detailed grievance audit logs',
            onTap: () {},
            child: const Text(
              'Features hover highlights, responsive feedback, and an integrated navigation indicator.',
              style: GovtTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Alerts & Banners
  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Alert & Banner Components',
            subtitle: 'Compact authoritative alert banners for operational status readouts',
          ),
          CivicFixSpacing.vSpaceMd,
          GovernmentAlert.info(
            title: 'System Maintenance Window',
            message: 'Central BMC servers will undergo scheduled index rebalancing at 02:00 AM.',
            onDismiss: () {},
          ),
          CivicFixSpacing.vSpaceMd,
          GovernmentAlert.success(
            title: 'Reassignment Batch Processed',
            message: 'All 14 pending department transfer tickets were successfully finalized.',
            onDismiss: () {},
          ),
          CivicFixSpacing.vSpaceMd,
          GovernmentAlert.warning(
            title: 'SLA Warning Threshold Exceeded',
            message: '7 routing requests require your review before the 48-hour threshold closes.',
            action: TextButton(
              onPressed: () {},
              child: const Text('Review Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            onDismiss: () {},
          ),
          CivicFixSpacing.vSpaceMd,
          GovernmentAlert.critical(
            title: 'Statutory SLA Breached',
            message: '3 high-priority water contamination complaints in N Ward have breached SLA.',
            action: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.critical,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text('Escalate Immediately'),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Tables & Filters
  Widget _buildTablesAndFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Standalone Search Input with Debounce',
            subtitle: 'Debounced search with clear trigger and accessible keyboard navigation',
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.md,
            runSpacing: CivicFixSpacing.sm,
            children: [
              GovtSearchField(
                hintText: 'Type to test 300ms debounce...',
                onChanged: (val) {},
              ),
              const GovtSearchField(
                hintText: 'Loading state indicator...',
                isLoading: true,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXl,
          const GovernmentSectionHeader(
            title: 'Filter Toolbar',
            subtitle: 'Dynamic query bar with search debounce, category chips, and dropdown filters',
          ),
          CivicFixSpacing.vSpaceSm,
          GovernmentFilterBar(
            searchQuery: _searchQuery,
            searchHint: 'Search complaint ID, keywords...',
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            activeFilterCount: 2,
            onClearAll: () {
              setState(() {
                _searchQuery = '';
                _selectedFilterIndex = 0;
              });
            },
            dropdownFilters: [
              GovtDropdownFilterConfig<String>(
                label: 'Ward',
                selectedValue: 'N Ward',
                items: const [
                  DropdownMenuItem(value: 'All Wards', child: Text('All Wards')),
                  DropdownMenuItem(value: 'N Ward', child: Text('N Ward')),
                  DropdownMenuItem(value: 'K/East Ward', child: Text('K/East Ward')),
                ],
                onChanged: (val) {},
              ),
              GovtDropdownFilterConfig<String>(
                label: 'Status',
                selectedValue: null,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'reported', child: Text('Reported')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                ],
                onChanged: (val) {},
              ),
            ],
            customChips: [
              GovtFilterChip(
                label: 'All Items',
                isSelected: _selectedFilterIndex == 0,
                count: 142,
                onSelected: (_) => setState(() => _selectedFilterIndex = 0),
              ),
              const SizedBox(width: 8),
              GovtFilterChip(
                label: 'High Priority',
                isSelected: _selectedFilterIndex == 1,
                count: 18,
                activeColor: const Color(0xFFD97706),
                onSelected: (_) => setState(() => _selectedFilterIndex = 1),
              ),
              const SizedBox(width: 8),
              GovtFilterChip(
                label: 'SLA Breached',
                isSelected: _selectedFilterIndex == 2,
                count: 3,
                activeColor: GovtThemeTokens.critical,
                onSelected: (_) => setState(() => _selectedFilterIndex = 2),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXl,
          const GovernmentSectionHeader(
            title: 'Generic Government Data Table',
            subtitle: 'Standardized municipal table with sorting, pagination, and multi-row selection',
          ),
          CivicFixSpacing.vSpaceSm,
          GovernmentDataTable(
            title: 'Grievance Workload Queue',
            selectable: true,
            selectedRows: _selectedTableRows,
            onSelectRow: (r, selected) {
              setState(() {
                if (selected) {
                  _selectedTableRows.add(r);
                } else {
                  _selectedTableRows.remove(r);
                }
              });
            },
            onSelectAll: (selected) {
              setState(() {
                if (selected) {
                  _selectedTableRows.addAll([0, 1, 2, 3]);
                } else {
                  _selectedTableRows.clear();
                }
              });
            },
            sortColumnIndex: _sortCol,
            sortAscending: _sortAsc,
            onSort: (col, asc) {
              setState(() {
                _sortCol = col;
                _sortAsc = asc;
              });
            },
            currentPage: _currentPage,
            pageSize: 4,
            totalCount: 24,
            onPreviousPage: () => setState(() => _currentPage--),
            onNextPage: () => setState(() => _currentPage++),
            columns: const [
              GovtDataColumn(label: 'Complaint ID', width: 130, isSortable: true),
              GovtDataColumn(label: 'Category', width: 150),
              GovtDataColumn(label: 'Ward / Zone', width: 140),
              GovtDataColumn(label: 'Status', width: 150),
              GovtDataColumn(label: 'Priority', width: 120),
              GovtDataColumn(label: 'SLA State', width: 160),
            ],
            rows: [
              [
                const Text('CF-2026-1049', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('Potholes & Roads'),
                GovtJurisdictionBadge.ward('N Ward', isCompact: true),
                GovtStatusBadge.complaint(ComplaintStatus.inProgress, isCompact: true),
                GovtPriorityBadge.fromPriority(ComplaintPriority.high, isCompact: true),
                GovtSlaBadge.warning(remainingText: '< 3h left', isCompact: true),
              ],
              [
                const Text('CF-2026-1048', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('Garbage Overflow'),
                GovtJurisdictionBadge.ward('K/West', isCompact: true),
                GovtStatusBadge.complaint(ComplaintStatus.assigned, isCompact: true),
                GovtPriorityBadge.fromPriority(ComplaintPriority.medium, isCompact: true),
                GovtSlaBadge.healthy(remainingText: '28h left', isCompact: true),
              ],
              [
                const Text('CF-2026-1042', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('Water Main Rupture'),
                GovtJurisdictionBadge.ward('N Ward', isCompact: true),
                GovtStatusBadge.complaint(ComplaintStatus.inProgress, isCompact: true),
                GovtPriorityBadge.fromPriority(ComplaintPriority.emergency, isCompact: true),
                GovtSlaBadge.breached(overdueText: 'Breached (+4h)', isCompact: true),
              ],
              [
                const Text('CF-2026-1039', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('Streetlight Outage'),
                GovtJurisdictionBadge.ward('G/North', isCompact: true),
                GovtStatusBadge.complaint(ComplaintStatus.resolved, isCompact: true),
                GovtPriorityBadge.fromPriority(ComplaintPriority.low, isCompact: true),
                GovtSlaBadge.healthy(remainingText: 'Resolved', isCompact: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 7. States & Dialogs
  Widget _buildStatesAndDialogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GovernmentSectionHeader(
            title: 'Empty & Error States',
            subtitle: 'Polished states for empty queries and recoverable error handling',
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard(
            child: GovtEmptyState.noComplaints(
              actionLabel: 'Reset Filters',
              onAction: () {},
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard(
            child: GovernmentErrorState(
              title: 'Unable to synchronize departmental records',
              message: 'Check network connectivity or retry your request.',
              errorCode: 'NET_TIMEOUT_408',
              technicalDetails:
                  'Trace ID: bmc-gw-991204\nPayload: { ward: "N", status: "open" }\nHost: https://api.civicfix.gov.in/v1/grievances',
              onRetry: () {},
            ),
          ),
          CivicFixSpacing.vSpaceXl,
          const GovernmentSectionHeader(
            title: 'Loading States & Skeletons',
            subtitle: 'Inline, button, and skeleton indicators for asynchronous municipal operations',
          ),
          CivicFixSpacing.vSpaceMd,
          GovtCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Column(
                  children: [
                    GovtInlineLoader(),
                    SizedBox(height: 6),
                    Text('Inline Loader', style: GovtTypography.caption),
                  ],
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const GovtButtonLoader(size: 16),
                      label: const Text('Submitting...'),
                      style: ElevatedButton.styleFrom(backgroundColor: GovtThemeTokens.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text('Button Loader', style: GovtTypography.caption),
                  ],
                ),
                const Column(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 80,
                      child: GovtKpiSkeleton(),
                    ),
                    SizedBox(height: 6),
                    Text('Skeleton KPI', style: GovtTypography.caption),
                  ],
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceXl,
          const GovernmentSectionHeader(
            title: 'Confirmation Dialog Examples',
            subtitle: 'Standardized modals for neutral, warning, destructive, and confirmation workflows',
          ),
          CivicFixSpacing.vSpaceMd,
          Wrap(
            spacing: CivicFixSpacing.md,
            runSpacing: CivicFixSpacing.sm,
            children: [
              ElevatedButton(
                onPressed: () {
                  GovernmentConfirmationDialog.show(
                    context,
                    title: 'Approve Reassignment Ticket',
                    message:
                        'Transfer this grievance from Roads & Infrastructure to Solid Waste Management?',
                    confirmLabel: 'Approve Transfer',
                    type: GovtDialogType.confirmation,
                    onConfirm: () {},
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: GovtThemeTokens.secondary),
                child: const Text('Confirmation Dialog'),
              ),
              ElevatedButton(
                onPressed: () {
                  GovernmentConfirmationDialog.show(
                    context,
                    title: 'Escalate to Zonal Commissioner',
                    message:
                        'This will notify Deputy Municipal Commissioner of Zone 4 regarding statutory SLA breach.',
                    confirmLabel: 'Proceed with Escalation',
                    type: GovtDialogType.warning,
                    onConfirm: () {},
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                child: const Text('Warning Dialog'),
              ),
              ElevatedButton(
                onPressed: () {
                  GovernmentConfirmationDialog.show(
                    context,
                    title: 'Reject Routing Request',
                    message:
                        'The complaint will remain assigned to the originating ward department.',
                    confirmLabel: 'Reject Request',
                    type: GovtDialogType.destructive,
                    onConfirm: () {},
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: GovtThemeTokens.error),
                child: const Text('Destructive Dialog'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

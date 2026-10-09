import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/repositories/repository_locator.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/offline_cache_banner.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/localization/app_localizations.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_data_table.dart';
import '../../widgets/common/govt_search_field.dart';
import '../../widgets/complaints/govt_complaint_card.dart';

/// Complete screen for Government Complaint & Grievance Management.
class GovtComplaintListScreen extends StatefulWidget {
  final GovtComplaintRepository? repository;
  final ConnectivityService? connectivityService;

  const GovtComplaintListScreen({
    super.key,
    this.repository,
    this.connectivityService,
  });

  @override
  State<GovtComplaintListScreen> createState() => _GovtComplaintListScreenState();
}

class _GovtComplaintListScreenState extends State<GovtComplaintListScreen> {
  late final GovtComplaintRepository _repository;
  late final ConnectivityService _connectivityService;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;

  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _hasActiveFilters => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RepositoryLocator.govtComplaintRepository;
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadComplaints();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _repository
        .watchComplaints(
          searchQuery: _searchController.text,
        )
        .listen(
      (data) {
        if (mounted) {
          setState(() {
            _complaints = data;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load complaints: $e';
            _isLoading = false;
          });
        }
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
    });
    _loadComplaints();
  }

  void _openDetails(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintDetails,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  void _openAssignment(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintAssignment,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  void _openStatusUpdate(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtStatusUpdate,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= GovtThemeTokens.desktopBreakpoint;

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Toolbar
            _buildToolbar(),
            CivicFixSpacing.vSpaceMd,

            // Main Grievance List / Table / Error / Empty
            _buildBody(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(CivicFixSpacing.xl),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.alert.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: GovtThemeTokens.alert),
              CivicFixSpacing.vSpaceMd,
              Text(
                _errorMessage!,
                style: CivicFixTypography.body.copyWith(color: GovtThemeTokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceLg,
              ElevatedButton.icon(
                onPressed: _loadComplaints,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopTable();
    } else {
      return _buildResponsiveCardsList();
    }
  }

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_connectivityService.isOnline)
            OfflineCacheBanner(
              customMessage: 'Offline — Showing cached grievances. Synchronization disabled.',
              onRefresh: _loadComplaints,
            ),
          Row(
            children: [
              Expanded(
                child: GovtSearchField(
                  controller: _searchController,
                  hintText: l10n?.govSearchComplaintsHint ?? 'Search by Ticket #, title, ward, address, citizen ID...',
                  onChanged: (_) => _loadComplaints(),
                  onClear: () => _loadComplaints(),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              if (_hasActiveFilters) ...[
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: Text(l10n?.clearFilters ?? 'Clear Search', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GovtThemeTokens.textSecondary,
                    side: const BorderSide(color: GovtThemeTokens.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
              ],
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh List',
                onPressed: _loadComplaints,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    final l10n = AppLocalizations.of(context);

    if (!_isLoading && _complaints.isEmpty) {
      return _buildEmptyState();
    }

    final columns = [
      GovtDataColumn(label: l10n?.govTableHeaderId ?? 'Ticket #', width: 140),
      GovtDataColumn(label: l10n?.govTableHeaderCategory ?? 'Subject / Category', width: 260),
      GovtDataColumn(label: l10n?.govTableHeaderWard ?? 'Location / Ward', width: 220),
      GovtDataColumn(label: l10n?.govTableHeaderStatus ?? 'Status', width: 160),
      GovtDataColumn(label: l10n?.govTableHeaderReported ?? 'Reported', width: 140),
    ];

    final rows = _complaints.map((c) {
      return [
        InkWell(
          onTap: () => _openDetails(c),
          child: Text(
            c.ticketNumber,
            style: CivicFixTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.primary,
            ),
          ),
        ),
        InkWell(
          onTap: () => _openDetails(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                localizedCategory(c.category.name, context: context),
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${c.location.address}\n${c.location.ward ?? "Central Zone"}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.caption,
        ),
        StatusBadge(status: c.status, isCompact: true),
        Text(
          DateFormatter.formatRelative(c.createdAt),
          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
        ),
      ];
    }).toList();

    return GovtDataTable(
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      totalCount: _complaints.length,
      currentPage: 1,
    );
  }

  Widget _buildResponsiveCardsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _complaints.length,
      separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
      itemBuilder: (context, index) {
        final c = _complaints[index];
        return GovtComplaintCard(
          complaint: c,
          onTap: () => _openDetails(c),
          onAssign: () => _openAssignment(c),
          onUpdateStatus: () => _openStatusUpdate(c),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.xxl),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: GovtThemeTokens.textDisabled,
            ),
            CivicFixSpacing.vSpaceMd,
            Text(
              l10n?.govNoMatchingComplaints ?? 'No complaints found',
              style: CivicFixTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            CivicFixSpacing.vSpaceXs,
            Text(
              'No civic grievances match the active search criteria.',
              style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              CivicFixSpacing.vSpaceLg,
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: Text(l10n?.clearFilters ?? 'Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

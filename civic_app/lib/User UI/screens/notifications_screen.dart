import 'package:flutter/material.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/notification_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/notification_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../widgets/assistant/civic_assistant_fab.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/notification_skeleton.dart';

enum NotificationFilter { all, unread, read }

/// Complete Citizen Notifications Center with filtering and bulk mark-all-read.
class NotificationsScreen extends StatefulWidget {
  final NotificationRepository? notificationRepository;
  final ComplaintRepository? complaintRepository;
  final ConnectivityService? connectivityService;

  const NotificationsScreen({
    super.key,
    this.notificationRepository,
    this.complaintRepository,
    this.connectivityService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _notificationRepository;
  late final ComplaintRepository _complaintRepository;
  late final ConnectivityService _connectivityService;

  List<NotificationModel> _allNotifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _notificationRepository = widget.notificationRepository ?? RepositoryLocator.notificationRepository;
    _complaintRepository = widget.complaintRepository ?? RepositoryLocator.complaintRepository;
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadNotifications();
  }

  String? get _currentUserId => AuthServiceLocator.citizenAuth.currentUser?.id;

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _notificationRepository.getNotifications(userId: _currentUserId);
      if (!mounted) return;
      setState(() {
        _allNotifications = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load notifications.";
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationRepository.markAllAsRead(userId: _currentUserId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10nOrNull?.allNotificationsMarkedAsRead ?? 'All notifications marked as read.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadNotifications();
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case NotificationFilter.all:
        return _allNotifications;
      case NotificationFilter.unread:
        return _allNotifications.where((n) => !n.isRead).toList();
      case NotificationFilter.read:
        return _allNotifications.where((n) => n.isRead).toList();
    }
  }

  int get _unreadCount => _allNotifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      floatingActionButton: const CivicChatbotFab(heroTag: 'notifications_assistant_fab'),
      appBar: CivicFixAppBar(
        title: l10n?.navNotifications ?? 'Notifications',
        automaticallyImplyLeading: false,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n?.markAllAsRead ?? 'Mark all as read',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: CivicFixSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_connectivityService.isOnline)
                OfflineCacheBanner(
                  onRefresh: _loadNotifications,
                ),
              // 1. Filter Chips Row: All, Unread, Read
              _buildFilterChips(),
              CivicFixSpacing.vSpaceMd,

              // 2. Notifications List or States
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final l10n = context.l10nOrNull;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(l10n?.filterAll ?? 'All', NotificationFilter.all, _allNotifications.length),
          CivicFixSpacing.hSpaceSm,
          _buildFilterChip(l10n?.filterUnread ?? 'Unread', NotificationFilter.unread, _unreadCount),
          CivicFixSpacing.hSpaceSm,
          _buildFilterChip(l10n?.filterRead ?? 'Read', NotificationFilter.read, _allNotifications.length - _unreadCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationFilter filter, int count) {
    final isSelected = _selectedFilter == filter;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: CivicFixColors.primary,
      backgroundColor: Colors.white,
      labelStyle: CivicFixTypography.captionMedium.copyWith(
        color: isSelected ? Colors.white : CivicFixColors.primaryText,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: CivicFixRadius.chipRadius,
        side: BorderSide(
          color: isSelected ? CivicFixColors.primary : CivicFixColors.border,
        ),
      ),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }

  Widget _buildBody() {
    final l10n = context.l10nOrNull;
    if (_isLoading) {
      return const NotificationSkeleton(itemCount: 5);
    }

    if (_errorMessage != null) {
      return Center(
        child: ErrorState(
          title: l10n?.couldNotLoadNotifications ?? "Couldn't load notifications.",
          message: l10n?.checkConnectionAndRetry ?? 'Please check your connection and try again.',
          onRetry: _loadNotifications,
        ),
      );
    }

    final items = _filteredNotifications;

    if (items.isEmpty) {
      if (_selectedFilter == NotificationFilter.unread) {
        return EmptyState(
          icon: Icons.mark_chat_read_outlined,
          title: l10n?.noUnreadNotifications ?? 'No unread notifications',
          description: l10n?.noUnreadNotificationsDesc ?? 'You have read all updates on your complaints and ward notices.',
        );
      }
      return EmptyState(
        icon: Icons.notifications_none_rounded,
        title: l10n?.noNotificationsYet ?? 'No notifications yet.',
        description: l10n?.noNotificationsYetDesc ?? 'When there is an update to one of your complaints, it will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: CivicFixColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => CivicFixSpacing.vSpaceMd,
        itemBuilder: (context, index) {
          final item = items[index];
          return NotificationCard(
            notification: item,
            notificationRepository: _notificationRepository,
            complaintRepository: _complaintRepository,
            onReadChanged: _loadNotifications,
          );
        },
      ),
    );
  }
}

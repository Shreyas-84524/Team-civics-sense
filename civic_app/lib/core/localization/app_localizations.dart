import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../map/basemap_mode.dart';
import '../models/complaint_model.dart';
import '../models/government_role.dart';
import '../models/notification_model.dart';
import 'mappers/canonical_display_mappers.dart';

export '../../l10n/generated/app_localizations.dart';
export 'mappers/canonical_display_mappers.dart';
export 'models/app_locale.dart';
export 'widgets/language_selector_widget.dart';
export 'widgets/civic_fix_translated_text.dart';
export 'translation/cache/memory_translation_cache.dart';
export 'translation/cache/persistent_translation_cache.dart';
export 'translation/cache/two_level_translation_cache.dart';
export 'translation/cache/translation_cache.dart';
export 'translation/models/translatable_content.dart';
export 'translation/models/translation_request.dart';
export 'translation/models/translation_result.dart';
export 'translation/repositories/translation_repository.dart';
export 'translation/services/no_op_translation_service.dart';
export 'translation/services/remote_translation_service.dart';
export 'translation/services/translation_service.dart';
export 'translation/utils/language_detector.dart';
export 'translation/constants/translation_constants.dart';
export 'translation/history/historical_language_resolver.dart';
export 'translation/history/historical_migration_utility.dart';
export 'notifications/notification_language_templates.dart';
export 'tts/tts_language_config.dart';

/// Extension providing fast and idiomatic access to [AppLocalizations] from [BuildContext].
extension LocalizedBuildContext on BuildContext {
  /// Returns the nearest [AppLocalizations] instance.
  /// Throws an assertion error in debug mode if localizations are not configured in the widget tree.
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(
      localizations != null,
      'No AppLocalizations found in BuildContext. Ensure MaterialApp includes localizationsDelegates.',
    );
    return localizations!;
  }

  /// Returns the nearest [AppLocalizations] instance or null if not available.
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}

/// Extension providing localized label for [ComplaintStatus].
extension LocalizedComplaintStatus on ComplaintStatus {
  String localizedLabel(BuildContext context) {
    return localizedComplaintStatus(this, context: context);
  }
}

/// Extension providing localized label for [ComplaintPriority].
extension LocalizedComplaintPriority on ComplaintPriority {
  String localizedLabel(BuildContext context) {
    return localizedComplaintPriority(this, context: context);
  }
}

/// Extension providing localized label for [GovernmentRole].
extension LocalizedGovernmentRole on GovernmentRole {
  String localizedLabel(BuildContext context) {
    return localizedGovernmentRole(this, context: context);
  }
}

/// Extension providing localized label for [SyncStatus].
extension LocalizedSyncStatus on SyncStatus {
  String localizedLabel(BuildContext context) {
    return localizedSyncStatus(this, context: context);
  }
}

/// Extension providing localized label for [BasemapMode].
extension LocalizedBasemapMode on BasemapMode {
  String localizedLabel(BuildContext context) {
    return localizedBasemapMode(this, context: context);
  }

  String localizedDescription(BuildContext context) {
    return localizedBasemapModeDescription(this, context: context);
  }
}

/// Extension providing localized label for [NotificationType].
extension LocalizedNotificationType on NotificationType {
  String localizedLabel(BuildContext context) {
    return localizedNotificationType(this, context: context);
  }
}

/// Extension providing localized label for [ComplaintRoutingStatus].
extension LocalizedComplaintRoutingStatus on ComplaintRoutingStatus {
  String localizedLabel(BuildContext context) {
    return localizedRoutingStatus(this, context: context);
  }
}

/// Extension providing localized label for [ComplaintAssignmentStatus].
extension LocalizedComplaintAssignmentStatus on ComplaintAssignmentStatus {
  String localizedLabel(BuildContext context) {
    return localizedAssignmentStatus(this, context: context);
  }
}


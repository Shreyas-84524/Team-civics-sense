import '../models/sync_queue_item.dart';

/// Result object returned from executing a sync provider operation.
class SyncResult {
  final bool isSuccess;
  final String? serverId;
  final String? errorMessage;
  final bool isPartialFailure;
  final List<String> uploadedImageUrls;
  final List<String> failedImageUrls;
  final Map<String, dynamic>? responseData;

  const SyncResult({
    required this.isSuccess,
    this.serverId,
    this.errorMessage,
    this.isPartialFailure = false,
    this.uploadedImageUrls = const [],
    this.failedImageUrls = const [],
    this.responseData,
  });

  factory SyncResult.success({
    String? serverId,
    List<String> uploadedImageUrls = const [],
    Map<String, dynamic>? responseData,
  }) {
    return SyncResult(
      isSuccess: true,
      serverId: serverId,
      uploadedImageUrls: uploadedImageUrls,
      responseData: responseData,
    );
  }

  factory SyncResult.failure(
    String errorMessage, {
    bool isPartialFailure = false,
    List<String> uploadedImageUrls = const [],
    List<String> failedImageUrls = const [],
  }) {
    return SyncResult(
      isSuccess: false,
      errorMessage: errorMessage,
      isPartialFailure: isPartialFailure,
      uploadedImageUrls: uploadedImageUrls,
      failedImageUrls: failedImageUrls,
    );
  }

  factory SyncResult.partial({
    required String serverId,
    required List<String> uploadedImageUrls,
    required List<String> failedImageUrls,
    String? errorMessage,
  }) {
    return SyncResult(
      isSuccess: true, // Complaint created on backend
      serverId: serverId,
      isPartialFailure: true, // Evidence upload needs retry
      uploadedImageUrls: uploadedImageUrls,
      failedImageUrls: failedImageUrls,
      errorMessage: errorMessage ?? 'Complaint synced but some evidence images failed to upload',
    );
  }
}

/// Abstract contract for executing remote backend synchronization.
///
/// In this phase, [MockSyncProvider] provides mock/simulated cloud synchronization.
/// In future prompts, this will be implemented by FirebaseSyncProvider.
abstract class SyncProvider {
  /// Execute the synchronization task for the given [item].
  Future<SyncResult> execute(SyncQueueItem item);
}

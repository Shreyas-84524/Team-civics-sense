import 'dart:async';
import '../models/sync_queue_item.dart';
import 'sync_provider.dart';

/// Mock synchronization provider simulating remote backend operations.
/// 
/// Allows testing realistic network scenarios, partial failures, latency, and success flows.
class MockSyncProvider implements SyncProvider {
  bool simulateNetworkFailure;
  bool simulatePartialUploadFailure;
  int simulatedDelayMs;

  MockSyncProvider({
    this.simulateNetworkFailure = false,
    this.simulatePartialUploadFailure = false,
    this.simulatedDelayMs = 0,
  });

  @override
  Future<SyncResult> execute(SyncQueueItem item) async {
    if (simulatedDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: simulatedDelayMs));
    }

    if (simulateNetworkFailure) {
      return SyncResult.failure('Simulated network timeout connecting to CivicFix cloud backend');
    }

    switch (item.operation) {
      case SyncOperation.createComplaint:
        return _handleCreateComplaint(item);

      case SyncOperation.updateComplaint:
        return SyncResult.success(
          serverId: item.payload['serverId'] as String? ?? 'srv_${item.entityId}',
          responseData: {'status': 'updated', 'entityId': item.entityId},
        );

      case SyncOperation.upvoteComplaint:
        return SyncResult.success(
          serverId: item.entityId,
          responseData: {'upvoted': true, 'complaintId': item.entityId},
        );

      case SyncOperation.uploadEvidence:
        return _handleUploadEvidence(item);

      case SyncOperation.deleteComplaint:
        return SyncResult.success(
          serverId: item.entityId,
          responseData: {'deleted': true, 'complaintId': item.entityId},
        );
    }
  }

  SyncResult _handleCreateComplaint(SyncQueueItem item) {
    final serverId = 'srv_cmp_${DateTime.now().millisecondsSinceEpoch}';
    final rawImages = item.payload['imageUrls'] as List<dynamic>? ?? [];
    final List<String> imageUrls = rawImages.map((e) => e.toString()).toList();

    // Check partial upload failure simulation
    if (simulatePartialUploadFailure && imageUrls.isNotEmpty) {
      final uploaded = imageUrls.length > 1 ? [imageUrls.first] : <String>[];
      final failed = imageUrls.length > 1 ? imageUrls.sublist(1) : imageUrls;
      return SyncResult.partial(
        serverId: serverId,
        uploadedImageUrls: uploaded,
        failedImageUrls: failed,
        errorMessage: 'Complaint created, but ${failed.length} image(s) failed to upload',
      );
    }

    return SyncResult.success(
      serverId: serverId,
      uploadedImageUrls: imageUrls,
      responseData: {
        'serverId': serverId,
        'localId': item.entityId,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  SyncResult _handleUploadEvidence(SyncQueueItem item) {
    final rawImages = item.payload['imageUrls'] as List<dynamic>? ?? [];
    final List<String> imageUrls = rawImages.map((e) => e.toString()).toList();

    if (simulatePartialUploadFailure && imageUrls.length > 1) {
      final uploaded = [imageUrls.first];
      final failed = imageUrls.sublist(1);
      return SyncResult.failure(
        'Partial evidence upload failure',
        isPartialFailure: true,
        uploadedImageUrls: uploaded,
        failedImageUrls: failed,
      );
    }

    return SyncResult.success(
      uploadedImageUrls: imageUrls,
      responseData: {'uploadedCount': imageUrls.length},
    );
  }
}

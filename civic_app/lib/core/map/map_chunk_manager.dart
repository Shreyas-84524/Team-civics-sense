import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import '../repositories/hazard_repository.dart';
import 'spatial_chunk.dart';

/// Manages progressive viewport-driven spatial chunk loading, in-memory caching,
/// request generation tokens (race condition prevention), and camera debounce.
class MapChunkManager extends ChangeNotifier {
  final Set<String> _loadedChunkIds = {};
  final Set<String> _pendingChunkIds = {};
  final Map<String, List<HazardModel>> _chunkData = {};

  int _currentGeneration = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get loadedChunkIds => Set.unmodifiable(_loadedChunkIds);
  int get loadedChunkCount => _loadedChunkIds.length;

  /// Returns all currently cached hazards deduplicated across all loaded chunks.
  List<HazardModel> get allCachedHazards {
    final Map<String, HazardModel> dedup = {};
    for (final list in _chunkData.values) {
      for (final h in list) {
        dedup[h.id] = h;
      }
    }
    return dedup.values.toList();
  }

  /// Calculates required chunks for [bounds] with a surrounding prefetch margin buffer.
  List<String> getRequiredChunksForBounds(
    LatLngBounds bounds, {
    double bufferRatio = 0.25,
  }) {
    return GeohashUtils.getChunksForBounds(
      minLat: bounds.southwest.latitude,
      minLng: bounds.southwest.longitude,
      maxLat: bounds.northeast.latitude,
      maxLng: bounds.northeast.longitude,
      bufferRatio: bufferRatio,
    );
  }

  /// Triggered on camera idle or programmatic bounds change.
  ///
  /// Uses [debounce] to avoid querying during rapid user drags.
  /// Deduplicates requests and reuses already-loaded chunks from memory.
  Future<void> onCameraIdle({
    required LatLngBounds bounds,
    required HazardRepository repository,
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
    Duration debounce = const Duration(milliseconds: 250),
    double bufferRatio = 0.25,
  }) {
    final completer = Completer<void>();
    _debounceTimer?.cancel();

    if (debounce == Duration.zero) {
      _executeLoad(
        bounds: bounds,
        repository: repository,
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
        bufferRatio: bufferRatio,
      ).then(completer.complete).catchError(completer.completeError);
      return completer.future;
    }

    _debounceTimer = Timer(debounce, () {
      _executeLoad(
        bounds: bounds,
        repository: repository,
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
        bufferRatio: bufferRatio,
      ).then(completer.complete).catchError(completer.completeError);
    });

    return completer.future;
  }

  Future<void> _executeLoad({
    required LatLngBounds bounds,
    required HazardRepository repository,
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
    double bufferRatio = 0.25,
  }) async {
    final requiredChunks = getRequiredChunksForBounds(bounds, bufferRatio: bufferRatio);
    final missingChunks = requiredChunks
        .where((c) => !_loadedChunkIds.contains(c) && !_pendingChunkIds.contains(c))
        .toList();

    // If all required chunks are already cached in memory, no network read needed!
    if (missingChunks.isEmpty) {
      notifyListeners();
      return;
    }

    _pendingChunkIds.addAll(missingChunks);
    _currentGeneration++;
    final requestGen = _currentGeneration;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await repository.getHazardsInChunks(
        chunkIds: missingChunks,
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
      );

      // Discard stale responses if camera moved and a newer request superseded this one
      if (requestGen != _currentGeneration) {
        _pendingChunkIds.removeAll(missingChunks);
        return;
      }

      // Partition fetched items into chunk data buckets
      for (final chunkId in missingChunks) {
        _chunkData[chunkId] = [];
      }
      for (final h in fetched) {
        final chunkId = h.computedSpatialChunkId;
        _chunkData.putIfAbsent(chunkId, () => []).add(h);
      }

      _loadedChunkIds.addAll(missingChunks);
      _pendingChunkIds.removeAll(missingChunks);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (requestGen == _currentGeneration) {
        _pendingChunkIds.removeAll(missingChunks);
        _isLoading = false;
        _errorMessage = "Couldn't load civic issues.";
        notifyListeners();
      }
    }
  }

  /// Live update of an individual hazard (e.g. status transition) in the cached chunks.
  void updateHazard(HazardModel updated) {
    bool found = false;
    for (final entry in _chunkData.entries) {
      final list = entry.value;
      final idx = list.indexWhere((h) =>
          h.id == updated.id ||
          (h.complaintId != null && h.complaintId == updated.complaintId) ||
          (h.ticketNumber != null && h.ticketNumber == updated.ticketNumber));
      if (idx != -1) {
        list[idx] = updated;
        found = true;
      }
    }
    if (!found) {
      final chunkId = updated.computedSpatialChunkId;
      _chunkData.putIfAbsent(chunkId, () => []).add(updated);
    }
    notifyListeners();
  }

  /// Pre-populates the cache with known initial hazards (e.g. for offline or testing).
  void seedInitialHazards(List<HazardModel> hazards) {
    for (final h in hazards) {
      final chunkId = h.computedSpatialChunkId;
      _chunkData.putIfAbsent(chunkId, () => []).add(h);
      _loadedChunkIds.add(chunkId);
    }
    notifyListeners();
  }

  /// Clears in-memory chunk cache forcing fresh loads on next camera move.
  void clearCache() {
    _debounceTimer?.cancel();
    _loadedChunkIds.clear();
    _pendingChunkIds.clear();
    _chunkData.clear();
    _currentGeneration++;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

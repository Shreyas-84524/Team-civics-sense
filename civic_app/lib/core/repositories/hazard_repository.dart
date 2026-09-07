import '../local/mock_data_source.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';

/// Abstract repository interface for Civic Hazard Map data.
abstract class HazardRepository {
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  });

  Future<HazardModel?> getHazardById(String id);

  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });
}

/// In-memory mock implementation of [HazardRepository] for User UI development.
class MockHazardRepository implements HazardRepository {
  static final MockHazardRepository _instance = MockHazardRepository._internal();
  factory MockHazardRepository() => _instance;
  MockHazardRepository._internal();

  final MockDataSource _dataSource = MockDataSource();

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    // Simulate brief asynchronous delay (100ms)
    await Future.delayed(const Duration(milliseconds: 100));

    var results = List<HazardModel>.from(_dataSource.hazards);

    // 1. Filter by Category
    if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
      results = results.where((h) {
        return h.category.id.toLowerCase() == categoryId.toLowerCase() ||
            h.category.name.toLowerCase() == categoryId.toLowerCase();
      }).toList();
    }

    // 2. Filter by Status
    if (status != null) {
      results = results.where((h) => h.status == status).toList();
    }

    // 3. Filter by Severity
    if (severity != null) {
      results = results.where((h) => h.severity == severity).toList();
    }

    // 3. Search query filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      results = results.where((h) {
        final matchesTitle = h.title.toLowerCase().contains(query);
        final matchesTicket = (h.ticketNumber ?? '').toLowerCase().contains(query);
        final matchesCategory = h.category.name.toLowerCase().contains(query);
        final matchesAddress = h.address.toLowerCase().contains(query);
        final matchesLandmark = (h.landmark ?? '').toLowerCase().contains(query);
        final matchesWard = (h.ward ?? '').toLowerCase().contains(query);

        return matchesTitle || matchesTicket || matchesCategory || matchesAddress || matchesLandmark || matchesWard;
      }).toList();
    }

    return results;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _dataSource.hazards.firstWhere((h) => h.id == id || h.complaintId == id || h.ticketNumber == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // For mock UI, return active hazards in ward
    return _dataSource.hazards.where((h) => h.status != ComplaintStatus.resolved).toList();
  }
}

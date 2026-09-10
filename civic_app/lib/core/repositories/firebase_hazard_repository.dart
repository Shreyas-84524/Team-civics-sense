import '../firebase/firestore/firebase_hazard_data_source.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'hazard_repository.dart';

/// Firebase Firestore remote implementation of [HazardRepository].
class FirebaseHazardRepository implements HazardRepository {
  final FirebaseHazardDataSource _dataSource;

  FirebaseHazardRepository({FirebaseHazardDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseHazardDataSource();

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    final page = await _dataSource.getHazards(
      categoryId: categoryId,
      status: status,
      severity: severity,
      limit: 100,
    );

    var results = page.items;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      results = results.where((h) {
        return h.title.toLowerCase().contains(query) ||
            (h.ticketNumber ?? '').toLowerCase().contains(query) ||
            h.category.name.toLowerCase().contains(query) ||
            h.address.toLowerCase().contains(query);
      }).toList();
    }

    return results;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    return _dataSource.getHazardById(id);
  }

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final page = await _dataSource.getHazards(limit: 100);
    return page.items.where((h) => h.status != ComplaintStatus.resolved).toList();
  }

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) {
    return _dataSource
        .watchHazards(
          categoryId: categoryId,
          status: status,
          severity: severity,
          limit: 100,
        )
        .map((items) {
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        return items.where((h) {
          return h.title.toLowerCase().contains(query) ||
              (h.ticketNumber ?? '').toLowerCase().contains(query) ||
              h.category.name.toLowerCase() == query ||
              h.address.toLowerCase().contains(query);
        }).toList();
      }
      return items;
    });
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) {
    return _dataSource.watchHazards(limit: 50).map((list) {
      try {
        return list.firstWhere((h) => h.id == id || h.complaintId == id || h.ticketNumber == id);
      } catch (_) {
        return null;
      }
    });
  }
}


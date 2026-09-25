import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'spatial_feature.dart';

/// Preset time-based filtering ranges for spatial and heatmap queries.
enum SpatialTimeFilter {
  allTime,
  last24Hours,
  last7Days,
  last30Days,
}

extension SpatialTimeFilterExt on SpatialTimeFilter {
  String get label {
    switch (this) {
      case SpatialTimeFilter.allTime:
        return 'All Time';
      case SpatialTimeFilter.last24Hours:
        return 'Last 24 Hours';
      case SpatialTimeFilter.last7Days:
        return 'Last 7 Days';
      case SpatialTimeFilter.last30Days:
        return 'Last 30 Days';
    }
  }

  Duration? get duration {
    switch (this) {
      case SpatialTimeFilter.allTime:
        return null;
      case SpatialTimeFilter.last24Hours:
        return const Duration(hours: 24);
      case SpatialTimeFilter.last7Days:
        return const Duration(days: 7);
      case SpatialTimeFilter.last30Days:
        return const Duration(days: 30);
    }
  }

  bool isWithin(DateTime createdAt, {DateTime? referenceTime}) {
    final dur = duration;
    if (dur == null) return true;
    final nowUtc = (referenceTime ?? DateTime.now()).toUtc();
    final createdUtc = createdAt.toUtc();
    final cutoff = nowUtc.subtract(dur);
    return createdUtc.isAfter(cutoff) || createdUtc.isAtSameMomentAs(cutoff);
  }
}

/// Single source of truth for converting CivicFix domain models (complaints and hazards)
/// into map-ready GeoJSON feature collections with filtering and spatial validation.
class SpatialDataService {
  const SpatialDataService();

  /// Extracts validated, map-ready [SpatialFeature] items from a list of [ComplaintModel]s with optional filtering.
  List<SpatialFeature> extractComplaintFeatures(
    List<ComplaintModel> complaints, {
    String? categoryId,
    ComplaintStatus? status,
    String? department,
    String? ward,
    SpatialTimeFilter? timeFilter,
    DateTime? referenceTime,
    String? searchQuery,
  }) {
    var list = complaints;

    if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
      final q = categoryId.toLowerCase();
      list = list.where((c) {
        final catId = c.category.id.toLowerCase();
        final catName = c.category.name.toLowerCase();
        return catId == q || catName == q || catId.contains(q) || q.contains(catId) || catName.contains(q);
      }).toList();
    }

    if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }

    if (department != null && department.isNotEmpty && department.toLowerCase() != 'all') {
      final d = department.toLowerCase();
      list = list.where((c) => c.effectiveDepartment.toLowerCase().contains(d)).toList();
    }

    if (ward != null && ward.isNotEmpty && ward.toLowerCase() != 'all') {
      final w = ward.toLowerCase();
      list = list.where((c) => (c.location.ward ?? '').toLowerCase().contains(w)).toList();
    }

    if (timeFilter != null && timeFilter != SpatialTimeFilter.allTime) {
      list = list.where((c) => timeFilter.isWithin(c.createdAt, referenceTime: referenceTime)).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((c) {
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesTicket = c.ticketNumber.toLowerCase().contains(q);
        final matchesCat = c.category.name.toLowerCase().contains(q);
        final matchesAddr = c.location.address.toLowerCase().contains(q);
        final matchesLandmark = (c.location.landmark ?? '').toLowerCase().contains(q);
        final matchesWard = (c.location.ward ?? '').toLowerCase().contains(q);
        return matchesTitle || matchesTicket || matchesCat || matchesAddr || matchesLandmark || matchesWard;
      }).toList();
    }

    final List<SpatialFeature> features = [];
    for (final complaint in list) {
      final feature = SpatialFeature.fromComplaint(complaint);
      if (feature != null) {
        features.add(feature);
      }
    }

    return features;
  }

  /// Extracts validated, map-ready [SpatialFeature] items from a list of [HazardModel]s with optional filtering.
  List<SpatialFeature> extractHazardFeatures(
    List<HazardModel> hazards, {
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? ward,
    SpatialTimeFilter? timeFilter,
    DateTime? referenceTime,
    String? searchQuery,
  }) {
    var list = hazards;

    if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
      final q = categoryId.toLowerCase();
      list = list.where((h) {
        final catId = h.category.id.toLowerCase();
        final catName = h.category.name.toLowerCase();
        return catId == q || catName == q || catId.contains(q) || q.contains(catId) || catName.contains(q);
      }).toList();
    }

    if (status != null) {
      list = list.where((h) => h.status == status).toList();
    }

    if (severity != null) {
      list = list.where((h) => h.severity == severity).toList();
    }

    if (ward != null && ward.isNotEmpty && ward.toLowerCase() != 'all') {
      final w = ward.toLowerCase();
      list = list.where((h) => (h.ward ?? '').toLowerCase().contains(w)).toList();
    }

    if (timeFilter != null && timeFilter != SpatialTimeFilter.allTime) {
      list = list.where((h) => timeFilter.isWithin(h.createdAt, referenceTime: referenceTime)).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((h) {
        final matchesTitle = h.title.toLowerCase().contains(q);
        final matchesTicket = (h.ticketNumber ?? '').toLowerCase().contains(q);
        final matchesCat = h.category.name.toLowerCase().contains(q);
        final matchesAddr = h.address.toLowerCase().contains(q);
        final matchesLandmark = (h.landmark ?? '').toLowerCase().contains(q);
        final matchesWard = (h.ward ?? '').toLowerCase().contains(q);
        return matchesTitle || matchesTicket || matchesCat || matchesAddr || matchesLandmark || matchesWard;
      }).toList();
    }

    final List<SpatialFeature> features = [];
    for (final hazard in list) {
      final feature = SpatialFeature.fromHazard(hazard);
      if (feature != null) {
        features.add(feature);
      }
    }

    return features;
  }

  /// Builds a complete GeoJSON FeatureCollection dictionary containing both complaints and hazards.
  Map<String, dynamic> buildFeatureCollection({
    List<ComplaintModel>? complaints,
    List<HazardModel>? hazards,
    String? categoryId,
    ComplaintStatus? status,
    String? department,
    String? ward,
    HazardSeverity? severity,
    SpatialTimeFilter? timeFilter,
    DateTime? referenceTime,
    String? searchQuery,
  }) {
    final List<SpatialFeature> allFeatures = [];

    if (complaints != null && complaints.isNotEmpty) {
      allFeatures.addAll(extractComplaintFeatures(
        complaints,
        categoryId: categoryId,
        status: status,
        department: department,
        ward: ward,
        timeFilter: timeFilter,
        referenceTime: referenceTime,
        searchQuery: searchQuery,
      ));
    }

    if (hazards != null && hazards.isNotEmpty) {
      allFeatures.addAll(extractHazardFeatures(
        hazards,
        categoryId: categoryId,
        status: status,
        severity: severity,
        ward: ward,
        timeFilter: timeFilter,
        referenceTime: referenceTime,
        searchQuery: searchQuery,
      ));
    }

    return SpatialFeature.toFeatureCollection(allFeatures);
  }

  /// Returns an empty GeoJSON FeatureCollection.
  static Map<String, dynamic> createEmptyFeatureCollection() {
    return {
      'type': 'FeatureCollection',
      'features': <Map<String, dynamic>>[],
    };
  }
}


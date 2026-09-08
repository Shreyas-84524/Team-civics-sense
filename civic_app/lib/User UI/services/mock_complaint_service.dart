import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/local/mock_data_source.dart';
import '../../core/location/location_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hive_complaint_repository.dart';
import '../models/complaint_draft.dart';

/// Abstract contract for civic complaint operations.
abstract class ComplaintService {
  Future<ComplaintModel> submitComplaint(
    ComplaintDraft draft, {
    bool simulateError = false,
  });

  Future<List<ComplaintModel>> getComplaints();

  Future<ComplaintModel?> getComplaintById(String id);
}

/// In-memory & Hive-backed Mock Complaint Service for Citizen UI with offline draft capability.
class MockComplaintService implements ComplaintService {
  static final MockComplaintService _instance = MockComplaintService._internal();
  factory MockComplaintService({
    ConnectivityService? connectivityService,
    ComplaintRepository? repository,
  }) {
    if (connectivityService != null) {
      _instance._connectivityService = connectivityService;
    }
    if (repository != null) {
      _instance._repository = repository;
    }
    return _instance;
  }

  MockComplaintService._internal()
      : _connectivityService = AppConnectivityService(),
        _repository = HiveComplaintRepository();

  ConnectivityService _connectivityService;
  ComplaintRepository _repository;
  final MockDataSource _dataSource = MockDataSource();
  int _ticketCounter = 24;

  /// Update the connectivity service (useful for test mocks or overrides)
  void setConnectivityService(ConnectivityService service) {
    _connectivityService = service;
  }

  /// Update repository implementation
  void setRepository(ComplaintRepository repository) {
    _repository = repository;
  }

  @override
  Future<ComplaintModel> submitComplaint(
    ComplaintDraft draft, {
    bool simulateError = false,
  }) async {
    // Simulate brief network latency (400ms) unless in test environment
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (simulateError) {
      throw Exception('Unable to submit your issue. Please try again.');
    }

    if (!draft.isComplete) {
      throw Exception('Please fill in all required fields before submitting.');
    }

    _ticketCounter++;
    final formattedCounter = _ticketCounter.toString().padLeft(6, '0');
    final isOnline = _connectivityService.isOnline;

    final category = draft.category ?? CivicCategory.defaultCategories.first;
    final location = draft.location ??
        const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, 2nd Main Road',
          ward: 'Ward 14 (Central)',
          city: 'Bengaluru',
        );

    if (!isOnline) {
      // OFFLINE PATH: Assign temporary local identifier & pending sync status
      final localRef = 'LOCAL-2026-$formattedCounter';
      final complaintId = 'cmp_local_${DateTime.now().microsecondsSinceEpoch}_$formattedCounter';

      final offlineComplaint = ComplaintModel(
        id: complaintId,
        citizenId: _dataSource.currentUser.id,
        ticketNumber: localRef,
        localId: localRef,
        title: draft.title.trim(),
        description: draft.description.trim(),
        category: category,
        status: ComplaintStatus.reported,
        priority: draft.isHazard ? ComplaintPriority.high : ComplaintPriority.medium,
        location: location,
        imageUrls: List.unmodifiable(draft.imageUrls),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isHazard: draft.isHazard,
        upvotes: 1,
        syncStatus: SyncStatus.pending,
        timeline: [
          TimelineEvent(
            title: 'Saved Locally',
            description: 'Complaint saved offline. Waiting for connection to submit to ${draft.departmentName}.',
            timestamp: DateTime.now(),
            status: ComplaintStatus.reported,
          ),
        ],
      );

      // Persist persistently in Hive complaints box & pending_sync box
      return await _repository.saveOfflineComplaint(offlineComplaint);
    }

    // ONLINE PATH: Normal server ticket generation & synced status
    final ticketNumber = 'CF-2026-$formattedCounter';
    final complaintId = 'cmp_cf_${DateTime.now().microsecondsSinceEpoch}_$formattedCounter';

    final onlineComplaint = ComplaintModel(
      id: complaintId,
      citizenId: _dataSource.currentUser.id,
      ticketNumber: ticketNumber,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: category,
      status: ComplaintStatus.reported,
      priority: draft.isHazard ? ComplaintPriority.high : ComplaintPriority.medium,
      location: location,
      imageUrls: List.unmodifiable(draft.imageUrls),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: draft.isHazard,
      upvotes: 1,
      syncStatus: SyncStatus.synced,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Grievance submitted by citizen and routed to ${draft.departmentName}.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.reported,
        ),
      ],
    );

    // Insert at front of in-memory complaints list
    _dataSource.complaints.insert(0, onlineComplaint);

    // Increment user contribution metrics
    _dataSource.currentUser = _dataSource.currentUser.copyWith(
      reportsSubmitted: _dataSource.currentUser.reportsSubmitted + 1,
      civicPoints: _dataSource.currentUser.civicPoints + 20,
    );

    return onlineComplaint;
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    return await _repository.getComplaints();
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    return await _repository.getComplaintById(id);
  }
}

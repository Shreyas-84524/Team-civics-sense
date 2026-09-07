import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/local/mock_data_source.dart';
import '../../core/location/location_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
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

/// In-memory Mock Complaint Service for Phase 1 Citizen UI.
class MockComplaintService implements ComplaintService {
  static final MockComplaintService _instance = MockComplaintService._internal();
  factory MockComplaintService() => _instance;
  MockComplaintService._internal();

  final MockDataSource _dataSource = MockDataSource();
  int _ticketCounter = 24;

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
    final ticketNumber = 'CF-2026-$formattedCounter';
    final complaintId = 'cmp_cf_${DateTime.now().millisecondsSinceEpoch}';

    final category = draft.category ?? CivicCategory.defaultCategories.first;
    final location = draft.location ??
        const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, 2nd Main Road',
          ward: 'Ward 14 (Central)',
          city: 'Bengaluru',
        );

    final newComplaint = ComplaintModel(
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
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Grievance submitted by citizen and routed to ${draft.departmentName}.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.reported,
        ),
      ],
    );

    // Insert at front of complaints list
    _dataSource.complaints.insert(0, newComplaint);

    // Increment user contribution metrics
    _dataSource.currentUser = _dataSource.currentUser.copyWith(
      reportsSubmitted: _dataSource.currentUser.reportsSubmitted + 1,
      civicPoints: _dataSource.currentUser.civicPoints + 20,
    );

    return newComplaint;
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    return List.unmodifiable(_dataSource.complaints);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      return _dataSource.complaints.firstWhere((c) => c.id == id || c.ticketNumber == id);
    } catch (_) {
      return null;
    }
  }
}

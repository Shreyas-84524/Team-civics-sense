import '../local/mock_data_source.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';

abstract class ComplaintRepository {
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId);
  Future<List<ComplaintModel>> getComplaints();
  Future<ComplaintModel?> getComplaintById(String id);
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId);
  Future<ComplaintModel> createComplaint({
    required String citizenId,
    required String title,
    required String description,
    required CivicCategory category,
    required CivicLocation location,
    required ComplaintPriority priority,
    List<String> imageUrls = const [],
    bool isHazard = false,
  });
  Future<void> upvoteComplaint(String id);
  Future<List<ComplaintModel>> getNearbyHazards();
}

class MockComplaintRepository implements ComplaintRepository {
  static final MockComplaintRepository _instance = MockComplaintRepository._internal();
  factory MockComplaintRepository() => _instance;
  MockComplaintRepository._internal();

  final MockDataSource _dataSource = MockDataSource();
  int _ticketCounter = 24;

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async {
    // In-memory instant return filtered by citizen ID (or matching current user)
    return List.unmodifiable(
      _dataSource.complaints.where((c) {
        if (citizenId.isEmpty) return true;
        return c.citizenId == citizenId || c.citizenId == 'user_citizen_001' || c.citizenId == 'user_001';
      }).toList(),
    );
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    return List.unmodifiable(_dataSource.complaints);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      return _dataSource.complaints.firstWhere(
        (c) => c.id == id || c.ticketNumber == id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async {
    try {
      return _dataSource.complaints.firstWhere(
        (c) => c.ticketNumber.toLowerCase() == ticketId.toLowerCase() || c.id == ticketId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ComplaintModel> createComplaint({
    required String citizenId,
    required String title,
    required String description,
    required CivicCategory category,
    required CivicLocation location,
    required ComplaintPriority priority,
    List<String> imageUrls = const [],
    bool isHazard = false,
  }) async {
    _ticketCounter++;
    final formattedCounter = _ticketCounter.toString().padLeft(6, '0');
    final ticketNum = 'CF-2026-$formattedCounter';
    final newId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
    
    final newComplaint = ComplaintModel(
      id: newId,
      citizenId: citizenId,
      ticketNumber: ticketNum,
      title: title,
      description: description,
      category: category,
      status: ComplaintStatus.reported,
      priority: priority,
      location: location,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: isHazard,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Ticket created and assigned to Ward ${location.ward ?? "Central"}.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.reported,
        ),
      ],
    );

    _dataSource.complaints.insert(0, newComplaint);
    
    // If flagged as hazard, sync into hazards collection
    if (isHazard) {
      _dataSource.hazards.insert(
        0,
        HazardModel(
          id: 'haz_${newComplaint.id}',
          complaintId: newComplaint.id,
          ticketNumber: newComplaint.ticketNumber,
          title: newComplaint.title,
          category: newComplaint.category,
          status: newComplaint.status,
          latitude: newComplaint.location.latitude,
          longitude: newComplaint.location.longitude,
          address: newComplaint.location.address,
          landmark: newComplaint.location.landmark,
          ward: newComplaint.location.ward,
          severity: newComplaint.priority == ComplaintPriority.emergency
              ? HazardSeverity.critical
              : newComplaint.priority == ComplaintPriority.high
                  ? HazardSeverity.high
                  : HazardSeverity.medium,
          imageUrl: newComplaint.imageUrls.isNotEmpty ? newComplaint.imageUrls.first : null,
          createdAt: newComplaint.createdAt,
          updatedAt: newComplaint.updatedAt,
        ),
      );
    }
    
    // Update user stats
    final updatedUser = _dataSource.currentUser.copyWith(
      reportsSubmitted: _dataSource.currentUser.reportsSubmitted + 1,
      civicPoints: _dataSource.currentUser.civicPoints + 20,
    );
    _dataSource.currentUser = updatedUser;

    return newComplaint;
  }

  @override
  Future<void> upvoteComplaint(String id) async {
    final index = _dataSource.complaints.indexWhere((c) => c.id == id || c.ticketNumber == id);
    if (index != -1) {
      final current = _dataSource.complaints[index];
      _dataSource.complaints[index] = current.copyWith(upvotes: current.upvotes + 1);
    }
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async {
    return _dataSource.complaints.where((c) => c.isHazard || c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high).toList();
  }
}

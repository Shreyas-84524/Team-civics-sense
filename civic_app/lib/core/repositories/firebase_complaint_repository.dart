import '../ai/models/ai_analysis_status.dart';
import '../ai/models/ai_authenticity_result.dart';
import '../firebase/firestore/firebase_complaint_data_source.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import 'complaint_repository.dart';

/// Firebase Firestore remote implementation of [ComplaintRepository].
class FirebaseComplaintRepository implements ComplaintRepository {
  final FirebaseComplaintDataSource _dataSource;
  int _ticketCounter = 24;

  FirebaseComplaintRepository({FirebaseComplaintDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseComplaintDataSource();

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async {
    final page = await _dataSource.getCitizenComplaints(citizenId: citizenId);
    return page.items;
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    final page = await _dataSource.getGovernmentComplaints(limit: 50);
    return page.items;
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    return _dataSource.getComplaintById(id);
  }

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async {
    return _dataSource.getComplaintByTicketNumber(ticketId);
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

    final complaint = ComplaintModel(
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
      syncStatus: SyncStatus.synced,
    );

    return _dataSource.createComplaint(complaint);
  }

  @override
  Future<ComplaintModel> saveOfflineComplaint(ComplaintModel complaint) async {
    // In remote repository, delegates directly to create or update
    return _dataSource.createComplaint(complaint);
  }

  @override
  Future<List<ComplaintModel>> getPendingComplaints() async {
    // Remote data source does not hold pending sync items (handled by Hive/SyncQueue)
    return const [];
  }

  @override
  Future<void> updateSyncStatus(
    String complaintId,
    SyncStatus status, {
    String? serverId,
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus? aiAnalysisStatus,
  }) async {
    // No-op on pure remote Firestore repository
  }

  @override
  Future<void> upvoteComplaint(String id) async {
    await _dataSource.upvoteComplaint(id);
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async {
    return _dataSource.getNearbyHazards();
  }

  @override
  Stream<ComplaintModel?> watchComplaint(String id) {
    return _dataSource.watchComplaint(id);
  }

  @override
  Stream<List<TimelineEvent>> watchComplaintTimeline(String complaintId) {
    return _dataSource.watchComplaintTimeline(complaintId);
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenComplaints(String citizenId) {
    return _dataSource.watchCitizenComplaints(citizenId: citizenId);
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() {
    return _dataSource.watchGovernmentComplaints();
  }

  @override
  Stream<List<ComplaintModel>> watchNearbyHazards() {
    return _dataSource.watchNearbyHazards();
  }
}


import 'dart:async';
import '../../core/auth/auth_service_locator.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../models/complaint_draft.dart';
import 'mock_complaint_service.dart';

/// Production offline-first [ComplaintService] delegating to [ComplaintRepository].
class OfflineFirstComplaintService implements ComplaintService {
  final ComplaintRepository? _complaintRepo;

  OfflineFirstComplaintService({
    ComplaintRepository? complaintRepository,
  }) : _complaintRepo = complaintRepository;

  ComplaintRepository get _activeRepository =>
      _complaintRepo ?? RepositoryLocator.complaintRepository;

  @override
  Future<ComplaintModel> submitComplaint(
    ComplaintDraft draft, {
    bool simulateError = false,
  }) async {
    if (simulateError) {
      throw Exception('Unable to submit your issue. Please try again.');
    }

    if (!draft.isComplete) {
      throw Exception('Please fill in all required fields before submitting.');
    }

    final category = draft.category ?? CivicCategory.defaultCategories.first;
    final location = draft.location!;

    final priority = draft.isHazard ? ComplaintPriority.high : ComplaintPriority.medium;
    final citizenId = AuthServiceLocator.citizenAuth.currentUser?.id ?? 'user_citizen_001';

    return await _activeRepository.createComplaint(
      citizenId: citizenId,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: category,
      location: location,
      priority: priority,
      imageUrls: List.unmodifiable(draft.imageUrls),
      isHazard: draft.isHazard,
    );
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    return await _activeRepository.getComplaints();
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    return await _activeRepository.getComplaintById(id);
  }
}

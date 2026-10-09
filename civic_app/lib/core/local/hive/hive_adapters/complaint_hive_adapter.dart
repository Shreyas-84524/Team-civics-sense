import 'package:hive/hive.dart';
import '../../models/complaint_local_model.dart';
import '../../models/location_local_model.dart';
import '../../models/timeline_event_local_model.dart';

/// Hive TypeAdapter for [ComplaintLocalModel] (typeId: 0).
class ComplaintHiveAdapter extends TypeAdapter<ComplaintLocalModel> {
  @override
  final int typeId = 0;

  @override
  ComplaintLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComplaintLocalModel(
      id: fields[0] as String? ?? '',
      citizenId: fields[1] as String? ?? 'user_citizen_001',
      ticketNumber: fields[2] as String? ?? '',
      title: fields[3] as String? ?? '',
      description: fields[4] as String? ?? '',
      categoryId: fields[5] as String? ?? 'other',
      categoryName: fields[6] as String? ?? 'Other',
      categoryDescription: fields[7] as String? ?? '',
      status: fields[8] as String? ?? 'reported',
      priority: fields[9] as String? ?? 'medium',
      location: fields[10] as LocationLocalModel? ??
          const LocationLocalModel(latitude: 0, longitude: 0, address: ''),
      imageUrls: (fields[11] as List?)?.cast<String>() ?? const [],
      createdAtEpochMs: fields[12] as int? ?? 0,
      updatedAtEpochMs: fields[13] as int? ?? 0,
      timeline: (fields[14] as List?)?.cast<TimelineEventLocalModel>() ?? const [],
      upvotes: fields[15] as int? ?? 0,
      isHazard: fields[16] as bool? ?? false,
      officerNotes: fields[17] as String?,
      assignedTo: fields[18] as String?,
      departmentName: fields[19] as String?,
      resolvedAtEpochMs: fields[20] as int?,
      syncStatus: fields[21] as String? ?? 'synced',
      localId: fields[22] as String?,
      serverId: fields[23] as String?,
      aiAuthenticityJson: fields[24] as String?,
      aiAnalysisStatus: fields[25] as String? ?? 'pending',
      wardId: fields[26] as String?,
      assignedDepartmentId: fields[27] as String?,
      assignedDepartmentLeadId: fields[28] as String?,
      assignedCrewMemberId: fields[29] as String?,
      routingStatus: fields[30] as String?,
      assignmentStatus: fields[31] as String?,
      slaStartedAtEpochMs: fields[32] as int?,
      originalCreatedAtEpochMs: fields[33] as int?,
      currentDepartmentAssignedAtEpochMs: fields[34] as int?,
      lastReassignedAtEpochMs: fields[35] as int?,
      reassignmentCount: fields[36] as int? ?? 0,
      assignedJuniorEngineerNameSnapshot: fields[37] as String?,
      assignedJuniorEngineerDesignationSnapshot: fields[38] as String?,
      assignedFieldOfficerId: fields[39] as String?,
      assignedFieldOfficerAtEpochMs: fields[40] as int?,
      assignedFieldOfficerNameSnapshot: fields[41] as String?,
      assignedFieldOfficerDesignationSnapshot: fields[42] as String?,
      workStartedAtEpochMs: fields[43] as int?,
      workStartedBy: fields[44] as String?,
      beforeWorkPhoto: fields[45] as String?,
      beforeWorkNotes: fields[46] as String?,
      afterWorkPhoto: fields[47] as String?,
      resolutionRemarks: fields[48] as String?,
      resolvedBy: fields[49] as String?,
      blockedAtEpochMs: fields[50] as int?,
      blockedBy: fields[51] as String?,
      blockedReason: fields[52] as String?,
      reopenedAtEpochMs: fields[53] as int?,
      reopenedBy: fields[54] as String?,
      reopenReason: fields[55] as String?,
      previousResolvedAtEpochMs: fields[56] as int?,
      previousResolutionEvidence: (fields[57] as List?)?.cast<String>() ?? const [],
      reopenCount: fields[58] as int? ?? 0,
      evidenceVerificationStatus: fields[59] as String? ?? 'pending',
      departmentVerificationStatus: fields[60] as String? ?? 'pending',
      verificationStage: fields[61] as String? ?? 'evidence',
      verifiedDepartmentId: fields[62] as String?,
      verifiedDepartmentName: fields[63] as String?,
      evidenceVerificationStartedAtEpochMs: fields[64] as int?,
      evidenceVerificationCompletedAtEpochMs: fields[65] as int?,
      departmentVerificationStartedAtEpochMs: fields[66] as int?,
      departmentVerificationCompletedAtEpochMs: fields[67] as int?,
      verificationCompletedAtEpochMs: fields[68] as int?,
      verificationFailureReason: fields[69] as String?,
      citizenSafeVerificationMessage: fields[70] as String?,
      closedAtEpochMs: fields[71] as int?,
      closedBy: fields[72] as String?,
      closureRemarks: fields[73] as String?,
      aiVerificationAttempts: fields[74] as int? ?? 0,
      lastAiVerificationAttemptAtEpochMs: fields[75] as int?,
      lastAiFailureCode: fields[76] as String?,
      aiFallbackTriggeredAtEpochMs: fields[77] as int?,
      initialReviewDepartmentId: fields[78] as String?,
      initialReviewDepartmentName: fields[79] as String?,
      humanReviewStatus: fields[80] as String?,
      humanReviewerId: fields[81] as String?,
      humanReviewerName: fields[82] as String?,
      humanReviewRemarks: fields[83] as String?,
      humanReviewedAtEpochMs: fields[84] as int?,
      previousDepartmentId: fields[85] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComplaintLocalModel obj) {
    writer
      ..writeByte(86)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.citizenId)
      ..writeByte(2)
      ..write(obj.ticketNumber)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.categoryName)
      ..writeByte(7)
      ..write(obj.categoryDescription)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.imageUrls)
      ..writeByte(12)
      ..write(obj.createdAtEpochMs)
      ..writeByte(13)
      ..write(obj.updatedAtEpochMs)
      ..writeByte(14)
      ..write(obj.timeline)
      ..writeByte(15)
      ..write(obj.upvotes)
      ..writeByte(16)
      ..write(obj.isHazard)
      ..writeByte(17)
      ..write(obj.officerNotes)
      ..writeByte(18)
      ..write(obj.assignedTo)
      ..writeByte(19)
      ..write(obj.departmentName)
      ..writeByte(20)
      ..write(obj.resolvedAtEpochMs)
      ..writeByte(21)
      ..write(obj.syncStatus)
      ..writeByte(22)
      ..write(obj.localId)
      ..writeByte(23)
      ..write(obj.serverId)
      ..writeByte(24)
      ..write(obj.aiAuthenticityJson)
      ..writeByte(25)
      ..write(obj.aiAnalysisStatus)
      ..writeByte(26)
      ..write(obj.wardId)
      ..writeByte(27)
      ..write(obj.assignedDepartmentId)
      ..writeByte(28)
      ..write(obj.assignedDepartmentLeadId)
      ..writeByte(29)
      ..write(obj.assignedCrewMemberId)
      ..writeByte(30)
      ..write(obj.routingStatus)
      ..writeByte(31)
      ..write(obj.assignmentStatus)
      ..writeByte(32)
      ..write(obj.slaStartedAtEpochMs)
      ..writeByte(33)
      ..write(obj.originalCreatedAtEpochMs)
      ..writeByte(34)
      ..write(obj.currentDepartmentAssignedAtEpochMs)
      ..writeByte(35)
      ..write(obj.lastReassignedAtEpochMs)
      ..writeByte(36)
      ..write(obj.reassignmentCount)
      ..writeByte(37)
      ..write(obj.assignedJuniorEngineerNameSnapshot)
      ..writeByte(38)
      ..write(obj.assignedJuniorEngineerDesignationSnapshot)
      ..writeByte(39)
      ..write(obj.assignedFieldOfficerId)
      ..writeByte(40)
      ..write(obj.assignedFieldOfficerAtEpochMs)
      ..writeByte(41)
      ..write(obj.assignedFieldOfficerNameSnapshot)
      ..writeByte(42)
      ..write(obj.assignedFieldOfficerDesignationSnapshot)
      ..writeByte(43)
      ..write(obj.workStartedAtEpochMs)
      ..writeByte(44)
      ..write(obj.workStartedBy)
      ..writeByte(45)
      ..write(obj.beforeWorkPhoto)
      ..writeByte(46)
      ..write(obj.beforeWorkNotes)
      ..writeByte(47)
      ..write(obj.afterWorkPhoto)
      ..writeByte(48)
      ..write(obj.resolutionRemarks)
      ..writeByte(49)
      ..write(obj.resolvedBy)
      ..writeByte(50)
      ..write(obj.blockedAtEpochMs)
      ..writeByte(51)
      ..write(obj.blockedBy)
      ..writeByte(52)
      ..write(obj.blockedReason)
      ..writeByte(53)
      ..write(obj.reopenedAtEpochMs)
      ..writeByte(54)
      ..write(obj.reopenedBy)
      ..writeByte(55)
      ..write(obj.reopenReason)
      ..writeByte(56)
      ..write(obj.previousResolvedAtEpochMs)
      ..writeByte(57)
      ..write(obj.previousResolutionEvidence)
      ..writeByte(58)
      ..write(obj.reopenCount)
      ..writeByte(59)
      ..write(obj.evidenceVerificationStatus)
      ..writeByte(60)
      ..write(obj.departmentVerificationStatus)
      ..writeByte(61)
      ..write(obj.verificationStage)
      ..writeByte(62)
      ..write(obj.verifiedDepartmentId)
      ..writeByte(63)
      ..write(obj.verifiedDepartmentName)
      ..writeByte(64)
      ..write(obj.evidenceVerificationStartedAtEpochMs)
      ..writeByte(65)
      ..write(obj.evidenceVerificationCompletedAtEpochMs)
      ..writeByte(66)
      ..write(obj.departmentVerificationStartedAtEpochMs)
      ..writeByte(67)
      ..write(obj.departmentVerificationCompletedAtEpochMs)
      ..writeByte(68)
      ..write(obj.verificationCompletedAtEpochMs)
      ..writeByte(69)
      ..write(obj.verificationFailureReason)
      ..writeByte(70)
      ..write(obj.citizenSafeVerificationMessage)
      ..writeByte(71)
      ..write(obj.closedAtEpochMs)
      ..writeByte(72)
      ..write(obj.closedBy)
      ..writeByte(73)
      ..write(obj.closureRemarks)
      ..writeByte(74)
      ..write(obj.aiVerificationAttempts)
      ..writeByte(75)
      ..write(obj.lastAiVerificationAttemptAtEpochMs)
      ..writeByte(76)
      ..write(obj.lastAiFailureCode)
      ..writeByte(77)
      ..write(obj.aiFallbackTriggeredAtEpochMs)
      ..writeByte(78)
      ..write(obj.initialReviewDepartmentId)
      ..writeByte(79)
      ..write(obj.initialReviewDepartmentName)
      ..writeByte(80)
      ..write(obj.humanReviewStatus)
      ..writeByte(81)
      ..write(obj.humanReviewerId)
      ..writeByte(82)
      ..write(obj.humanReviewerName)
      ..writeByte(83)
      ..write(obj.humanReviewRemarks)
      ..writeByte(84)
      ..write(obj.humanReviewedAtEpochMs)
      ..writeByte(85)
      ..write(obj.previousDepartmentId);
  }
}

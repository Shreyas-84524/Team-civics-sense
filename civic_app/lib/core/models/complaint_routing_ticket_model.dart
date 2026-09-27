/// Routing Ticket Lifecycle Status for wrong-department reassignments.
enum RoutingTicketStatus {
  pending,
  approved,
  rejected,
  cancelled;

  String get label {
    switch (this) {
      case RoutingTicketStatus.pending:
        return 'Pending Ward Officer Review';
      case RoutingTicketStatus.approved:
        return 'Reassignment Approved';
      case RoutingTicketStatus.rejected:
        return 'Reassignment Rejected';
      case RoutingTicketStatus.cancelled:
        return 'Ticket Cancelled';
    }
  }

  static RoutingTicketStatus fromString(String? status) {
    if (status == null) return RoutingTicketStatus.pending;
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return RoutingTicketStatus.approved;
      case 'rejected':
        return RoutingTicketStatus.rejected;
      case 'cancelled':
        return RoutingTicketStatus.cancelled;
      case 'pending':
      default:
        return RoutingTicketStatus.pending;
    }
  }
}

/// Complaint Routing Ticket for Cross-Department Reassignment.
///
/// When a complaint is wrongly categorized or routed, the assigned Ward Department Lead
/// creates a `ComplaintRoutingTicket`. Only the responsible Ward Officer (or Super Admin override)
/// can approve or reject the transfer.
///
/// SLA Policy: The original complaint creation date and SLA clock are NEVER reset upon approval.
class ComplaintRoutingTicket {
  final String id;
  final String complaintId;
  final String ticketNumber;
  final String wardId;
  final String sourceDepartmentId;
  final String sourceLeadId;
  final String suggestedDepartmentId;
  final String reason;
  final RoutingTicketStatus status;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ComplaintRoutingTicket({
    required this.id,
    required this.complaintId,
    required this.ticketNumber,
    required this.wardId,
    required this.sourceDepartmentId,
    required this.sourceLeadId,
    required this.suggestedDepartmentId,
    required this.reason,
    this.status = RoutingTicketStatus.pending,
    this.reviewedBy,
    this.reviewNotes,
    required this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == RoutingTicketStatus.pending;
  bool get isApproved => status == RoutingTicketStatus.approved;
  bool get isRejected => status == RoutingTicketStatus.rejected;
  bool get isCancelled => status == RoutingTicketStatus.cancelled;

  ComplaintRoutingTicket copyWith({
    String? id,
    String? complaintId,
    String? ticketNumber,
    String? wardId,
    String? sourceDepartmentId,
    String? sourceLeadId,
    String? suggestedDepartmentId,
    String? reason,
    RoutingTicketStatus? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return ComplaintRoutingTicket(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      wardId: wardId ?? this.wardId,
      sourceDepartmentId: sourceDepartmentId ?? this.sourceDepartmentId,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      suggestedDepartmentId: suggestedDepartmentId ?? this.suggestedDepartmentId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  factory ComplaintRoutingTicket.fromJson(Map<String, dynamic> json) {
    return ComplaintRoutingTicket(
      id: json['id'] as String? ?? '',
      complaintId: json['complaintId'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String? ?? '',
      wardId: json['wardId'] as String? ?? '',
      sourceDepartmentId: json['sourceDepartmentId'] as String? ?? '',
      sourceLeadId: json['sourceLeadId'] as String? ?? '',
      suggestedDepartmentId: json['suggestedDepartmentId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: RoutingTicketStatus.fromString(json['status'] as String?),
      reviewedBy: json['reviewedBy'] as String?,
      reviewNotes: json['reviewNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] is DateTime
              ? json['reviewedAt'] as DateTime
              : DateTime.tryParse(json['reviewedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'ticketNumber': ticketNumber,
      'wardId': wardId,
      'sourceDepartmentId': sourceDepartmentId,
      'sourceLeadId': sourceLeadId,
      'suggestedDepartmentId': suggestedDepartmentId,
      'reason': reason,
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory ComplaintRoutingTicket.fromMap(Map<String, dynamic> map) =>
      ComplaintRoutingTicket.fromJson(map);
}

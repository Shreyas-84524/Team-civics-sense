import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/civic_department_model.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_manual_verification_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_manual_verification_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ComplaintModel createFallbackComplaint() {
    final now = DateTime.now();
    return ComplaintModel(
      id: 'CMP-TEST-001',
      citizenId: 'CITIZEN-001',
      ticketNumber: 'TICK-TEST-001',
      title: 'Water pipe rupture on 5th avenue',
      description: 'Severe water leak flooding street',
      category: CivicCategory(
        id: 'water_supply',
        name: 'Water Supply',
        description: 'Water pipeline and contamination',
        icon: Icons.water_drop,
      ),
      status: ComplaintStatus.underVerification,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0178,
        longitude: 72.8478,
        address: '5th Avenue, Dadar West',
        ward: 'G/North',
      ),
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
      slaStartedAt: now.subtract(const Duration(hours: 1)),
      originalCreatedAt: now.subtract(const Duration(hours: 1)),
      evidenceVerificationStatus: 'passed',
      departmentVerificationStatus: 'pending',
      verificationStage: 'humanDepartmentReview',
      aiVerificationAttempts: 3,
      lastAiFailureCode: 'TIMEOUT',
      aiFallbackTriggeredAt: now,
      initialReviewDepartmentId: 'hydraulic_engineer',
      initialReviewDepartmentName: 'Hydraulic Engineer Department',
      humanReviewStatus: 'pending',
      wardId: 'G_NORTH',
      assignedDepartmentId: 'hydraulic_engineer',
      routingStatus: ComplaintRoutingStatus.unassigned,
      assignmentStatus: ComplaintAssignmentStatus.unassigned,
    );
  }

  const sampleDepartments = [
    CivicDepartment(
      departmentId: 'hydraulic_engineer',
      departmentCode: 'HE',
      displayName: 'Hydraulic Engineer Department',
      description: 'Water pipeline and distribution network',
      defaultLeadDesignation: 'Executive Engineer (HE)',
    ),
    CivicDepartment(
      departmentId: 'maintenance_roads',
      departmentCode: 'MR',
      displayName: 'Roads & Traffic Department',
      description: 'Road repairs and maintenance',
      defaultLeadDesignation: 'Executive Engineer (Roads)',
    ),
    CivicDepartment(
      departmentId: 'solid_waste_management',
      departmentCode: 'SWM',
      displayName: 'Solid Waste Management',
      description: 'Garbage and sanitation',
      defaultLeadDesignation: 'Executive Engineer (SWM)',
    ),
  ];

  testWidgets('DepartmentLeadManualVerificationSection displays pending cards and triggers review callback', (tester) async {
    final complaint = createFallbackComplaint();
    ComplaintModel? reviewedComplaint;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentLeadManualVerificationSection(
            manualVerificationComplaints: [complaint],
            onReviewComplaint: (c) {
              reviewedComplaint = c;
            },
          ),
        ),
      ),
    );

    expect(find.text('AI FALLBACK — MANUAL DEPARTMENT REVIEW'), findsOneWidget);
    expect(find.text('#TICK-TEST-001'), findsOneWidget);
    expect(find.text('AI Offline Fallback'), findsOneWidget);
    expect(find.text('Water pipe rupture on 5th avenue'), findsOneWidget);

    // Tap review button
    final reviewBtn = find.text('Review & Decide');
    expect(reviewBtn, findsOneWidget);
    await tester.tap(reviewBtn);
    await tester.pump();

    expect(reviewedComplaint, isNotNull);
    expect(reviewedComplaint!.ticketNumber, equals('TICK-TEST-001'));
  });

  testWidgets('DepartmentLeadManualVerificationDialog allows confirming current department', (tester) async {
    final complaint = createFallbackComplaint();
    bool? confirmedBelongs;
    String? submittedRemarks;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentLeadManualVerificationDialog(
            complaint: complaint,
            leadId: 'LEAD-HE-001',
            allDepartments: sampleDepartments,
            onSubmitDecision: ({
              required belongsToCurrentDepartment,
              targetDepartmentId,
              required remarks,
            }) async {
              confirmedBelongs = belongsToCurrentDepartment;
              submittedRemarks = remarks;
            },
          ),
        ),
      ),
    );

    expect(find.text('AI Verification Fallback'), findsOneWidget);
    expect(find.text('AI Offline'), findsOneWidget);
    expect(find.textContaining('Hydraulic Engineer Department'), findsWidgets);

    // Tap Confirm & Auto-Route JE
    final confirmBtn = find.text('Confirm & Auto-Route JE');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(confirmedBelongs, isTrue);
    expect(submittedRemarks, isNotEmpty);
  });
}

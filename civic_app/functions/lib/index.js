"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.translateUserContent = exports.onComplaintStatusChanged = exports.submitHumanVerificationDecision = exports.onComplaintCreated = exports.CURRENT_TRANSLATION_VERSION = exports.SUPPORTED_LANGUAGES = exports.computeCacheDocId = exports.computeSourceHash = exports.isSupportedLanguage = exports.executeUserContentTranslation = exports.autoRouteVerifiedComplaint = exports.verifyComplaintDepartment = exports.verifyComplaintEvidence = exports.resolveDepartmentForCategory = exports.resolveWardForLocation = exports.getDepartmentById = exports.isValidDepartmentId = exports.ALLOWED_DEPARTMENT_IDS = exports.CANONICAL_DEPARTMENTS = void 0;
exports.sanitizeTokenDocId = sanitizeTokenDocId;
exports.sendCitizenNotification = sendCitizenNotification;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const gemini_verification_1 = require("./gemini_verification");
Object.defineProperty(exports, "verifyComplaintEvidence", { enumerable: true, get: function () { return gemini_verification_1.verifyComplaintEvidence; } });
Object.defineProperty(exports, "verifyComplaintDepartment", { enumerable: true, get: function () { return gemini_verification_1.verifyComplaintDepartment; } });
const routing_1 = require("./routing");
Object.defineProperty(exports, "autoRouteVerifiedComplaint", { enumerable: true, get: function () { return routing_1.autoRouteVerifiedComplaint; } });
const departments_1 = require("./departments");
Object.defineProperty(exports, "CANONICAL_DEPARTMENTS", { enumerable: true, get: function () { return departments_1.CANONICAL_DEPARTMENTS; } });
Object.defineProperty(exports, "ALLOWED_DEPARTMENT_IDS", { enumerable: true, get: function () { return departments_1.ALLOWED_DEPARTMENT_IDS; } });
Object.defineProperty(exports, "isValidDepartmentId", { enumerable: true, get: function () { return departments_1.isValidDepartmentId; } });
Object.defineProperty(exports, "getDepartmentById", { enumerable: true, get: function () { return departments_1.getDepartmentById; } });
Object.defineProperty(exports, "resolveWardForLocation", { enumerable: true, get: function () { return departments_1.resolveWardForLocation; } });
const departments_2 = require("./departments");
Object.defineProperty(exports, "resolveDepartmentForCategory", { enumerable: true, get: function () { return departments_2.resolveDepartmentForCategory; } });
const translation_1 = require("./translation");
Object.defineProperty(exports, "executeUserContentTranslation", { enumerable: true, get: function () { return translation_1.executeUserContentTranslation; } });
Object.defineProperty(exports, "isSupportedLanguage", { enumerable: true, get: function () { return translation_1.isSupportedLanguage; } });
Object.defineProperty(exports, "computeSourceHash", { enumerable: true, get: function () { return translation_1.computeSourceHash; } });
Object.defineProperty(exports, "computeCacheDocId", { enumerable: true, get: function () { return translation_1.computeCacheDocId; } });
Object.defineProperty(exports, "SUPPORTED_LANGUAGES", { enumerable: true, get: function () { return translation_1.SUPPORTED_LANGUAGES; } });
Object.defineProperty(exports, "CURRENT_TRANSLATION_VERSION", { enumerable: true, get: function () { return translation_1.CURRENT_TRANSLATION_VERSION; } });
// Initialize Firebase Admin SDK once per container lifecycle
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const messaging = admin.messaging();
function getStatusContent(status, ticketNumber, complaintTitle, departmentName, officerNotes) {
    switch (status) {
        case 'reported':
        case 'submitted':
            return {
                title: `Complaint Received: ${ticketNumber}`,
                body: `Your grievance "${complaintTitle}" has been logged and queued for verification.`,
                type: 'complaintSubmitted',
            };
        case 'underVerification':
            return {
                title: `Verification Underway: ${ticketNumber}`,
                body: `Your grievance "${complaintTitle}" is undergoing verification.`,
                type: 'complaintUnderVerification',
            };
        case 'verified':
            return {
                title: `Complaint Verified: ${ticketNumber}`,
                body: `Your grievance "${complaintTitle}" has been verified by the municipal authority.`,
                type: 'complaintVerified',
            };
        case 'assigned':
            return {
                title: `Officer Assigned: ${ticketNumber}`,
                body: departmentName
                    ? `Your grievance has been auto-routed to ${departmentName} for action.`
                    : `An engineer has been assigned to address your grievance "${complaintTitle}".`,
                type: 'complaintAssigned',
            };
        case 'inProgress':
            return {
                title: `Work In Progress: ${ticketNumber}`,
                body: `Municipal ground teams are actively resolving "${complaintTitle}".`,
                type: 'complaintStatusChanged',
            };
        case 'resolved':
            return {
                title: `Grievance Resolved: ${ticketNumber}`,
                body: `Work on "${complaintTitle}" is complete with photo proof. Tap to review.`,
                type: 'complaintResolved',
            };
        case 'closed':
            return {
                title: `Grievance Closed: ${ticketNumber}`,
                body: `Resolution for "${complaintTitle}" has been confirmed and closed.`,
                type: 'complaintClosed',
            };
        case 'reopened':
            return {
                title: `Complaint Reopened: ${ticketNumber}`,
                body: `Your grievance "${complaintTitle}" has been reopened for rework and investigation.`,
                type: 'complaintStatusChanged',
            };
        case 'rejected':
            return {
                title: `Complaint Update: ${ticketNumber}`,
                body: officerNotes
                    ? `Status updated: Closed/Rejected. Note: ${officerNotes}`
                    : `Your grievance "${complaintTitle}" has been closed. Tap for details.`,
                type: 'complaintStatusChanged',
            };
        default:
            return {
                title: `Status Updated: ${ticketNumber}`,
                body: `Your grievance "${complaintTitle}" is now marked as ${status}.`,
                type: 'complaintStatusChanged',
            };
    }
}
/**
 * Sanitizes FCM registration token for use as Firestore document ID.
 */
function sanitizeTokenDocId(token) {
    return token.replace(/[^a-zA-Z0-9_-]/g, '_');
}
/**
 * Centralized, idempotent helper to record in Firestore notifications collection
 * and dispatch multi-device FCM push notifications to the citizen.
 */
async function sendCitizenNotification(payload) {
    const { userId, title, body, type, complaintId, ticketNumber, priority = 'medium', status, targetRoute = '/complaint-details', sourceEventId, } = payload;
    if (!userId) {
        functions.logger.warn(`[sendCitizenNotification] Missing userId for complaint ${complaintId}. Cannot notify.`);
        return;
    }
    const timestamp = Date.now();
    const notificationDocId = `notif_${complaintId}_${type}_${timestamp}`;
    const notificationRef = db.collection('notifications').doc(notificationDocId);
    // 1. Authoritative Firestore Notification Record
    try {
        await notificationRef.set({
            id: notificationDocId,
            userId: userId,
            title: title,
            message: body,
            type: type,
            complaintId: complaintId,
            ticketNumber: ticketNumber,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            sourceEventId: sourceEventId || `event_${complaintId}_${timestamp}`,
            priority: priority,
        }, { merge: true });
        functions.logger.info(`[sendCitizenNotification] Created Firestore notification: ${notificationDocId}`);
    }
    catch (err) {
        functions.logger.error(`[sendCitizenNotification] Failed to write Firestore notification record:`, err);
    }
    // 2. Query Active Device Tokens
    try {
        const devicesSnapshot = await db
            .collection('users')
            .doc(userId)
            .collection('devices')
            .get();
        if (devicesSnapshot.empty) {
            functions.logger.info(`[sendCitizenNotification] No registered devices for user ${userId}`);
            return;
        }
        const tokensWithDocIds = [];
        devicesSnapshot.forEach((doc) => {
            const data = doc.data();
            if (data.token && typeof data.token === 'string') {
                tokensWithDocIds.push({ token: data.token, docId: doc.id });
            }
        });
        if (tokensWithDocIds.length === 0) {
            functions.logger.info(`[sendCitizenNotification] No valid token strings for user ${userId}`);
            return;
        }
        const tokens = tokensWithDocIds.map((item) => item.token);
        // 3. Construct FCM Multicast Payload
        const multicastMessage = {
            tokens: tokens,
            notification: {
                title: title,
                body: body,
            },
            data: {
                complaintId: complaintId,
                ticketNumber: ticketNumber,
                status: status || '',
                type: type,
                role: 'citizen',
                targetRoute: targetRoute,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'civicfix_complaints_channel',
                    icon: 'ic_launcher',
                    color: '#0052CC',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };
        // 4. Send FCM Push Notification
        const response = await messaging.sendEachForMulticast(multicastMessage);
        functions.logger.info(`[sendCitizenNotification] FCM push result for user ${userId}: ${response.successCount} succeeded, ${response.failureCount} failed.`);
        // 5. Cleanup Stale / Invalid Tokens
        if (response.failureCount > 0) {
            const invalidDocIdsToDelete = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success && resp.error) {
                    const errCode = resp.error.code;
                    if (errCode === 'messaging/registration-token-not-registered' ||
                        errCode === 'messaging/invalid-registration-token' ||
                        errCode === 'messaging/mismatched-credential') {
                        invalidDocIdsToDelete.push(tokensWithDocIds[idx].docId);
                    }
                }
            });
            if (invalidDocIdsToDelete.length > 0) {
                const batch = db.batch();
                invalidDocIdsToDelete.forEach((docId) => {
                    const tokenDocRef = db.collection('users').doc(userId).collection('devices').doc(docId);
                    batch.delete(tokenDocRef);
                });
                await batch.commit();
            }
        }
    }
    catch (pushErr) {
        functions.logger.error(`[sendCitizenNotification] Error dispatching push notification:`, pushErr);
    }
}
/**
 * Cloud Function Trigger: Automated Complaint Creation & Resilient AI Verification Pipeline.
 *
 * Triggered whenever a citizen submits a new complaint (`complaints/{complaintId}`).
 * 1. Step 1 (Gemini): Evidence & Image Authenticity Verification (with retry).
 *    - Transient Failure -> Human Department Review Fallback Queue.
 *    - Business Failure -> Rejected / Failed.
 * 2. Step 2 (Gemini): Department Verification against closed 18 BMC allowlist (with retry).
 *    - Transient Failure -> Human Department Review Fallback Queue.
 * 3. Step 3 (Backend): Automated Ward + Junior Engineer Routing & Assignment.
 */
exports.onComplaintCreated = functions.firestore
    .document('complaints/{complaintId}')
    .onCreate(async (snap, context) => {
    const complaintId = context.params.complaintId;
    const complaintData = snap.data();
    if (!complaintData) {
        functions.logger.warn(`[onComplaintCreated] Missing document data for ${complaintId}`);
        return;
    }
    functions.logger.info(`[onComplaintCreated] Ingesting complaint ${complaintId} (${complaintData.ticketNumber})`);
    const citizenId = complaintData.citizenId;
    const ticketNumber = complaintData.ticketNumber || `CF-${complaintId.substring(0, 6).toUpperCase()}`;
    const complaintTitle = complaintData.title || 'Civic Grievance';
    const priority = complaintData.priority || 'medium';
    // 1. Send authoritative submission confirmation notification to citizen
    if (citizenId) {
        await sendCitizenNotification({
            userId: citizenId,
            title: `Complaint Submitted: ${ticketNumber}`,
            body: `Your grievance "${complaintTitle}" has been received and queued for municipal verification.`,
            type: 'complaintSubmitted',
            complaintId: complaintId,
            ticketNumber: ticketNumber,
            priority: priority,
            status: complaintData.status || 'reported',
            sourceEventId: `submitted_${complaintId}`,
        });
    }
    const complaintRef = db.collection('complaints').doc(complaintId);
    // Initial check: if already human-reviewed or assigned, avoid redundant processing
    if (complaintData.humanReviewStatus === 'approved' ||
        complaintData.humanReviewStatus === 'transferred' ||
        complaintData.status === 'assigned') {
        functions.logger.info(`[onComplaintCreated] Complaint ${complaintId} is already processed/assigned. Skipping.`);
        return;
    }
    try {
        // -----------------------------------------------------------------------
        // STAGE 2: GEMINI STEP 1 — EVIDENCE AUTHENTICITY VERIFICATION
        // -----------------------------------------------------------------------
        functions.logger.info(`[onComplaintCreated] Step 1: Running evidence verification for ${complaintId}`);
        const evidenceResult = await (0, gemini_verification_1.verifyComplaintEvidence)({
            title: complaintData.title || '',
            description: complaintData.description || '',
            category: complaintData.category,
            imageUrls: complaintData.imageUrls || [],
        });
        // Handle Class B: Transient AI Infrastructure Failure -> Human Review Fallback
        if (evidenceResult.isTransientFailure) {
            functions.logger.warn(`[onComplaintCreated] Step 1 transient failure for ${complaintId} (${evidenceResult.failureCode}). Triggering Human Fallback.`);
            const initialDept = (0, departments_2.resolveDepartmentForCategory)(complaintData.category);
            const location = complaintData.location || {};
            const resolvedWard = (0, departments_1.resolveWardForLocation)(location.latitude, location.longitude, complaintData.wardId || location.ward);
            const fallbackUpdate = {
                status: 'underVerification',
                verificationStage: 'humanDepartmentReview',
                humanReviewStatus: 'pending',
                evidenceVerificationStatus: 'temporarily_unavailable',
                departmentVerificationStatus: 'temporarily_unavailable',
                aiVerificationAttempts: evidenceResult.attempts || 3,
                lastAiVerificationAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
                lastAiFailureCode: evidenceResult.failureCode || 'AI_TEMPORARILY_UNAVAILABLE',
                aiFallbackTriggeredAt: admin.firestore.FieldValue.serverTimestamp(),
                initialReviewDepartmentId: initialDept.departmentId,
                initialReviewDepartmentName: initialDept.displayName,
                assignedDepartmentId: initialDept.departmentId,
                departmentName: initialDept.displayName,
                wardId: resolvedWard ? resolvedWard.wardId : (complaintData.wardId || null),
                citizenSafeVerificationMessage: 'Automated verification is temporarily unavailable. Your complaint has been forwarded for manual departmental review.',
                aiAnalysisStatus: 'temporarily_unavailable',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            await complaintRef.update(fallbackUpdate);
            const updateId = `upd_ai_fallback_${Date.now()}`;
            await complaintRef.collection('complaint_updates').doc(updateId).set({
                id: updateId,
                complaintId: complaintId,
                status: 'underVerification',
                title: 'Forwarded for Manual Review',
                notes: 'Automated verification is temporarily unavailable. Forwarded to Ward Department Lead for manual verification.',
                updatedBy: 'system_ai_verifier',
                updatedByRole: 'system',
                updatedByName: 'AI Verification System',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await db.collection('government_audit_logs').add({
                complaintId,
                action: 'human_review_requested',
                actorId: 'system_ai_verifier',
                actorRole: 'system',
                actorName: 'AI Verification System',
                wardId: resolvedWard?.wardId || null,
                departmentId: initialDept.departmentId,
                details: {
                    ticketNumber: complaintData.ticketNumber,
                    reason: evidenceResult.reason,
                    failureCode: evidenceResult.failureCode,
                    attempts: evidenceResult.attempts,
                    initialDepartmentId: initialDept.departmentId,
                },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            return;
        }
        // Handle Class A: Business Verification Failure (Spam / Non-civic issue)
        if (!evidenceResult.passed) {
            const failureReason = evidenceResult.reason || 'Evidence verification failed.';
            const step1FailureUpdate = {
                evidenceVerificationStatus: 'failed',
                evidenceVerificationAt: admin.firestore.FieldValue.serverTimestamp(),
                evidenceVerificationScore: evidenceResult.confidence,
                evidenceVerificationNotes: failureReason,
                verificationStage: 'evidence_failed',
                verificationFailureReason: failureReason,
                citizenSafeVerificationMessage: 'Evidence verification could not confirm a valid civic issue. A municipal officer will manually review your submission.',
                aiAnalysisStatus: 'failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            await complaintRef.update(step1FailureUpdate);
            const updateId = `upd_ev_fail_${Date.now()}`;
            await complaintRef.collection('complaint_updates').doc(updateId).set({
                id: updateId,
                complaintId: complaintId,
                status: 'underVerification',
                updatedBy: 'system_ai_verifier',
                updatedByRole: 'system',
                updatedByName: 'AI Verification System',
                notes: `Evidence Verification: ${failureReason}. Queued for manual officer review.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.warn(`[onComplaintCreated] Evidence verification failed for ${complaintId}: ${failureReason}`);
            return;
        }
        // Step 1 Passed
        const step1Update = {
            evidenceVerificationStatus: 'passed',
            evidenceVerificationAt: admin.firestore.FieldValue.serverTimestamp(),
            evidenceVerificationScore: evidenceResult.confidence,
            evidenceVerificationNotes: evidenceResult.reason,
            verificationStage: 'department_verification',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await complaintRef.update(step1Update);
        // -----------------------------------------------------------------------
        // STAGE 3: GEMINI STEP 2 — DEPARTMENT VERIFICATION
        // -----------------------------------------------------------------------
        functions.logger.info(`[onComplaintCreated] Step 2: Running department verification for ${complaintId}`);
        const deptResult = await (0, gemini_verification_1.verifyComplaintDepartment)({
            title: complaintData.title || '',
            description: complaintData.description || '',
            category: complaintData.category,
            imageUrls: complaintData.imageUrls || [],
        }, evidenceResult);
        // Handle Class B: Department Verification Transient Failure -> Human Review Fallback
        if (deptResult.isTransientFailure) {
            functions.logger.warn(`[onComplaintCreated] Step 2 transient failure for ${complaintId} (${deptResult.failureCode}). Triggering Human Fallback.`);
            const initialDept = (0, departments_2.resolveDepartmentForCategory)(complaintData.category);
            const location = complaintData.location || {};
            const resolvedWard = (0, departments_1.resolveWardForLocation)(location.latitude, location.longitude, complaintData.wardId || location.ward);
            const fallbackUpdate = {
                status: 'underVerification',
                verificationStage: 'humanDepartmentReview',
                humanReviewStatus: 'pending',
                evidenceVerificationStatus: 'passed',
                departmentVerificationStatus: 'temporarily_unavailable',
                aiVerificationAttempts: deptResult.attempts || 3,
                lastAiVerificationAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
                lastAiFailureCode: deptResult.failureCode || 'AI_TEMPORARILY_UNAVAILABLE',
                aiFallbackTriggeredAt: admin.firestore.FieldValue.serverTimestamp(),
                initialReviewDepartmentId: initialDept.departmentId,
                initialReviewDepartmentName: initialDept.displayName,
                assignedDepartmentId: initialDept.departmentId,
                departmentName: initialDept.displayName,
                wardId: resolvedWard ? resolvedWard.wardId : (complaintData.wardId || null),
                citizenSafeVerificationMessage: 'Automated verification is temporarily unavailable. Your complaint has been forwarded for manual departmental review.',
                aiAnalysisStatus: 'temporarily_unavailable',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            await complaintRef.update(fallbackUpdate);
            const updateId = `upd_ai_fallback_${Date.now()}`;
            await complaintRef.collection('complaint_updates').doc(updateId).set({
                id: updateId,
                complaintId: complaintId,
                status: 'underVerification',
                title: 'Forwarded for Manual Review',
                notes: 'Department classification is temporarily unavailable. Forwarded to Ward Department Lead for manual verification.',
                updatedBy: 'system_ai_verifier',
                updatedByRole: 'system',
                updatedByName: 'AI Verification System',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await db.collection('government_audit_logs').add({
                complaintId,
                action: 'human_review_requested',
                actorId: 'system_ai_verifier',
                actorRole: 'system',
                actorName: 'AI Verification System',
                wardId: resolvedWard?.wardId || null,
                departmentId: initialDept.departmentId,
                details: {
                    ticketNumber: complaintData.ticketNumber,
                    reason: deptResult.rationale,
                    failureCode: deptResult.failureCode,
                    attempts: deptResult.attempts,
                    initialDepartmentId: initialDept.departmentId,
                },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            return;
        }
        if (!deptResult.passed || !deptResult.verifiedDepartmentId) {
            const failureRationale = deptResult.rationale || 'Department verification failed to match a canonical BMC department.';
            const step2FailureUpdate = {
                departmentVerificationStatus: 'failed',
                departmentVerificationAt: admin.firestore.FieldValue.serverTimestamp(),
                departmentVerificationScore: deptResult.confidence,
                departmentVerificationNotes: failureRationale,
                verifiedDepartmentId: null,
                verifiedDepartmentName: null,
                verificationStage: 'department_failed',
                verificationFailureReason: failureRationale,
                citizenSafeVerificationMessage: 'Department routing could not automatically classify this issue. Routed to Central Ward Administration for manual assignment.',
                aiAnalysisStatus: 'failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            await complaintRef.update(step2FailureUpdate);
            return;
        }
        const step2Update = {
            departmentVerificationStatus: 'passed',
            departmentVerificationAt: admin.firestore.FieldValue.serverTimestamp(),
            departmentVerificationScore: deptResult.confidence,
            departmentVerificationNotes: deptResult.rationale,
            verifiedDepartmentId: deptResult.verifiedDepartmentId,
            verifiedDepartmentName: deptResult.verifiedDepartmentName || deptResult.verifiedDepartmentId,
            verificationStage: 'verification_completed',
            aiAnalysisStatus: 'completed',
            verificationCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await complaintRef.update(step2Update);
        functions.logger.info(`[onComplaintCreated] Step 2 result for ${complaintId}: PASSED -> ${deptResult.verifiedDepartmentId} (${deptResult.verifiedDepartmentName})`);
        // -----------------------------------------------------------------------
        // STAGE 4: AUTOMATED WARD + JUNIOR ENGINEER ROUTING
        // -----------------------------------------------------------------------
        functions.logger.info(`[onComplaintCreated] Step 3: Auto-routing complaint ${complaintId} to Junior Engineer`);
        const updatedSnap = await complaintRef.get();
        const currentData = updatedSnap.data() || complaintData;
        // Late human response check: if reviewed during processing, ignore AI routing
        if (currentData.humanReviewStatus === 'approved' ||
            currentData.humanReviewStatus === 'transferred') {
            functions.logger.info(`[onComplaintCreated] Complaint ${complaintId} was already manually reviewed. Ignoring AI routing.`);
            await db.collection('government_audit_logs').add({
                complaintId,
                action: 'late_ai_response_ignored',
                actorId: 'system_ai_verifier',
                actorRole: 'system',
                actorName: 'AI Verification System',
                details: { message: 'Late AI response ignored because human review already finalized routing.' },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            return;
        }
        const routingResult = await (0, routing_1.autoRouteVerifiedComplaint)(db, complaintId, currentData, deptResult.verifiedDepartmentId, deptResult.verifiedDepartmentName || deptResult.verifiedDepartmentId);
        functions.logger.info(`[onComplaintCreated] Auto-routing result for ${complaintId}: ${routingResult.message}`);
    }
    catch (err) {
        functions.logger.error(`[onComplaintCreated] Pipeline failure for complaint ${complaintId}:`, err);
        const errorMessage = err instanceof Error ? err.message : String(err);
        try {
            const initialDept = (0, departments_2.resolveDepartmentForCategory)(complaintData.category);
            await complaintRef.update({
                status: 'underVerification',
                verificationStage: 'humanDepartmentReview',
                humanReviewStatus: 'pending',
                evidenceVerificationStatus: 'temporarily_unavailable',
                departmentVerificationStatus: 'temporarily_unavailable',
                aiAnalysisStatus: 'temporarily_unavailable',
                verificationFailureReason: errorMessage,
                initialReviewDepartmentId: initialDept.departmentId,
                initialReviewDepartmentName: initialDept.displayName,
                citizenSafeVerificationMessage: 'Automated verification is temporarily unavailable. Your complaint has been forwarded for manual departmental review.',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const updateId = `upd_err_${Date.now()}`;
            await complaintRef.collection('complaint_updates').doc(updateId).set({
                id: updateId,
                complaintId: complaintId,
                status: 'underVerification',
                updatedBy: 'system_ai_verifier',
                updatedByRole: 'system',
                updatedByName: 'AI Verification System',
                notes: `Automated processing notice: Forwarded for manual departmental review.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        catch (innerErr) {
            functions.logger.error(`[onComplaintCreated] Failed to write error fallback state for ${complaintId}:`, innerErr);
        }
    }
});
/**
 * Cloud Function Callable: Submit Human Verification Decision (Confirm or Transfer Department).
 *
 * Authoritative backend endpoint for Ward Department Leads to resolve AI fallback verification reviews.
 */
exports.submitHumanVerificationDecision = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required to submit human verification decisions.');
    }
    const { complaintId, decision, targetDepartmentId, reason, remarks } = data;
    if (!complaintId) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing complaintId.');
    }
    if (decision !== 'confirm_department' && decision !== 'transfer_department') {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid decision type.');
    }
    const callerUid = context.auth.uid;
    const govtUserDoc = await db.collection('government_users').doc(callerUid).get();
    if (!govtUserDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only authorized government personnel can submit verification decisions.');
    }
    const govtUser = govtUserDoc.data();
    const allowedRoles = [
        'ward_department_lead',
        'central_department_hod',
        'ward_officer',
        'government_super_admin',
        'zonal_dmc',
        'government',
    ];
    if (!allowedRoles.includes(govtUser.role)) {
        throw new functions.https.HttpsError('permission-denied', `Role "${govtUser.role}" is not authorized to submit verification decisions.`);
    }
    const complaintRef = db.collection('complaints').doc(complaintId);
    let originalDeptId = '';
    let finalDeptId = '';
    let finalDeptName = '';
    const txResult = await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(complaintRef);
        if (!snap.exists) {
            throw new functions.https.HttpsError('not-found', 'Complaint not found.');
        }
        const cData = snap.data();
        // Idempotency check: if human review is already completed or complaint already assigned
        if (cData.humanReviewStatus === 'approved' ||
            cData.humanReviewStatus === 'transferred' ||
            (cData.status !== 'underVerification' && cData.status !== 'reported')) {
            return {
                alreadyProcessed: true,
                message: 'Human review decision already processed.',
            };
        }
        originalDeptId =
            cData.assignedDepartmentId ||
                cData.initialReviewDepartmentId ||
                'maintenance_roads';
        finalDeptId =
            decision === 'transfer_department' && targetDepartmentId
                ? targetDepartmentId.trim().toLowerCase()
                : originalDeptId;
        if (!(0, departments_1.isValidDepartmentId)(finalDeptId)) {
            throw new functions.https.HttpsError('invalid-argument', `Department "${finalDeptId}" is not in the canonical 18 BMC departments allowlist.`);
        }
        if (decision === 'transfer_department' && (!reason || reason.trim().length === 0)) {
            throw new functions.https.HttpsError('invalid-argument', 'A valid reason is required when transferring complaint to another department.');
        }
        const targetDeptMeta = (0, departments_1.getDepartmentById)(finalDeptId);
        finalDeptName = targetDeptMeta.displayName;
        const location = cData.location || {};
        const resolvedWard = (0, departments_1.resolveWardForLocation)(location.latitude, location.longitude, cData.wardId || location.ward);
        if (!resolvedWard) {
            throw new functions.https.HttpsError('failed-precondition', 'Cannot resolve valid BMC Ward for complaint location coordinates.');
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        transaction.update(complaintRef, {
            humanReviewStatus: decision === 'confirm_department' ? 'approved' : 'transferred',
            humanReviewerId: govtUser.employeeId || callerUid,
            humanReviewerName: govtUser.fullName || 'Departmental Officer',
            humanReviewRemarks: remarks || reason || '',
            humanReviewedAt: now,
            verifiedDepartmentId: targetDeptMeta.departmentId,
            verifiedDepartmentName: targetDeptMeta.displayName,
            evidenceVerificationStatus: 'passed',
            departmentVerificationStatus: 'passed',
            verificationStage: 'verification_completed',
            previousDepartmentId: decision === 'transfer_department' ? originalDeptId : null,
            assignedDepartmentId: targetDeptMeta.departmentId,
            departmentName: targetDeptMeta.displayName,
            wardId: resolvedWard.wardId,
            aiAnalysisStatus: 'completed',
            updatedAt: now,
        });
        return {
            alreadyProcessed: false,
            finalDeptId: targetDeptMeta.departmentId,
            finalDeptName: targetDeptMeta.displayName,
            resolvedWard,
        };
    });
    if (txResult.alreadyProcessed) {
        return { success: true, message: txResult.message };
    }
    // Resume Junior Engineer routing
    const freshSnap = await complaintRef.get();
    const freshData = freshSnap.data();
    const routingResult = await (0, routing_1.autoRouteVerifiedComplaint)(db, complaintId, freshData, finalDeptId, finalDeptName);
    // Audit log
    await db.collection('government_audit_logs').add({
        complaintId,
        action: decision === 'confirm_department'
            ? 'human_department_confirmed'
            : 'human_department_transferred',
        actorId: govtUser.employeeId || callerUid,
        actorRole: govtUser.role,
        actorName: govtUser.fullName,
        wardId: freshData.wardId,
        departmentId: finalDeptId,
        details: {
            ticketNumber: freshData.ticketNumber,
            decision,
            previousDepartmentId: decision === 'transfer_department' ? originalDeptId : null,
            targetDepartmentId: finalDeptId,
            reason: reason || remarks || '',
            assignedJuniorEngineerId: routingResult.assignedJuniorEngineer?.employeeId,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        message: `Human review decision recorded and auto-routed to ${routingResult.assignedJuniorEngineer?.fullName || 'department queue'}.`,
        routingResult,
    };
});
/**
 * Cloud Function Trigger: Automated Status Change Notifications
 *
 * Triggered whenever a document in the `complaints` collection is updated.
 */
exports.onComplaintStatusChanged = functions.firestore
    .document('complaints/{complaintId}')
    .onUpdate(async (change, context) => {
    const complaintId = context.params.complaintId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (!beforeData || !afterData) {
        functions.logger.info(`[onComplaintStatusChanged] Missing before/after data for ${complaintId}`);
        return;
    }
    const prevStatus = beforeData.status;
    const newStatus = afterData.status;
    // 1. Strict Status Diffing: Only execute if status has actually transitioned
    if (prevStatus === newStatus) {
        return;
    }
    const citizenId = afterData.citizenId;
    const ticketNumber = afterData.ticketNumber || `CF-${complaintId.substring(0, 6).toUpperCase()}`;
    const complaintTitle = afterData.title || 'Civic Grievance';
    const departmentName = afterData.departmentName;
    const officerNotes = afterData.officerNotes;
    const priority = afterData.priority || 'medium';
    if (!citizenId) {
        functions.logger.warn(`[onComplaintStatusChanged] Complaint ${complaintId} has no citizenId. Cannot notify.`);
        return;
    }
    // 2. Compute Idempotent Event Identifier
    const updatedAtMillis = afterData.updatedAt?.toMillis ? afterData.updatedAt.toMillis() : Date.now();
    const sourceEventId = `status_${complaintId}_${newStatus}_${updatedAtMillis}`;
    const content = getStatusContent(newStatus, ticketNumber, complaintTitle, departmentName, officerNotes);
    functions.logger.info(`[onComplaintStatusChanged] Processing status change ${prevStatus} -> ${newStatus} for ticket ${ticketNumber}`);
    // 3. Dispatch Authoritative Firestore Notification Record & Multi-device FCM Push
    await sendCitizenNotification({
        userId: citizenId,
        title: content.title,
        body: content.body,
        type: content.type,
        complaintId: complaintId,
        ticketNumber: ticketNumber,
        priority: priority,
        status: newStatus,
        targetRoute: '/complaint-details',
        sourceEventId: sourceEventId,
    });
});
/**
 * Cloud Function Callable: Secure Multilingual User-Generated Content Translation.
 *
 * Translates human-authored civic grievance text (complaint titles, descriptions,
 * officer instructions, remarks) between English, Hindi, and Marathi via Gemini AI
 * backed by persistent Firestore cache and strict glossary adherence.
 */
exports.translateUserContent = functions.https.onCall(async (data, context) => {
    // Authenticated users and authorized clients
    if (!data || typeof data !== 'object') {
        throw new functions.https.HttpsError('invalid-argument', 'Missing translation payload.');
    }
    functions.logger.info(`[translateUserContent] Request: ${data.sourceLanguage || 'auto'} -> ${data.targetLanguage} (${data.contentType || 'generic'}, len: ${(data.text || '').length})`);
    return (0, translation_1.executeUserContentTranslation)(db, data);
});
//# sourceMappingURL=index.js.map
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Initialize Firebase Admin SDK once per container lifecycle
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Maps raw complaint status codes to user-friendly display titles and descriptive bodies.
 */
interface StatusContent {
  title: string;
  body: string;
  type: string;
}

function getStatusContent(
  status: string,
  ticketNumber: string,
  complaintTitle: string,
  departmentName?: string,
  officerNotes?: string
): StatusContent {
  switch (status) {
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
          ? `Your grievance has been assigned to ${departmentName} for action.`
          : `An officer has been assigned to address your grievance "${complaintTitle}".`,
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
        body: `Work on "${complaintTitle}" is complete. Tap to review the resolution.`,
        type: 'complaintResolved',
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
export function sanitizeTokenDocId(token: string): string {
  return token.replace(/[^a-zA-Z0-9_-]/g, '_');
}

/**
 * Cloud Function Trigger: Automated Status Change Notifications
 *
 * Triggered whenever a document in the `complaints` collection is updated.
 * Diffs previous status vs new status. If changed:
 * 1. Writes an authoritative notification record to Firestore `notifications` collection (idempotent).
 * 2. Fetches registered FCM device tokens for the citizen.
 * 3. Sends FCM high-priority push notifications with deep-link metadata.
 * 4. Automatically removes stale/invalid FCM tokens to keep device collections clean.
 */
export const onComplaintStatusChanged = functions.firestore
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
      functions.logger.debug(`[onComplaintStatusChanged] Status unchanged (${prevStatus}) for ${complaintId}. Skipping.`);
      return;
    }

    const citizenId = afterData.citizenId as string;
    const ticketNumber = (afterData.ticketNumber as string) || `CF-${complaintId.substring(0, 6).toUpperCase()}`;
    const complaintTitle = (afterData.title as string) || 'Civic Grievance';
    const departmentName = afterData.departmentName as string | undefined;
    const officerNotes = afterData.officerNotes as string | undefined;
    const priority = (afterData.priority as string) || 'medium';

    if (!citizenId) {
      functions.logger.warn(`[onComplaintStatusChanged] Complaint ${complaintId} has no citizenId. Cannot notify.`);
      return;
    }

    // 2. Compute Idempotent Event Identifier
    const updatedAtMillis = afterData.updatedAt?.toMillis ? afterData.updatedAt.toMillis() : Date.now();
    const sourceEventId = `status_${complaintId}_${newStatus}_${updatedAtMillis}`;
    const notificationDocId = `notif_${complaintId}_${newStatus}_${updatedAtMillis}`;

    const content = getStatusContent(newStatus, ticketNumber, complaintTitle, departmentName, officerNotes);

    functions.logger.info(
      `[onComplaintStatusChanged] Processing status change ${prevStatus} -> ${newStatus} for ticket ${ticketNumber}`
    );

    // 3. Write Authoritative Firestore Notification Record (Idempotent via deterministic doc ID)
    const notificationRef = db.collection('notifications').doc(notificationDocId);

    try {
      await notificationRef.set(
        {
          id: notificationDocId,
          userId: citizenId,
          title: content.title,
          message: content.body,
          type: content.type,
          complaintId: complaintId,
          ticketNumber: ticketNumber,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          sourceEventId: sourceEventId,
          priority: priority,
        },
        { merge: true }
      );

      functions.logger.info(`[onComplaintStatusChanged] Created Firestore notification: ${notificationDocId}`);
    } catch (err) {
      functions.logger.error(`[onComplaintStatusChanged] Failed to write Firestore notification record:`, err);
      // Non-blocking: continue attempting push notification delivery
    }

    // 4. Retrieve Active FCM Device Tokens for the Citizen
    try {
      const devicesSnapshot = await db
        .collection('users')
        .doc(citizenId)
        .collection('devices')
        .get();

      if (devicesSnapshot.empty) {
        functions.logger.info(`[onComplaintStatusChanged] No registered devices for user ${citizenId}`);
        return;
      }

      const tokensWithDocIds: Array<{ token: string; docId: string }> = [];
      devicesSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.token && typeof data.token === 'string') {
          tokensWithDocIds.push({ token: data.token, docId: doc.id });
        }
      });

      if (tokensWithDocIds.length === 0) {
        functions.logger.info(`[onComplaintStatusChanged] No valid token strings for user ${citizenId}`);
        return;
      }

      const tokens = tokensWithDocIds.map((item) => item.token);

      // 5. Construct FCM Multicast Payload with Deep-Linking Data
      const multicastMessage: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          complaintId: complaintId,
          ticketNumber: ticketNumber,
          status: newStatus,
          type: content.type,
          role: 'citizen',
          targetRoute: '/complaint-details',
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

      // 6. Send FCM Push Notification
      const response = await messaging.sendEachForMulticast(multicastMessage);
      functions.logger.info(
        `[onComplaintStatusChanged] FCM push result: ${response.successCount} succeeded, ${response.failureCount} failed.`
      );

      // 7. Cleanup Stale / Invalid Tokens
      if (response.failureCount > 0) {
        const invalidDocIdsToDelete: string[] = [];

        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errCode = resp.error.code;
            functions.logger.warn(`[onComplaintStatusChanged] Token failure [${errCode}]:`, resp.error.message);

            if (
              errCode === 'messaging/registration-token-not-registered' ||
              errCode === 'messaging/invalid-registration-token' ||
              errCode === 'messaging/mismatched-credential'
            ) {
              invalidDocIdsToDelete.push(tokensWithDocIds[idx].docId);
            }
          }
        });

        if (invalidDocIdsToDelete.length > 0) {
          functions.logger.info(
            `[onComplaintStatusChanged] Cleaning up ${invalidDocIdsToDelete.length} stale FCM device tokens for user ${citizenId}`
          );
          const batch = db.batch();
          invalidDocIdsToDelete.forEach((docId) => {
            const staleRef = db.collection('users').doc(citizenId).collection('devices').doc(docId);
            batch.delete(staleRef);
          });
          await batch.commit();
        }
      }
    } catch (pushErr) {
      functions.logger.error(`[onComplaintStatusChanged] Error during FCM push multicast:`, pushErr);
    }
  });

/**
 * Cloud Function Trigger: Automated Submission Confirmation
 *
 * Triggered on initial grievance submission.
 * Writes confirmation notification to Firestore and dispatches push to citizen.
 */
export const onComplaintCreated = functions.firestore
  .document('complaints/{complaintId}')
  .onCreate(async (snapshot, context) => {
    const complaintId = context.params.complaintId;
    const data = snapshot.data();

    if (!data) return;

    const citizenId = data.citizenId as string;
    const ticketNumber = (data.ticketNumber as string) || `CF-${complaintId.substring(0, 6).toUpperCase()}`;
    const complaintTitle = (data.title as string) || 'Civic Grievance';

    if (!citizenId) return;

    const sourceEventId = `created_${complaintId}`;
    const notificationDocId = `notif_created_${complaintId}`;

    const title = `Grievance Submitted: ${ticketNumber}`;
    const body = `Your complaint "${complaintTitle}" has been logged successfully and routed for verification.`;

    // 1. Authoritative notification record
    try {
      await db.collection('notifications').doc(notificationDocId).set(
        {
          id: notificationDocId,
          userId: citizenId,
          title: title,
          message: body,
          type: 'complaintSubmitted',
          complaintId: complaintId,
          ticketNumber: ticketNumber,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          sourceEventId: sourceEventId,
          priority: data.priority || 'medium',
        },
        { merge: true }
      );
    } catch (err) {
      functions.logger.error(`[onComplaintCreated] Error writing submission notification:`, err);
    }

    // 2. Dispatch Push
    try {
      const devicesSnapshot = await db
        .collection('users')
        .doc(citizenId)
        .collection('devices')
        .get();

      if (devicesSnapshot.empty) return;

      const tokens: string[] = [];
      devicesSnapshot.forEach((doc) => {
        const token = doc.data().token;
        if (token && typeof token === 'string') {
          tokens.push(token);
        }
      });

      if (tokens.length === 0) return;

      await messaging.sendEachForMulticast({
        tokens: tokens,
        notification: { title, body },
        data: {
          complaintId: complaintId,
          ticketNumber: ticketNumber,
          status: 'reported',
          type: 'complaintSubmitted',
          role: 'citizen',
          targetRoute: '/complaint-details',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
    } catch (pushErr) {
      functions.logger.error(`[onComplaintCreated] Error dispatching push:`, pushErr);
    }
  });


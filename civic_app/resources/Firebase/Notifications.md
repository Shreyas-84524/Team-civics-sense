# CivicFix Firebase Cloud Messaging & Automated Notifications Architecture

## 1. Executive Summary & Core Philosophy

CivicFix uses a decoupled, privacy-first notification architecture:

1. **Cloud Firestore is the Authoritative Source of Truth**: All civic notifications are persisted in the `notifications` collection (`notifications/{notificationId}`). Real-time Firestore snapshot listeners stream changes directly into local Hive caching repositories (`OfflineFirstNotificationRepository`).
2. **Firebase Cloud Messaging (FCM) is the Push Delivery Channel**: FCM delivers background and terminated push alerts to citizen and municipal officer devices. Push delivery failures never block grievance state transitions or local offline queues.
3. **Automated Serverless Triggers (Cloud Functions)**: Cloud Firestore triggers diff document mutations on `complaints/{complaintId}` on update/create, enforcing idempotency (`sourceEventId`), writing authoritative notification records, dispatching FCM multicast pushes, and automatically pruning stale device tokens.
4. **No Server Keys on Client**: Client applications only interact with standard FCM SDK APIs (`getToken`, `onMessage`, `onMessageOpenedApp`). All FCM administrative multicast dispatches originate exclusively from trusted Cloud Functions with the Admin SDK.

```mermaid
sequenceDiagram
    autonumber
    actor Govt as Municipal Officer
    participant GovtApp as Government UI
    participant Firestore as Cloud Firestore
    participant Functions as Cloud Functions (Trigger)
    participant FCM as Firebase Cloud Messaging
    participant CitizenApp as Citizen UI
    actor Citizen as Citizen User

    Govt->>GovtApp: Updates Status (e.g. Verified -> In Progress)
    GovtApp->>Firestore: Update complaints/{complaintId}
    Firestore-->>CitizenApp: Real-time Snapshot Stream (Live UI refresh via Hive Cache)
    Firestore->>Functions: onComplaintStatusChanged (Diff before vs after)
    Note over Functions: Validate status changed & compute sourceEventId
    Functions->>Firestore: Set notifications/{notificationDocId}
    Functions->>Firestore: Query users/{citizenId}/devices
    Functions->>FCM: sendEachForMulticast(tokens, payload)
    FCM->>CitizenApp: Push Notification Delivered
    Citizen->>CitizenApp: Taps Notification
    CitizenApp->>CitizenApp: Deep Links to Complaint Tracker / Details
```

---

## 2. Multi-Device Token Lifecycle

Each user's active device tokens are maintained in a dedicated subcollection under their profile:

```text
users/
  └── {userId}/
        └── devices/
              └── {sanitizedTokenDocId}/
                    ├── token: "fcm_token_string..."
                    ├── platform: "android" | "ios" | "web"
                    ├── appVersion: "1.0.0+1"
                    ├── createdAt: Timestamp
                    ├── updatedAt: Timestamp
                    └── lastSeenAt: Timestamp
```

### 2.1 Token Registration Flow
1. Upon successful login (`FirebaseAuthService.login` or `FirebaseGovtAuthService.login`), the app acquires the active FCM registration token via `FirebaseNotificationService.getToken()`.
2. `FirebaseUserDataSource.registerDeviceToken(userId, token, platform: ...)` upserts the document in `users/{userId}/devices/{docId}` using `SetOptions(merge: true)`.
3. If the FCM token is refreshed by the platform while the session is active, `FirebaseMessaging.instance.onTokenRefresh` automatically updates the Firestore record.

### 2.2 Token Unregistration on Logout
To ensure multi-user isolation on shared devices:
1. When a user logs out (`logout()`), `FirebaseNotificationService.unregisterDeviceToken(userId)` deletes the device document `users/{userId}/devices/{docId}`.
2. The user's active Firestore real-time subscriptions are cancelled via `RealtimeSubscriptionManager.instance.cancelAll()`.

---

## 3. Cloud Functions Backend Triggers

Located in `functions/src/index.ts`.

### 3.1 `onComplaintStatusChanged`
- **Trigger**: `functions.firestore.document('complaints/{complaintId}').onUpdate`
- **Status Diffing**: Compares `before.data().status` with `after.data().status`. Exits immediately if status is unchanged (e.g. citizen upvote or minor field edit).
- **Idempotency**: Computes deterministic event identifier `sourceEventId = status_${complaintId}_${newStatus}_${updatedAtMillis}`.
- **Deterministic Notification ID**: `notif_${complaintId}_${newStatus}_${updatedAtMillis}` prevents duplicate writes on function retries.
- **Lifecycle Mapping**:
  - `verified` $\rightarrow$ `NotificationType.complaintVerified` ("Complaint Verified")
  - `assigned` $\rightarrow$ `NotificationType.complaintAssigned` ("Officer Assigned")
  - `inProgress` $\rightarrow$ `NotificationType.complaintStatusChanged` ("Work In Progress")
  - `resolved` $\rightarrow$ `NotificationType.complaintResolved` ("Grievance Resolved")
  - `rejected` $\rightarrow$ `NotificationType.complaintStatusChanged` ("Complaint Update")
- **FCM Push Dispatch**: Sends multicast payload to all tokens found in `users/{citizenId}/devices`.
- **Stale Token Garbage Collection**: Inspects failed tokens in `sendEachForMulticast` response. If error is `messaging/registration-token-not-registered`, `messaging/invalid-registration-token`, or `messaging/mismatched-credential`, automatically executes a batch delete from `users/{citizenId}/devices`.

### 3.2 `onComplaintCreated`
- **Trigger**: `functions.firestore.document('complaints/{complaintId}').onCreate`
- **Action**: Writes `complaintSubmitted` notification to Firestore and dispatches initial confirmation push with ticket number (`CF-2026-XXXXXX`).

---

## 4. Mobile Client Push & In-App Routing Architecture

### 4.1 Top-Level Background Message Handler
Located in `lib/core/firebase/messaging/background_message_handler.dart`:
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await FirebaseInitializer.initialize();
  }
  debugPrint('[CivicFix FCM Background] Message received: ${message.messageId}');
}
```
Registered in `main.dart` after `FirebaseInitializer.initialize()`.

### 4.2 App Lifecycle States & Deep Linking

| App State | Event Trigger | Behavior |
|---|---|---|
| **Foreground** | `FirebaseMessaging.onMessage` | Non-blocking floating snackbar banner (`MockNotificationService.showInAppAlert`) displayed with "VIEW" action button. Does NOT duplicate Firestore doc. |
| **Background (Tapped)** | `FirebaseMessaging.onMessageOpenedApp` | `NotificationService.handleNotificationNavigation` parses `complaintId` / `targetRoute` and pushes route on `navigatorKey`. |
| **Terminated (Tapped)** | `FirebaseMessaging.getInitialMessage()` | `FirebaseNotificationService.initialize` evaluates initial message on post-frame callback and navigates to the target screen once router mounts. |

### 4.3 Deep Link Payload Format

```json
{
  "complaintId": "cmp_2026_000042",
  "ticketNumber": "CF-2026-000042",
  "status": "inProgress",
  "type": "complaintStatusChanged",
  "role": "citizen",
  "targetRoute": "/complaint-details",
  "click_action": "FLUTTER_NOTIFICATION_CLICK"
}
```

- If `targetRoute` is specified, navigates directly to named route.
- If `complaintId` is specified and `role == 'government'`, navigates to `AppRoutes.govtComplaintDetails`.
- If `complaintId` is specified and `role == 'citizen'`, navigates to `AppRoutes.complaintDetails`.
- Fallback route: `AppRoutes.notifications`.

---

## 5. Security Rules

Updated in `firestore.rules`:

```firestore
// User Devices Subcollection
match /users/{userId}/devices/{deviceId} {
  allow read, write: if isSignedIn() && isOwner(userId);
}

// Notifications Collection
match /notifications/{notificationId} {
  // Users can only access their own notifications
  allow read: if isSignedIn() && resource.data.userId == request.auth.uid;

  // Notifications are created server-side via Cloud Functions (Admin SDK)
  allow create: if false;

  // Users can only update their own isRead status
  allow update: if isSignedIn() &&
    resource.data.userId == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']) &&
    request.resource.data.isRead is bool;

  // Users can dismiss/delete their own notifications
  allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
}
```

---

## 6. Verification & Test Matrix

- **Cloud Functions Unit Tests** (`functions/test/notifications.test.js`):
  - Status content resolution and message mapping.
  - Token string sanitization.
  - Status transition diffing logic.
- **Flutter Notification Unit & Widget Tests** (`test/core/notifications/notification_service_test.dart`):
  - Service initialization and token generation.
  - User device registration & unregistration.
  - Simulated foreground and background push delivery.
  - Deep-link navigation routing across Citizen and Government screens.
- **FCM Lifecycle Integration Tests** (`test/core/notifications/fcm_lifecycle_integration_test.dart`):
  - Authentication flow device token registration and logout cleanup.
  - Foreground banner presentation.
  - Push tap deep link to 5-stage `ComplaintTrackerScreen`.
- **Static Analysis & Global Test Suite**:
  - `flutter analyze` $\rightarrow$ 0 warnings / 0 errors.
  - `flutter test` $\rightarrow$ 395 tests passing 100%.

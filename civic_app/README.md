# CivicFix — Citizen-Government Civic Redressal Platform

CivicFix is an offline-first, real-time civic grievance redressal and municipal engagement platform built with **Flutter**, **Hive**, and **Google Cloud Firebase**. It empowers citizens to report community issues (potholes, water leaks, broken streetlights, hazardous drains) with location geotagging and photographic evidence, while providing municipal government officers with a streamlined triage, verification, assignment, and resolution control console.

---

## Key Features

### 👤 Citizen Experience
- **Interactive Issue Reporting**: 4-step grievance wizard with category selection, GPS/manual map picker, camera/gallery evidence, and review.
- **Offline-First Resilience**: Report complaints offline; grievances are securely cached in Hive local storage and automatically synchronized when connectivity returns.
- **5-Stage Live Status Tracker**: Real-time reactive updates as complaints transition through *Reported* $\rightarrow$ *Verified* $\rightarrow$ *Assigned* $\rightarrow$ *In Progress* $\rightarrow$ *Resolved*.
- **Live Hazard GIS Map**: Interactive geotagged community map showing active public hazards and road conditions without exposing citizen personal data.
- **Automated Notifications**: Real-time in-app alerts and FCM push notifications with deep-link navigation directly to grievance trackers.
- **Civic Gamification & Rewards**: Earn points and unlock civic badges for community contributions.
- **Multilingual Support**: Full internationalization for English, Hindi, and Marathi.

### 🏛️ Government Portal
- **Executive Dashboard**: Key operational metrics, status breakdown, category distribution, and attention-required triage queues.
- **Grievance Triage & Verification**: Verify incoming citizen reports on-site or from the control room.
- **Department Dispatch & Assignment**: Allocate complaints to specialized maintenance squads across 9 municipal departments.
- **Status & Timeline Workflows**: Update grievance progress with official audit notes and resolution verification.
- **Analytics & SLA Performance**: Time trend charts, resolution efficiency statistics, and department workload tables.

---

## Technical Stack & Architecture

- **Frontend**: Flutter (Cross-platform Android, iOS, Web, Desktop)
- **Local Persistence & Cache**: Hive (`hive_flutter`) with 10 structured boxes and custom type adapters
- **Remote Backend**: Firebase (`civicfix-38d53`):
  - **Firebase Authentication**: Secure email/password authentication and role enforcement.
  - **Cloud Firestore**: Authoritative document store with security rules, compound indexes, and real-time snapshot streams.
  - **Firebase Cloud Storage**: Secure photographic evidence uploads with format and size validation.
  - **Firebase Cloud Messaging (FCM)**: Multi-device push notification delivery and deep linking.
  - **Cloud Functions**: Serverless triggers on Firestore status mutations for authoritative notification records and FCM dispatch.
- **Offline Sync Engine**: FIFO `HiveSyncQueue`, `SyncManager`, exponential backoff `RetryPolicy`, and `FirebaseSyncProvider`.

```text
Citizen UI / Government UI
          │
      Services
          │
     Repositories
     ├── Hive Local Storage (Instant reads & offline filing)
     └── Firebase Remote Data Sources (Authoritative source of truth)
              │
          SyncManager (FIFO Queue + Exponential Backoff)
              │
      FirebaseSyncProvider
          ├── Cloud Firestore (Real-time snapshots)
          ├── Firebase Storage (Evidence images)
          ├── Cloud Functions (Automated status diffing)
          └── Firebase Cloud Messaging (Push delivery)
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.11.3 or higher)
- [Node.js](https://nodejs.org/) (v18 or higher) for Cloud Functions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the Application
You can run the app in two modes:

#### A. Fast Mock Mode (Default for Local Development & Offline Preview)
Runs completely in-memory with preloaded realistic civic data without requiring active Firebase credentials:
```bash
flutter run
```

#### B. Production Firebase Mode
Connects directly to the active Firebase project (`civicfix-38d53`):
```bash
flutter run -d chrome # or -d android / -d windows
```

---

## Testing & Quality Assurance

### Run Flutter Unit, Widget & Integration Tests
CivicFix includes **400 automated tests** covering models, local storage, repositories, real-time synchronization, UI widgets, and end-to-end multi-user workflows:
```bash
flutter test
```

### Run Static Analysis
```bash
flutter analyze
```

### Run Cloud Functions Backend Tests
```bash
cd functions
npm test
```

---

## Project Structure

```text
civic_app/
├── lib/
│   ├── core/                    # Core architecture & shared foundation
│   │   ├── auth/                # Authentication services & locator
│   │   ├── constants/           # Design tokens, colors, typography, spacing
│   │   ├── firebase/            # Firestore data sources, storage, & mappers
│   │   ├── local/               # Hive boxes, adapters, & storage service
│   │   ├── models/              # Domain models (Complaint, User, Category, etc.)
│   │   ├── notifications/       # FCM service, mock service, & service locator
│   │   ├── repositories/        # Offline-first & mock repositories
│   │   ├── routing/             # AppRouter, route definitions, & guards
│   │   ├── sync/                # SyncManager, SyncQueue, & FirebaseSyncProvider
│   │   └── widgets/             # Reusable UI component library
│   ├── User UI/                 # Citizen portal screens & widgets
│   ├── Govt UI/                 # Government administrative portal
│   └── main.dart                # Application startup orchestrator
├── functions/                   # Cloud Functions backend triggers & tests
├── resources/                   # Architecture & Firebase documentation
├── test/                        # Comprehensive test suite (400 tests)
├── firestore.rules              # Firestore security rules
├── storage.rules                # Storage security rules
└── pubspec.yaml                 # Package dependencies
```

---

## License
CivicFix is developed for modern municipal civic engagement and public service optimization.

# CivicFix — System Architecture

> Version: 1.0  
> Status: MVP Architecture  
> Project: CivicFix  
> Frontend: Flutter  
> Backend: Firebase  
> Primary Database: Cloud Firestore

---

# 1. Overview

CivicFix is a citizen-government civic engagement platform designed to make reporting, tracking, and managing civic issues more transparent and accessible.

The system consists of two primary interfaces:

1. Citizen Application
2. Government / Organization Dashboard

Both interfaces are implemented using Flutter and communicate with a shared Firebase backend.

The architecture follows the principle:

    One Flutter Project
            |
            +--------------------+
            |                    |
       Citizen UI           Government UI
            |                    |
            +---------+----------+
                      |
                 Shared Core
                      |
                 Firebase Backend

The citizen and government interfaces remain logically and structurally separated inside the Flutter project, while authentication, models, services, Firebase integration, utilities, and other reusable functionality are maintained inside the shared `core` layer.

---

# 2. Architectural Goals

The architecture is designed around the following goals:

- Maintain a single Flutter codebase.
- Keep Citizen UI and Government UI clearly separated.
- Centralize shared business and backend logic.
- Provide secure role-based access.
- Support real-time complaint tracking.
- Support offline complaint creation and synchronization.
- Support location-based civic reporting.
- Provide a Live Hazard Map.
- Support English, Hindi, and Marathi.
- Provide a multilingual civic assistant.
- Support basic gamification.
- Keep the MVP technically achievable.
- Make the system extensible for future versions.
- Avoid unnecessary architectural complexity during MVP development.

---

# 3. High-Level Architecture

The complete system can be represented as:

    +-------------------------------------------------------+
    |                       CivicFix                        |
    +-------------------------------------------------------+
                            |
              +-------------+-------------+
              |                           |
              v                           v
    +--------------------+       +--------------------+
    |    Citizen UI      |       |   Government UI    |
    |      Flutter       |       |    Flutter Web     |
    +--------------------+       +--------------------+
              |                           |
              +-------------+-------------+
                            |
                            v
                  +-------------------+
                  |    Shared Core    |
                  +-------------------+
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
       Firebase SDK    Local Storage   Location Services
             |
             v
    +--------------------------------------------+
    |             Firebase Backend              |
    +--------------------------------------------+
    |                                            |
    |  Firebase Authentication                   |
    |  Cloud Firestore                           |
    |  Firebase Storage                          |
    |  Cloud Functions                           |
    |  Firebase Cloud Messaging (FCM)            |
    |                                            |
    +--------------------------------------------+

---

# 4. Technology Stack

## 4.1 Frontend

Primary framework:

- Flutter

Primary language:

- Dart

Flutter is used for both:

- Citizen mobile application
- Government web dashboard

The same project can target:

- Android
- iOS
- Web

The MVP primarily focuses on the Citizen mobile experience and Government web dashboard.

---

# 5. Frontend Architecture

The Flutter application is divided into three major areas:

```text
lib/
│
├── User UI/
│
├── Govt UI/
│
└── core/

The separation is intentional.

Citizen-specific screens and widgets must remain inside:

lib/User UI/

Government-specific screens and widgets must remain inside:

lib/Govt UI/

Shared functionality belongs inside:

lib/core/
#6. Recommended Flutter Directory Structure
lib/
│
├── main.dart
│
├── User UI/
│   │
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── complaints/
│   │   ├── report_issue/
│   │   ├── hazard_map/
│   │   ├── profile/
│   │   ├── rewards/
│   │   └── assistant/
│   │
│   ├── widgets/
│   │
│   └── services/
│
├── Govt UI/
│   │
│   ├── screens/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── complaints/
│   │   ├── hazard_map/
│   │   ├── analytics/
│   │   └── profile/
│   │
│   ├── widgets/
│   │
│   └── services/
│
└── core/
    │
    ├── firebase/
    │
    ├── models/
    │
    ├── services/
    │
    ├── repositories/
    │
    ├── local/
    │
    ├── location/
    │
    ├── notifications/
    │
    ├── routing/
    │
    ├── localization/
    │
    ├── utils/
    │
    ├── constants/
    │
    └── widgets/

The exact subfolders may evolve during implementation, but the separation between:

User UI
Govt UI
core

must remain.

#7. Responsibility of Each Layer
###7.1 User UI

Responsible for citizen-facing functionality.

Examples:

Login / registration
Citizen home screen
Report civic issue
Complaint history
Complaint tracker
Complaint details
Live Hazard Map
Notifications
Profile
Rewards / points
Multilingual assistant

The User UI should not directly contain Firebase implementation details wherever possible.

Instead:

User UI
   |
   v
Shared Service / Repository
   |
   v
Firebase
#8. Government UI

Responsible for government and authorized organization functionality.

Examples:

Government login
Dashboard
Complaint management
Complaint details
Complaint assignment
Status updates
Live Hazard Map
Basic analytics
Profile

The Government UI should also communicate with Firebase through shared services/repositories.

#9. Shared Core

The core directory contains functionality that is shared by both interfaces.

Examples:

Firebase initialization
Authentication
Firestore services
Storage services
Cloud Functions integration
Notifications
Models
Repositories
Local database
Location services
Localization
Routing
Constants
Common utilities

The core layer should contain reusable logic rather than UI-specific implementation.

#10. Backend Architecture

Firebase is the primary backend platform for CivicFix.

The MVP backend consists of:

Firebase
│
├── Authentication
│
├── Cloud Firestore
│
├── Firebase Storage
│
├── Cloud Functions
│
└── Firebase Cloud Messaging
#11. Firebase Authentication

Firebase Authentication handles user authentication.

Supported roles:

Citizen
Government / Organization

Authentication should not rely only on the frontend to determine permissions.

The authenticated user's role must be securely associated with their account and enforced by Firebase security rules and backend validation.

#12. Role-Based Access

CivicFix uses role-based access control.

Conceptually:

                Authenticated User
                       |
              +--------+--------+
              |                 |
           Citizen           Government
              |                 |
          User UI           Govt UI

The role determines:

Which interface the user sees.
Which data the user can access.
Which operations the user can perform.

For example:

A citizen can:

Create complaints.
View their complaints.
View public hazard information.
View their rewards.

A government user can:

View assigned/relevant complaints.
Update complaint statuses.
Manage complaints.
Access government dashboard information.

A citizen must never be able to perform government-only operations merely by manipulating the client application.

Authorization must therefore be enforced using Firebase security rules and backend validation.

#13. Cloud Firestore

Cloud Firestore is the primary database.

Firestore stores structured application data including:

Users
Complaints
Complaint updates
Departments
Locations
Rewards / points
Notifications
Hazard information
#14. Proposed Firestore Structure

A high-level structure is:

users/
    {userId}

complaints/
    {complaintId}

complaints/
    {complaintId}/
        updates/
            {updateId}

departments/
    {departmentId}

hazards/
    {hazardId}

notifications/
    {notificationId}

rewards/
    {userId}

The exact schema may evolve during implementation, but relationships between these entities must remain clear.

#15. User Document

Example conceptual structure:

users/{userId}

{
    name,
    email,
    phone,
    role,
    preferredLanguage,
    profileImage,
    createdAt,
    points
}

Possible role values:

citizen
government

Additional government-specific information can include:

departmentId
organizationId
designation

where required.

#16. Complaint Document

A complaint represents a civic issue reported by a citizen.

Conceptual structure:

complaints/{complaintId}

{
    citizenId,
    title,
    description,
    category,
    imageUrls,
    latitude,
    longitude,
    address,
    departmentId,
    status,
    priority,
    createdAt,
    updatedAt,
    assignedTo,
    resolvedAt
}

The actual implementation may add or remove fields depending on MVP requirements.

#17. Complaint Updates

Complaint status history should be preserved.

Conceptual structure:

complaints/{complaintId}/updates/{updateId}

{
    status,
    message,
    updatedBy,
    timestamp
}

This allows CivicFix to display a chronological progress history.

Example:

Complaint Submitted
        |
        v
Complaint Verified
        |
        v
Department Assigned
        |
        v
Work Started
        |
        v
Issue Resolved
#18. Complaint Status Architecture

The internal complaint system may use more detailed statuses than those displayed to citizens.

The citizen-facing tracker should remain simple.

Citizen-facing stages:

1. Reported
2. Verified
3. Assigned
4. In Progress
5. Resolved

Internally, additional statuses can be used where necessary.

For example:

SUBMITTED
PENDING_VERIFICATION
VERIFIED
ASSIGNED
IN_PROGRESS
RESOLVED
CLOSED

The UI maps internal states into the simplified citizen tracker.

This prevents the citizen interface from becoming unnecessarily complicated.

#19. Complaint Lifecycle

The intended lifecycle is:

Citizen creates complaint
        |
        v
Complaint stored
        |
        v
Complaint verified
        |
        v
Complaint assigned to department
        |
        v
Government works on complaint
        |
        v
Status updated
        |
        v
Citizen receives update
        |
        v
Complaint resolved
#20. Real-Time Updates

Firestore real-time listeners can be used for complaint status updates.

Example:

Government changes status
          |
          v
       Firestore
          |
          v
   Real-time listener
          |
          v
     Citizen App
          |
          v
 Updated Complaint Tracker

This allows citizens to see status changes without manually refreshing the application.

#21. Firebase Storage

Firebase Storage is used for files associated with complaints.

Primary MVP use case:

Complaint images

Example:

Citizen
   |
   v
Take/select image
   |
   v
Firebase Storage
   |
   v
Image URL
   |
   v
Complaint document in Firestore

Firestore should store references/URLs rather than large image files directly.

#22. Cloud Functions

Cloud Functions provide backend-side logic that should not be trusted to the client.

Potential responsibilities:

Complaint-related automation
Notifications
Reward calculation
Data validation
Department assignment logic
Backend-triggered workflows
Processing events
Future chatbot integrations

For example:

Complaint created
       |
       v
Cloud Function
       |
       +----> Determine relevant department
       |
       +----> Create notification
       |
       +----> Update required metadata

Cloud Functions should be used whenever sensitive business logic should not be exposed to the client.

23. Firebase Cloud Messaging

Firebase Cloud Messaging (FCM) handles push notifications.

Possible notifications:

Complaint submitted
Complaint verified
Complaint assigned
Complaint status changed
Complaint resolved
Important civic/hazard alert

Basic flow:

Backend event
     |
     v
Cloud Function
     |
     v
FCM
     |
     v
Citizen / Government device
#24. Offline Architecture

CivicFix should support offline complaint creation.

The primary local storage technology is:

Hive

The purpose is to prevent complaint data from being lost when the citizen temporarily has no internet connection.

25. Offline Complaint Flow
Citizen creates complaint
        |
        v
Internet available?
       / \
     YES  NO
      |    |
      |    v
      |   Hive
      |    |
      |    v
      |  Pending
      |    |
      +----+
           |
     Internet returns
           |
           v
      Sync Manager
           |
           v
       Firebase
#26. Offline Data States

A locally stored complaint can have a synchronization state.

Example:

pending
syncing
synced
failed

The local record should contain enough information to retry synchronization safely.

#27. Synchronization

The synchronization process should:

Detect connectivity.
Identify pending complaints.
Upload required images.
Create the complaint in Firestore.
Mark the local complaint as synchronized.
Handle failures without deleting unsynchronized data.

Conceptually:

Hive
 |
 | pending complaints
 v
Sync Service
 |
 +----> Upload media
 |
 +----> Create Firestore document
 |
 +----> Confirm success
 |
 v
Mark synced
#28. Location Architecture

Location is a core part of CivicFix because civic complaints are generally tied to physical locations.

The application can use device location services to obtain:

Latitude
Longitude

The complaint can additionally store:

Address
Locality
Area information

Conceptual flow:

Device GPS
    |
    v
Location Service
    |
    v
Latitude + Longitude
    |
    v
Complaint

The user should have the ability to review the detected location before submitting a complaint.

#29. Live Hazard Map

CivicFix includes a Live Hazard Map.

The map is available to:

Citizens
Government users

The map can display location-based civic hazards/issues.

Examples:

Road damage
Waterlogging
Open manholes
Garbage accumulation
Other relevant civic hazards

The exact categories can be expanded later.

#30. Hazard Map Architecture
Citizen Reports
      |
      v
Firestore
      |
      v
Hazard Data
      |
      v
Live Hazard Map
      |
 +----+----+
 |         |
 v         v
Citizen   Government
   UI         UI

The map should use geographic coordinates stored with complaints/hazard records.

#31. Multilingual Architecture

CivicFix supports:

English
Hindi
Marathi

Localization should be designed so that UI text is not hard-coded directly into screens.

Conceptually:

User Preference
      |
      v
Localization System
      |
 +----+----+----+
 |         |    |
English   Hindi Marathi

The preferred language can be stored in the user's profile.

#32. Multilingual Assistant

CivicFix includes a basic multilingual civic assistant.

The assistant should support:

English
Hindi
Marathi

Initial responsibilities include helping citizens understand the platform and civic reporting process.

Example interactions:

How do I report an issue?
Where can I report this problem?
What does this complaint status mean?
Which department handles this issue?
How can I track my complaint?

The assistant architecture should remain modular so that a more advanced AI/NLP backend can be introduced later without rebuilding the entire application.

#33. Gamification Architecture

CivicFix includes basic gamification to encourage civic participation.

The MVP focuses on simple mechanisms rather than a complex gaming system.

Possible components:

Citizen
   |
   v
Civic Participation
   |
   v
Points
   |
   +----> Progress
   |
   +----> Achievements
   |
   +----> Recognition

Points can be associated with legitimate civic participation activities.

The reward system must avoid encouraging spam or duplicate complaints.

#34. Reward Data

A conceptual reward record:

rewards/{userId}

{
    points,
    achievements,
    updatedAt
}

The exact reward rules should be defined in the MVP specification.

Sensitive reward calculations should be validated server-side where necessary.

#35. Notifications Architecture

Notifications can originate from:

Complaint status changes
Complaint assignment
Complaint resolution
Important civic alerts

Architecture:

Firestore / Backend Event
          |
          v
    Cloud Function
          |
          v
         FCM
          |
          v
      User Device
#36. Repository Layer

Firebase access should preferably be abstracted through repositories/services.

Example:

UI
 |
 v
ComplaintRepository
 |
 v
Firebase / Local Storage

Instead of:

UI
 |
 +---- Firebase calls
 +---- Hive calls
 +---- Storage calls
 +---- Notification calls

This separation makes the application easier to test and maintain.

#37. Example Repository Responsibilities
ComplaintRepository

Responsible for:

Creating complaints
Fetching complaints
Updating complaints
Listening for real-time updates
Synchronization
Complaint history
UserRepository

Responsible for:

User information
Profile information
Preferred language
Role information
RewardRepository

Responsible for:

Points
Achievements
Reward information
HazardRepository

Responsible for:

Hazard retrieval
Geographic filtering
Map-related data
#38. Routing Architecture

The application must determine the appropriate interface based on authentication and user role.

Conceptual flow:

Application Start
       |
       v
Firebase Auth
       |
       v
Authenticated?
     /     \
   No       Yes
   |         |
Login        v
         Check Role
          /     \
     Citizen   Government
        |          |
        v          v
    User UI     Govt UI

Unauthorized users must not be allowed to access protected screens simply by navigating directly to a route.

#39. Security Architecture

Security is a critical component of CivicFix.

Security must be enforced at multiple levels:

Flutter UI
    |
    v
Authentication
    |
    v
Role Verification
    |
    v
Firestore Security Rules
    |
    v
Cloud Functions / Backend Validation

The frontend must never be considered a trusted security boundary.

#40. Firestore Security Principles

At minimum:

Citizens

Citizens should generally be able to:

Read their own user profile.
Create their own complaints.
Read their own complaints.
Read appropriate public hazard information.
Access their own rewards.
Government Users

Government users should only be able to access data permitted by their role and department/organization.

They may:

Read relevant complaints.
Update authorized complaint fields.
Update complaint statuses.
Access government dashboard information.

Security rules should prevent unauthorized cross-user data access.

#41. Data Validation

Data validation should occur both:

Client-side
+
Server-side

Client-side validation improves user experience.

Server-side validation protects the backend.

Examples:

Required complaint fields
Valid status transitions
Authorized department actions
Valid user role
Valid ownership
Valid reward operations
#42. Data Flow — Citizen Complaint

Complete flow:

Citizen
   |
   v
Report Issue Screen
   |
   +----> Image
   |
   +----> Description
   |
   +----> Category
   |
   +----> Location
   |
   v
Complaint Service
   |
   v
Connectivity Check
   |
   +--------------------+
   |                    |
 Online               Offline
   |                    |
   v                    v
Firebase              Hive
   |                    |
   |                Pending Queue
   |                    |
   |                Sync Service
   |                    |
   +---------+----------+
             |
             v
         Firestore
             |
             v
     Government Dashboard
             |
             v
       Status Updates
             |
             v
          Citizen
#43. Data Flow — Government Status Update
Government User
      |
      v
Government Dashboard
      |
      v
Complaint Management
      |
      v
Update Status
      |
      v
Authorization Check
      |
      v
Firestore
      |
      +----------------+
      |                |
      v                v
Citizen Listener     Cloud Function
      |                |
      v                v
Tracker Updated       FCM
                       |
                       v
                  Notification
#44. Application State Management

The application should use a consistent state-management approach.

The exact package can be selected during implementation, but the architecture should separate:

UI State
Business State
Backend State
Local Sync State

The UI should not directly manipulate Firebase data everywhere.

A conceptual architecture is:

Screen
  |
  v
Controller / Provider / ViewModel
  |
  v
Repository
  |
  v
Data Source
  |
  +---- Firebase
  |
  +---- Hive
#45. Error Handling

Errors should be handled at appropriate layers.

Examples:

Network unavailable
Authentication failure
Permission denied
Image upload failure
Location unavailable
Firestore failure
Synchronization failure
Invalid complaint data

The application should show user-friendly messages rather than exposing raw Firebase exceptions.

Example:

Instead of:

FirebaseException: permission-denied

show:

You don't have permission to perform this action.
#46. Offline and Error Resilience

The system should prioritize preserving user-generated complaint data.

If synchronization fails:

Complaint
   |
   v
Hive
   |
   v
Sync Attempt
   |
   v
Failure
   |
   v
Keep Local Data
   |
   v
Retry Later

A failed synchronization must not silently delete the complaint.

#47. Image Handling

Complaint images should follow this process:

Camera / Gallery
       |
       v
Image Selection
       |
       v
Optional Compression
       |
       v
Upload
       |
       v
Firebase Storage
       |
       v
Download URL
       |
       v
Firestore Complaint Document

Image size and upload behavior should be optimized for mobile networks.

#48. Scalability Considerations

The MVP architecture should be simple but must allow future expansion.

Future possibilities include:

More departments
More government organizations
Multiple cities
State-level deployments
Advanced analytics
AI-based complaint categorization
Duplicate complaint detection
Automated department routing
Advanced chatbot
Predictive civic analytics
More languages
Public civic dashboards

The current architecture should not prevent these additions.

#49. Multi-Department Architecture

CivicFix should not be tied to a single department.

Conceptually:

CivicFix
   |
   +---- Roads
   |
   +---- Water
   |
   +---- Sanitation
   |
   +---- Electricity
   |
   +---- Waste Management
   |
   +---- Other Civic Departments

Departments are represented as backend entities.

Complaints can contain:

departmentId

which allows the system to route and filter complaints appropriately.

#50. Government Dashboard Architecture

The Government Dashboard should provide:

Government Dashboard
        |
        +---- Overview
        |
        +---- Complaints
        |
        +---- Complaint Details
        |
        +---- Status Management
        |
        +---- Live Hazard Map
        |
        +---- Basic Analytics
        |
        +---- Profile

The dashboard should prioritize operational clarity over unnecessary visual complexity.

#51. Citizen Application Architecture

The Citizen application should provide:

Citizen App
    |
    +---- Home
    |
    +---- Report Issue
    |
    +---- My Complaints
    |
    +---- Complaint Tracker
    |
    +---- Live Hazard Map
    |
    +---- Notifications
    |
    +---- Rewards
    |
    +---- Assistant
    |
    +---- Profile
#52. Complaint Tracker

The citizen-facing tracker should visually communicate progress.

Example:

[✓] Reported
 |
[✓] Verified
 |
[✓] Assigned
 |
[●] In Progress
 |
[ ] Resolved

The tracker is intentionally simplified compared with internal backend statuses.

#53. Public vs Private Data

CivicFix should distinguish between:

Private Data

Examples:

Citizen profile information
Personal contact information
Private complaint information
Internal government information
Public / Appropriate Civic Information

Examples:

Public hazard locations
General issue categories
Public civic alerts

Only information intended to be public should be exposed publicly.

#54. Architecture Principles

The following principles should be followed throughout development.

Principle 1 — Separation of Concerns

UI, business logic, data access, and backend services should remain separated.

Principle 2 — Shared Core

Common functionality must be implemented once and reused.

Principle 3 — Role-Based Security

Authorization must be enforced on the backend, not only in Flutter.

Principle 4 — Offline First for Critical User Input

A complaint should not disappear simply because connectivity is unavailable.

Principle 5 — Real-Time Where Useful

Complaint status changes should propagate quickly to the relevant users.

Principle 6 — MVP Simplicity

Do not introduce complex infrastructure unless the MVP requires it.

Principle 7 — Extensibility

The architecture should allow future features without major restructuring.

#55. MVP Scope Boundaries

The architecture intentionally does NOT require every possible CivicFix feature.

The MVP focuses on:

Authentication
Citizen complaint reporting
Government complaint management
Complaint tracking
Real-time status updates
Location-based complaints
Live Hazard Map
Offline complaint support
English/Hindi/Marathi support
Basic multilingual assistant
Basic gamification
Notifications
#56. Features Explicitly Deferred from MVP

The following are not required for the initial MVP:

Citizen feedback system
Complaint reopening by citizens
Complex reward economy
Advanced AI complaint classification
Predictive analytics
Advanced fraud detection
Large-scale multi-city infrastructure
Advanced government workflow automation
Complex social networking features

These can be considered for future versions.

#57. Deployment Architecture

The intended deployment model is:

                 CivicFix
                    |
          +---------+---------+
          |                   |
          v                   v
   Mobile Application    Government Web
          |                   |
          +---------+---------+
                    |
                    v
                Firebase

Citizen application:

Android / iOS

Government interface:

Flutter Web

Backend:

Firebase
#58. Development Environments

The project should support:

Development
    |
    v
Testing
    |
    v
Production

Firebase configuration should be handled carefully so development/testing data is not accidentally mixed with production data.

#59. Environment Configuration

Sensitive configuration values should not be hard-coded throughout the application.

Environment-specific configuration should be centralized.

The repository should never contain:

Private API keys
Service account credentials
Admin credentials
Secrets

in publicly accessible source code.

#60. GitHub Repository Structure

Recommended project structure:

CivicFix/
│
├── android/
├── ios/
├── web/
├── lib/
│
│   ├── User UI/
│   ├── Govt UI/
│   └── core/
│
├── test/
│
├── resources/
│   ├── Architecture.md
│   ├── MVP.md
│   ├── PRD.md
│   │
│   ├── Govt Design/
│   │   └── Design.md
│   │
│   └── User Design/
│       └── Design.md
│
├── assets/
│
├── pubspec.yaml
├── README.md
└── .gitignore
#61. Testing Architecture

Testing should be performed at multiple levels.

Unit Testing

Test:

Business logic
Repositories
Validation
Status mapping
Reward calculations
Synchronization logic
Widget Testing

Test:

Screens
Forms
Complaint tracker
Dashboard components
User interactions
Integration Testing

Test complete flows such as:

Login
  ↓
Report Complaint
  ↓
Store Complaint
  ↓
Government Receives Complaint
  ↓
Government Updates Status
  ↓
Citizen Receives Update
#62. Security Testing

Security testing should verify:

Citizens cannot access other citizens' private data.
Citizens cannot access government-only operations.
Government users cannot access unauthorized departments/data.
Unauthorized users cannot access protected screens/data.
Firestore rules reject invalid operations.
Storage access is restricted appropriately.
#63. Performance Considerations

The MVP should optimize:

Firestore reads
Image sizes
Map data loading
Real-time listeners
Mobile network usage
Offline synchronization
Dashboard queries

The application should avoid unnecessary real-time listeners and database reads.

#64. Data Consistency

The system should treat Firestore as the primary source of truth for synchronized server data.

Hive acts as a local persistence and synchronization mechanism.

Conceptually:

                 Server State
                      |
                  Firestore
                      |
          +-----------+-----------+
          |                       |
      Citizen UI              Govt UI
          |
        Hive
    Local Offline State

When offline:

Hive = temporary local source for pending operations

Once synchronized:

Firestore = authoritative server state
#65. Future Architecture Evolution

As CivicFix grows, the architecture can evolve without changing the core concept.

Possible future architecture:

                  CivicFix
                     |
        +------------+------------+
        |                         |
   Citizen Apps             Government Apps
        |                         |
        +------------+------------+
                     |
                 API Layer
                     |
        +------------+------------+
        |            |            |
      Auth       Complaint     Analytics
                   Service
        |            |            |
        +------------+------------+
                     |
              Distributed Backend

However, this level of backend separation is intentionally unnecessary for the MVP.

Firebase provides enough functionality to validate the product before introducing additional infrastructure.

#66. Architectural Decision Summary
Area	Decision
Frontend	Flutter
Citizen Platform	Flutter Mobile
Government Platform	Flutter Web
Codebase	Single Flutter Project
Citizen UI	lib/User UI/
Government UI	lib/Govt UI/
Shared Logic	lib/core/
Authentication	Firebase Authentication
Database	Cloud Firestore
File Storage	Firebase Storage
Backend Logic	Cloud Functions
Notifications	Firebase Cloud Messaging
Offline Storage	Hive
Location	Device GPS / Location Services
Maps	Live Hazard Map
Languages	English, Hindi, Marathi
Assistant	Multilingual civic assistant
Gamification	Basic points/achievements
Complaint Tracking	Real-time
Security	Firebase Security Rules + backend validation
Citizen Feedback	Deferred
Citizen Reopen	Deferred
Deployment	Mobile + Flutter Web
Primary Backend	Firebase
#67. Final Architecture

The final MVP architecture can be summarized as:

                         CIVICFIX
                            |
             +--------------+--------------+
             |                             |
             v                             v
      +-------------+               +-------------+
      |  CITIZEN UI |               |   GOVT UI   |
      |   Flutter   |               | Flutter Web |
      +------+------+               +------+------+
             |                             |
             +--------------+--------------+
                            |
                            v
                    +---------------+
                    |  SHARED CORE  |
                    +-------+-------+
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
   Repositories       Local Storage       App Services
        |                   |                   |
        |                  Hive                 |
        |                                       |
        +-------------------+-------------------+
                            |
                            v
                    +---------------+
                    |    FIREBASE   |
                    +---------------+
                            |
       +--------------------+--------------------+
       |                    |                    |
       v                    v                    v
 Firebase Auth         Firestore             Storage
       |                    |                    |
       |                    +---------+----------+
       |                              |
       |                         Cloud Functions
       |                              |
       |                              v
       |                             FCM
       |                              |
       +------------------------------+
                            |
                            v
                  Notifications / Updates


                 ADDITIONAL SERVICES
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
       Location       Hazard Map    Multilingual
       Services                     Assistant
                         |
                         v
                    Gamification
#68. Core Architectural Statement

CivicFix follows a single-codebase, dual-interface, shared-core architecture.

The Citizen UI and Government UI remain separately organized within the Flutter application, while shared functionality is centralized in the core layer.

Firebase provides authentication, database, storage, backend functions, and notifications. Hive provides local persistence for offline complaint creation and synchronization.
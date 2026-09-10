# CivicFix — Firebase Authentication & Role Integration Architecture

> **Version**: 1.0  
> **Status**: Completed (Prompt 7)  
> **Target Project**: `civicfix-38d53` (CivicFix)  
> **Core Principle**: Secure identity anchoring via Firebase Auth UID across Cloud Firestore, Hive local cache, and domain models, with strict client-side anti-tampering and server-authoritative role verification.

---

## 1. Architectural Overview

CivicFix separates authentication concerns cleanly between domain interfaces, production Firebase implementations, and deterministic in-memory mocks:

```text
               ┌───────────────────────────────┐
               │    AuthService Locator        │
               │   (Active Provider Switch)    │
               └───────────────┬───────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
  ┌───────────────────┐                 ┌───────────────────┐
  │  Citizen Auth     │                 │  Government Auth  │
  │  (AuthService)    │                 │ (GovtAuthService) │
  └─────────┬─────────┘                 └─────────┬─────────┘
            │                                     │
   ┌────────┴────────┐                   ┌────────┴────────┐
   ▼                 ▼                   ▼                 ▼
FirebaseAuth-   MockAuth-            FirebaseGovt-     MockGovt-
   Service       Service              AuthService       AuthService
   │                                     │
   ├── FirebaseAuth.instance             ├── FirebaseAuth.instance
   ├── FirebaseUserDataSource            ├── FirebaseUserDataSource
   └── HiveUserRepository                └── Token Custom Claims
```

---

## 2. Identity Mapping & Canonical UID

1. **Firebase UID**: When a user registers or logs in, Firebase Authentication generates an immutable `uid`.
2. **Firestore Canonical Document**: Profile document is strictly keyed at `/users/{uid}`.
3. **Domain Models**:
   - Citizen: `UserModel.id == uid`
   - Government: `GovtUserModel.id == uid`
4. **Complaint Ownership**:
   - `ComplaintModel.citizenId == uid`
   - Firestore Security Rules enforce `request.resource.data.citizenId == request.auth.uid`.
5. **Local Cache Safety**:
   - `HiveUserRepository.cacheUser(user)` persists non-sensitive profile attributes (`fullName`, `email`, `phone`, `civicPoints`, `badges`, `wardNumber`, `languageCode`).
   - Passwords, access tokens, and refresh tokens are **NEVER** stored in Hive boxes.

---

## 3. Role Resolution & Anti-Tampering Matrix

| Dimension | Citizen Flow | Government Flow |
| :--- | :--- | :--- |
| **Registration Mechanism** | Self-serve in-app via `FirebaseAuthService.register()` | Provisioned via Municipal Admin / Console |
| **Enforced Role Field** | Strictly `role: 'citizen'` | Verified `role: 'government'` or `'admin'` |
| **Firestore Write Rule** | `request.resource.data.role == 'citizen'` (Cannot self-assign `government`) | Protected document; updates require administrative permissions |
| **Authorization Check** | Allowed if valid Firebase Auth token | Verified via custom claims (`token.role == 'government'`) OR Firestore `/users/{uid}` with `role == 'government'` |
| **Tampering Defense** | Attempts to pass `role: 'government'` in citizen registration fail both in client mapper and Firestore security rules | Non-government credentials signing in to Government Portal are immediately signed out with access denied error |

---

## 4. Authentication Error Mapping

All Firebase authentication exceptions are intercepted by `FirebaseAuthErrorHandler` and converted into clear, user-actionable messages:

| Firebase Error Code | User-Facing Message |
| :--- | :--- |
| `user-not-found` / `wrong-password` / `invalid-credential` | "Incorrect email or password. Please verify your credentials." |
| `email-already-in-use` | "An account with this email address already exists. Please login instead." |
| `invalid-email` | "Please enter a valid email address format." |
| `weak-password` | "The password is too weak. Please use at least 8 characters with letters and numbers." |
| `user-disabled` | "This account has been disabled. Please contact municipal support." |
| `too-many-requests` | "Too many unsuccessful attempts. Access has been temporarily locked. Please try again later." |
| `network-request-failed` | "Network connection unavailable. Please check your internet connection and try again." |
| `government-access-denied` | "Access denied. This account does not possess authorized Municipal Government Officer credentials." |

---

## 5. Session Lifecycle & Navigation Protection

1. **Cold Start & Splash Screen**:
   - `SplashScreen` triggers `AuthService.checkAuthState()`.
   - If authenticated, navigates directly to `AppRoutes.home` (or Government Dashboard).
   - If unauthenticated, navigates to `AppRoutes.login`.
2. **Protected Government Routes**:
   - `AppRouter` wraps all `/govt/*` operational endpoints with `_protectedGovtRoute()`.
   - Evaluates `AuthServiceLocator.govtAuth.isAuthenticated`.
   - Redirects unauthenticated requests to `AppRoutes.govtLogin`.
3. **Session Termination**:
   - Logout invokes `FirebaseAuth.instance.signOut()`.
   - Clears in-memory user notifiers and resets state to `unauthenticated`.

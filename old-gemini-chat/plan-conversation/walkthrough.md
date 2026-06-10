# Walkthrough — Jarvis Life Operating System

We have successfully rebuilt and transitioned the **Jarvis** personal operating system to **Feature-Based Clean Architecture**, implemented the **Firebase backend** (Anonymous Authentication, Cloud Firestore, Firebase Cloud Messaging), and added support for **Mobile First and Widescreen Responsive Web Design**.

---

## Technical & Architectural Upgrades

### 1. Feature-Based Clean Architecture Restructuring
All features inside the codebase have been migrated to the standard Domain/Data/Presentation separation layers:
- **Auth Feature** (`lib/features/auth/`): Secure Anonymous Authentication via Firebase Auth.
- **Tasks/Focus Feature** (`lib/features/tasks/`): Cloud-synced checklists and customizable tags.
- **Habits Feature** (`lib/features/habits/`): Track streak consistencies and daily atomic wins.
- **Mood Feature** (`lib/features/mood/`): Log daily check-ins and compute mood statistics.
- **Money Feature** (`lib/features/money/`): Track cloud-synced transactions, financial goals, and debts.
- **Memory Feature** (`lib/features/memory/`): Aggregate daily reviews, weekly summaries, and monthly stats.

### 2. Firebase Integration & Cloud Synchronization
- **Anonymous Session Handshake:** The application initiates anonymous authentication on boot (during the splash screen) to guarantee a secure session ID (`uid`).
- **Path Isolation:** All documents in Cloud Firestore are stored securely under `/users/{uid}/[collections]`, isolating user data.
- **Resilient Serialization:** Custom `fromJson` model factories handle both standard Firestore `Timestamp` objects and local/fallback `String` ISO datetimes safely.

### 3. Firebase Cloud Messaging (FCM)
- Configured [notification_service.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/services/notification_service.dart) to prompt for permissions on start.
- Captures and uploads device FCM registration tokens to `/users/{uid}/fcmToken` to target remote notifications.

### 4. Widescreen Responsive Web & Sidebar Rail Navigation
- **Responsive Layout Control:** In [app_scaffold.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/app_scaffold.dart), the viewport adapts dynamically based on screen bounds:
  - **Widescreen Desktop (>800px):** Renders a vertical sidebar navigation rail (left-aligned) themed in dark `AppColors.navBar` with the pulsing Jarvis AI Orb in the center, and constrains the active view to a centered `800px` container.
  - **Mobile Layout (<=800px):** Renders the mobile-first layout with the floating center Jarvis FAB and the bottom navigation bar.

---

## Verification & Build Success

### 1. Flutter Static Analysis
```bash
flutter analyze
```
- **Result:** `No issues found!` (completely clean codebase, all mismatched models and ambiguous type references resolved).

### 2. Web Production Build Packaging
```bash
flutter build web
```
- **Result:** Compiled successfully to a production-ready package in **126.3s** with zero warnings or errors.

---

## How to Run locally

To launch the application in Chrome development mode:
```bash
flutter run -d chrome
```

# Implementation Plan — Firebase Integration & Feature Based Clean Architecture

This plan details the transition of **Jarvis** from local Hive storage to a cloud-synced **Firebase** backend (Auth, Cloud Firestore, Firebase Cloud Messaging) using **Feature Based Clean Architecture** with **Responsive Web Support**.

---

## User Review Required

> [!IMPORTANT]
> **Firebase Project Credentials**: We will configure standard Firebase initialization. To connect to your specific Firebase project, you will need to add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files, or run `flutterfire configure`. We will provide a configurable `firebase_options.dart` stub.

---

## Architecture: Feature Based Clean Architecture

We will restructure the project from a mixed directory structure to a strict Feature Based Clean Architecture. Each feature folder (e.g. `lib/features/tasks`) will be structured as follows:

```
lib/features/tasks/
├── domain/
│   ├── entities/
│   │   └── task.dart
│   └── repositories/
│       └── task_repository.dart
├── data/
│   ├── models/
│   │   └── task_model.dart
│   ├── datasources/
│   │   └── task_remote_datasource.dart
│   └── repositories/
│       └── task_repository_impl.dart
└── presentation/
    ├── controllers/
    │   └── task_provider.dart
    ├── screens/
    │   └── focus_screen.dart
    └── widgets/
        └── task_card.dart
```

---

## Proposed Changes

### 1. Dependencies Setup
#### [MODIFY] [pubspec.yaml](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/pubspec.yaml)
- Add Firebase packages:
  - `firebase_core: ^2.27.0`
  - `cloud_firestore: ^4.15.5`
  - `firebase_auth: ^4.17.8`
  - `firebase_messaging: ^14.7.19`

### 2. Main Entry & Initialization
#### [MODIFY] [main.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/main.dart)
- Initialize Firebase Core instead of Hive:
  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```
#### [NEW] [firebase_options.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/firebase_options.dart)
- Create a standard configuration placeholder for Firebase on Android, iOS, and Web.

### 3. Core Network & Authentication Services
#### [NEW] [firebase_auth_service.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/services/firebase_auth_service.dart)
- Implement Anonymous login & basic profile tracking. Since Firestore secure rules require a logged-in user, anonymous authentication will be automatically triggered during splash/onboarding if no credentials exist.
- Link the Firebase Auth `uid` as the primary key for all Firestore documents to isolate user data.

---

### 4. Feature Restructuring (Clean Architecture)

We will migrate and restructure the existing features:

#### A. User & Authentication Feature
- **Domain**: `user.dart` entity, `user_repository.dart` interface.
- **Data**: `user_model.dart` (extends `User` entity, adds firestore serialization), `user_repository_impl.dart`, `user_remote_datasource.dart`.
- **Presentation**: `setup_screen.dart`, `onboarding_screen.dart`, `splash_screen.dart`.

#### B. Today Feature
- **Presentation**: `today_screen.dart` and dashboard sub-widgets.

#### C. Priorities (Tasks) Feature
- **Domain**: `task.dart` entity, `tag.dart` entity, repository interfaces.
- **Data**: `task_model.dart`, `tag_model.dart`, Firestore remote data source (reading/writing to `/users/{userId}/tasks` and `/users/{userId}/tags`).
- **Presentation**: `focus_screen.dart` (Priorities tab), Tag CRUD manager sheet.

#### D. Habits Feature
- **Domain**: `habit.dart` entity, repository interface.
- **Data**: `habit_model.dart`, Firestore remote data source (reading/writing to `/users/{userId}/habits`).
- **Presentation**: `focus_screen.dart` (Habits tab), add habit sheet.

#### E. Money Feature
- **Domain**: `transaction.dart` entity, `financial_goal.dart` entity, `debt.dart` entity, repository interfaces.
- **Data**: Models and remote data source for transactions, goals, and debts under `/users/{userId}/transactions`, `/users/{userId}/goals`, `/users/{userId}/debts`.
- **Presentation**: `money_screen.dart`, debt sections, transaction sheets.

#### F. Memory (Life Review) Feature
- **Domain**: `daily_memory.dart` entity, repository interface.
- **Data**: `daily_memory_model.dart` and remote data source reading aggregated records or generating daily summaries under `/users/{userId}/memories`.
- **Presentation**: `memory_screen.dart`, period toggles, trends sparkline.

---

### 5. Notification Service (FCM)
#### [NEW] [notification_service.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/services/notification_service.dart)
- Set up Firebase Cloud Messaging.
- Handle background and foreground notifications.
- Request permissions on iOS and Android.
- Save FCM device tokens under the user's Firestore profile for target pushes.

---

### 6. Responsive Web & Mobile First Layouts
- **Responsive Layout Constraints**: Ensure all feature dashboards (e.g. Today timeline, Focus checklists, Money logs) adapt gracefully to large screens.
- **Max Width Wrapper**: Wrap main viewports in a max-width container (e.g. `Center` with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 800))`) when run on Web/Desktop.
- **Responsive Navigation**: Render a sidebar/rail navigation menu on widescreen environments instead of the bottom navigation bar.

---

## Verification Plan

### Automated Tests
- Run code quality analysis:
  ```bash
  flutter analyze
  ```
- Run a production compilation check:
  ```bash
  flutter build web
  ```

### Manual Verification
- Deploy to Chrome: `flutter run -d chrome`.
- Test Firebase anonymous sign-in flow on setup.
- Verify that created tasks, habits, and transactions are synced in real-time with Firestore.
- Validate layout on wide desktop screens (max-width card alignments and responsive rails).

# Jarvis — Complete Project Architecture & File Documentation

This document provides a comprehensive, file-by-file breakdown of the **Jarvis Personal Operating System** codebase. The project is designed with **Feature-Based Clean Architecture**, using **Riverpod** for state management, **GoRouter** for routing, and a secure **Firebase** cloud-synced backend.

---

## 1. Directory Structure Overview

The codebase is organized into four main layers under the `lib/` directory:

```
lib/
├── core/             # Cross-cutting concerns (Themes, Spacing, Utilities, Services)
├── data/             # Shared data providers (StateNotifiers, Seed data)
├── features/         # Vertical feature modules (Auth, Tasks, Habits, Mood, Money, Memory, Onboarding, Today)
├── shared/           # Reusable UI widgets
├── app.dart          # Root widget and MaterialApp
└── main.dart         # App entry point & initialization
```

---

## 2. Core Modules (`lib/core/`)

These modules contain foundational elements, configuration parameters, global utility functions, and network-related services.

### Themes (`lib/core/theme/`)

#### 📄 [app_colors.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/theme/app_colors.dart)
- **Purpose**: Defines the absolute color palette for the Jarvis system.
- **Key Fields**:
  - `background` (`0xFFFFF5F0`) & `backgroundGradientEnd` (`0xFFFFE8E0`): Coral-tinted warm background.
  - `primary` (`0xFFE8847C`) & `primaryDark` (`0xFFD4635A`): Warm peach/coral primary accents.
  - `secondary` (`0xFFC4A0E8`): Soft lavender accent color.
  - `navBar` (`0xFF1A1A1A`): Near-black navigation background.
  - **Gradients**: `backgroundGradient` (vertical fade) and `jarvisButtonGradient` (pulsing peach-pink orb).

#### 📄 [app_typography.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/theme/app_typography.dart)
- **Purpose**: Configures the type scale of the application using **Plus Jakarta Sans** (migrated from default Inter).
- **Key Methods**:
  - `display()` (32px, bold), `h1()` (28px, bold), `h2()` (22px, semi-bold), `body()` (15px, regular), `caption()` (13px), `micro()` (11px). All accept custom text colors.

#### 📄 [app_spacing.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/theme/app_spacing.dart)
- **Purpose**: A centralized design spacing scale (padding, margins, shadows, and corner radiuses).
- **Key Fields**:
  - Spacing constants: `xs=4`, `sm=8`, `md=12`, `base=16`, `lg=20`, `xl=24`, `xxl=32`.
  - Radius constants: `card=28`, `button=16`, `bottomNav=32`.
  - Utility objects: `cardShadow` (subtle `0.06` opacity shadow), `screenPadding`, and `cardPadding`.

#### 📄 [app_theme.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/theme/app_theme.dart)
- **Purpose**: Formulates the global light standard theme (`ThemeData`) conforming to Material 3 guidelines. Sets up default styling for cards, buttons, inputs, AppBars, and bottom navigation controls.

---

### Services (`lib/core/services/`)

#### 📄 [notification_service.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/services/notification_service.dart)
- **Purpose**: Initializes Firebase Cloud Messaging (FCM), prompts permissions on Android/iOS, listens to token changes, and monitors push payloads.
- **Key Methods**:
  - `initialize()`: Sets up foreground/background stream handlers.
  - `saveCurrentToken()`: Commits current FCM registration tokens to the active user's Firestore path (`/users/{uid}/fcmToken`).

---

### Utilities & Constants (`lib/core/utils/` & `lib/core/constants/`)

#### 📄 [date_helpers.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/utils/date_helpers.dart)
- **Purpose**: Central calendar calculations.
- **Key Methods**:
  - `greeting()`: Returns Morning/Afternoon/Evening greetings based on local clock.
  - `formatDate()`: Conversational date formatter ("Today", "Yesterday", "Tomorrow", or "Mon, Jan 15").
  - `dateKey()`: Serializes DateTime objects safely to `yyyy-MM-dd` keys.

#### 📄 [currency_formatter.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/utils/currency_formatter.dart)
- **Purpose**: Formats monetary double amounts into the Indian Rupee system (e.g. `₹1,500` or compact values like `₹1.2L`, `₹2.5Cr`).

#### 📄 [id_generator.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/utils/id_generator.dart)
- **Purpose**: Quick UUID v4 string generator wrapping the `uuid` package.

#### 📄 [intent_detector.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/utils/intent_detector.dart)
- **Purpose**: Client-side Natural Language Processing (NLP) parser. Decodes input typed into the Jarvis Command Orb into command intents (e.g., extracting transaction amounts, priority levels, task dates, or habit names using regex matches).

#### 📄 [emoji_map.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/constants/emoji_map.dart)
- **Purpose**: Resolves keywords in task/transaction inputs to emojis (80+ definitions, e.g., 'rent' -> '🏠', 'coffee' -> '☕').

#### 📄 [quotes.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/core/constants/quotes.dart)
- **Purpose**: Quote repository returning deterministic quotes based on date indices (featuring Naval Ravikant, Warren Buffett, James Clear, etc.).

---

## 3. Data Providers (`lib/data/`)

### 📄 [user_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/user_provider.dart)
- **Purpose**: Exposes global authentication state and the current user profile. Binds the login flow to `AuthRepositoryImpl` and `AuthRemoteDataSource`.

### 📄 [task_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/task_provider.dart)
- **Purpose**: Manages active checklists and tag labels. Binds queries to Firestore databases under `/users/{uid}/tasks` and `/users/{uid}/tags`.

### 📄 [habit_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/habit_provider.dart)
- **Purpose**: Manages habit entities, computes completion streaks, and tracks completions.

### 📄 [mood_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/mood_provider.dart)
- **Purpose**: Manages daily mental vibes and statistical distribution charts.

### 📄 [money_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/money_provider.dart)
- **Purpose**: Exposes financial overview calculations (total income, monthly expenses, debt totals, goal progress).

### 📄 [memory_provider.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/providers/memory_provider.dart)
- **Purpose**: Aggregates calendar review snapshots by bridging the task, habit, mood, and money repositories.

### 📄 [seed_data.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/data/seed_data.dart)
- **Purpose**: Seeds Cloud Firestore with mock database entries on initial run (tasks, tags, habits, transactions, goals, and debts).

---

## 4. Shared UI Elements (`lib/shared/widgets/`)

- [app_scaffold.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/app_scaffold.dart): Root screen wrapper. Detects responsive viewport size to switch between:
  - **Widescreen Mode (>800px):** Vertical navigation rail on the left, centered max-width bounds (`800px`) screen stack on the right.
  - **Mobile Mode (<=800px):** Stack views with the floating Jarvis FAB and bottom nav bar.
- [bottom_nav_bar.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/bottom_nav_bar.dart): 4-tab styled dark menu bar featuring the center space allocation for the command orb.
- [jarvis_fab.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/jarvis_fab.dart): Floating center button that triggers the Jarvis command bar overlay.
- [jarvis_card.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/jarvis_card.dart): Rounded border card (`28px` corner radius) with subtle shadows.
- [jarvis_button.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/jarvis_button.dart): Press-scale animated button with loading states.
- [jarvis_chip.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/jarvis_chip.dart): Outlined or filled filter chips.
- [jarvis_input.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/jarvis_input.dart): Themed text input field with active border transitions.
- [section_header.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/section_header.dart): Section title on the left with a "See All" action on the right.
- [empty_state.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/empty_state.dart): Centered graphic container shown when no items are available.
- [toast_notification.dart](file:///C:/Users/Santhosh%20S/.gemini/antigravity/scratch/jarvis/lib/shared/widgets/toast_notification.dart): Custom in-app overlay toast with an **Undo** button (active for 7 seconds) and a dismiss close button.

---

## 5. Feature Architecture (`lib/features/`)

Every feature module is divided into a clean separation of layers:

### Auth / Profile
- **Domain**: `UserEntity`, `AuthRepository` interface.
- **Data**: `UserModel` (supporting `Timestamp` serialization), `AuthRemoteDataSource` (handles sign-in), and `AuthRepositoryImpl`.
- **Presentation**: `splash_screen.dart` (authenticates session on start), `onboarding_screen.dart`, and `setup_screen.dart`.

### Tasks (Focus — Priorities)
- **Domain**: `Task` & `Tag` entities, `TaskRepository` interface.
- **Data**: `TaskModel`, `TagModel`, `TaskRemoteDataSource` (connects to `/users/{uid}/tasks` and `/users/{uid}/tags`), and `TaskRepositoryImpl`.
- **Presentation**: `focus_screen.dart` (combined screen containing priorities tab with swipe check/delete actions, detail expansion, and custom Tag CRUD sheets).

### Habits (Focus — Habits)
- **Domain**: `Habit` entity, `HabitRepository` interface.
- **Data**: `HabitModel` (stores completion date strings), `HabitRemoteDataSource` (`/users/{uid}/habits`), and `HabitRepositoryImpl`.
- **Presentation**: `focus_screen.dart` (habits tab displaying streaks, insights, and weekly dot-grid consistency tables).

### Mood
- **Domain**: `MoodEntry` entity, `MoodRepository` interface.
- **Data**: `MoodEntryModel`, `MoodRemoteDataSource`, and `MoodRepositoryImpl`.
- **Presentation**: `mood_checkin_card.dart` and `mood_arc_selector.dart` (horizontal row of animated emoji selectors).

### Money
- **Domain**: `Transaction`, `FinancialGoal`, `Debt`, `DebtPayment` entities, and repository interfaces.
- **Data**: Models, `MoneyRemoteDataSource` (managing database collections for transactions, goals, and debts), and `MoneyRepositoryImpl`.
- **Presentation**: `money_screen.dart` (displays financial overview calculations, debt sections, and goal progress bars).

### Memory (Life Review)
- **Domain**: `DailyMemory` entity, `MemoryRepository` interface.
- **Data**: `DailyMemoryModel` and `MemoryRepositoryImpl` (bridges metrics from the other repository layers).
- **Presentation**: `memory_screen.dart` (period toggles, daily highlights, and monthly consistency metrics).

### Today (Command Center)
- **Presentation**: `today_screen.dart`. Hosts components in order:
  1. `GreetingHeader`: Greeting customized by time.
  2. `DailySummaryCard`: Progress totals at the top.
  3. `MoodCheckinCard`: Log daily vibe check.
  4. `TimelineSection`: Lists upcoming tasks/habits/debts sorted by time.
  5. `JarvisSuggestionsCard`: Contextual suggestions.
  6. `DailyQuoteCard`: Quote of the day at the bottom.

### Command Bar
- **Presentation**: `command_bar_overlay.dart` (blurred modal containing NLP intents, quick action chips, and a button to save parsed entities).

# IronLog

Personal iOS gym tracking app — SwiftUI + SwiftData, iOS 17+, fully local.

---

## Xcode Setup

1. **Create a new Xcode project**
   - Open Xcode → New Project → iOS → App
   - Product Name: `IronLog`
   - Bundle Identifier: `com.yourname.ironlog`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (check this box if available, or skip — we configure it manually)
   - Minimum Deployments: **iOS 17.0**

2. **Delete the generated boilerplate**
   - Delete the auto-generated `ContentView.swift` and `[AppName]App.swift`

3. **Add the source files**
   - Drag the entire `IronLog/` folder into your Xcode project navigator
   - When prompted: check "Copy items if needed", select "Create groups"

4. **Capabilities**
   - In your target → Signing & Capabilities → add **Push Notifications** and **Background Modes** (if you want background notification delivery)

5. **Build & Run**
   - Select an iPhone 17 Simulator (iOS 17+)
   - Cmd+R

The app will seed 26 exercises on first launch and route to onboarding.

---

## Project Structure

```
IronLog/
├── App/
│   ├── IronLogApp.swift          # SwiftData container + @main
│   ├── RootView.swift            # Routes to Onboarding or MainTabView
│   └── MainTabView.swift         # 4-tab navigation
│
├── Models/                       # SwiftData @Model classes
│   ├── Exercise.swift
│   ├── Program.swift
│   ├── SessionTemplate.swift     # + TemplateEntry
│   ├── QueuedSession.swift
│   ├── WorkoutLog.swift
│   └── SetLog.swift
│
├── Data/
│   ├── ExerciseLibrary.swift     # 26 seeded exercises with stable UUIDs
│   └── DataSeeder.swift          # Seeds on first launch
│
├── Services/
│   ├── ProgramGenerator.swift    # Builds templates + rolling queue
│   ├── ProgressionEngine.swift   # Overload, stall detection, PR detection
│   └── NotificationManager.swift # Schedules session reminders
│
├── Theme/
│   └── AppTheme.swift            # Colors, typography, spacing, modifiers
│
└── Views/
    ├── Onboarding/               # 6-step onboarding flow
    ├── Home/                     # HomeView — today's session
    ├── Session/                  # DailySessionView, ActiveWorkoutView, SessionCompleteView
    ├── Calendar/                 # CalendarView, QueueEditorView
    ├── Progress/                 # ProgressView (Charts + History), SessionHistoryDetailView
    ├── Settings/                 # SettingsView
    └── Shared/                   # ExerciseInfoSheet, ExerciseSwapView, DeloadPromptView, AbsencePromptView
```

---

## Build Phases Status

| Phase | Status | Description |
|-------|--------|-------------|
| 1 — Foundation | ✅ Complete | Models, exercise library, program generator, progression engine |
| 2 — Onboarding | ✅ Complete | 6-step flow, notification permission, program generation on confirm |
| 3 — Core Workout Loop | ✅ Complete | Home, Daily Session, Active Workout, Session Complete |
| 4 — Calendar & Queue | ✅ Complete | Monthly calendar, queue editor with drag-to-reorder |
| 5 — Supporting Screens | ✅ Complete | Exercise info, swap, deload prompt, progress charts, history, settings |
| 6 — Intelligence Layer | ✅ Complete | Progressive overload, stall detection, PR detection, absence detection, rotation signals |

---

## Key Design Decisions

- **All weight stored in lbs internally.** Settings → Units toggle converts display only.
- **Queue is sequential.** Missed sessions stay at position 1; they never auto-skip.
- **Nothing changes silently.** Deload, swap, and restart all require explicit user confirmation.
- **Calibration sessions 1 & 2** use hardcoded conservative starting weights from the PRD.
- **Deload weight** is computed at display time (50% of last logged weight, rounded to nearest 5 lbs) — not stored as a separate field.
- **Exercise IDs** are stable UUIDs defined as constants in `ExerciseLibrary` so they can be safely cross-referenced from templates, set logs, and chart selectors.

---

## Data Model Relationships

```
Program
  ├── scheduledDays: [Int]          (Weekday raw values)
  └── sessionTemplates: [SessionTemplate]
        └── entries: [TemplateEntry]
              └── exerciseID: UUID  (→ Exercise)

QueuedSession
  ├── sessionTemplate: SessionTemplate
  └── workoutLog: WorkoutLog?

WorkoutLog
  ├── queuedSession: QueuedSession?
  └── sets: [SetLog]
        └── exerciseID: UUID        (→ Exercise)
```

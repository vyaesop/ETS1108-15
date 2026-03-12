# Chrono UI (Flutter + SQLite)

This app recreates and extends the Dribbble-style calendar/task design and runs with a **local SQLite backend**.

## What this app is
A personal scheduling planner for meetings, calls, reminders, and timezone-aware day planning.

## Local backend
- Uses `sqflite` + `path`.
- Database file: `chrono_ui.db`.
- Tables:
  - `app_state` (onboarding status)
  - `profiles` (user profile/settings)
  - `events` (event records)
  - `event_attendees` (normalized attendee records)
- Seeds profile and starter events on first run.

## Phase 1 hardening
- Repository abstraction layer (`EventRepository`, `ProfileRepository`, `AppStateRepository`).
- Sqflite repository implementations to decouple state from persistence.
- Database lifecycle upgrades (`onUpgrade`, schema versioning, indexes).
- Guarded app-state operations with surfaced error messaging.

## Phase 2 improvements
- **Data normalization**: attendees moved to dedicated `event_attendees` table with migration logic.
- **Advanced search filters**: query by text (title/location/attendee), reminder-only mode, and date-range filtering.
- **Calendar correctness improvements**: month cards show event density badges based on real persisted data.
- **Validation hardening**:
  - Event form enforces required title and `end > start`.
  - Profile save enforces timezone format (`GMT+7`, `GMT-5`, etc.).

## Included user flows
- Onboarding (persisted)
- Today view (filter and empty states)
- Calendar board view
- Month overview grid
- Search flow with filters
- Event detail flow
- Create event flow (insert to SQLite)
- Edit event flow (update SQLite)
- Delete event flow (delete from SQLite)
- Profile/settings edit flow (save to SQLite)

## Run
```bash
flutter pub get
flutter run
```

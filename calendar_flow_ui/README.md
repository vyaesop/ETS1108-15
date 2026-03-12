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
  - `events` (full event CRUD)
- Seeds profile and starter events on first run.

## Phase 1 production hardening implemented
- Repository abstraction layer:
  - `EventRepository`
  - `ProfileRepository`
  - `AppStateRepository`
- Sqflite repository implementations to decouple app state from storage details.
- Database lifecycle improvements:
  - schema versioning (`v2`)
  - `onUpgrade` migration entrypoint
  - index creation migration (`idx_events_date`, `idx_events_start_minutes`)
- Guarded state operations with surfaced error messaging (`lastError`) for safer UI behavior.

## Included user flows
- Onboarding (persisted)
- Today view (filter and empty states)
- Calendar board view
- Month overview grid
- Search flow
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

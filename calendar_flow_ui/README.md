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
  - `focus_sessions` (focus timer logs)
  - `daily_stats` (daily productivity aggregates)
- Seeds profile and starter events on first run.

## Productivity planner (V1)
- Event duration support (`duration_minutes`) with default 30 minutes.
- Daily auto planner (`generateDailySchedule`) sequencing incomplete tasks from 09:00.
- Smart rollover of incomplete past events to today on startup.
- Focus timer sessions with persisted minute totals.
- Daily productivity stats for completed tasks and focus minutes.
- Today screen enhancements:
  - Today's Plan timeline
  - per-task focus start/stop
  - completion progress indicator

## Architecture pattern
Changes follow strict order:
1. database migration
2. repository interface
3. sqflite repository implementation
4. AppState integration
5. UI integration
6. tests

## Included user flows
- Onboarding (persisted)
- Today view (filters, cards, productivity timeline)
- Calendar board view
- Month overview grid
- Search flow with filters
- Event detail flow
- Create event flow (insert to SQLite)
- Edit event flow (update SQLite)
- Delete event flow (delete from SQLite)
- Profile/settings edit flow (save to SQLite)
- Reset app data flow

## Run
```bash
flutter pub get
flutter run
```


## UX notes
- A UX review summary and follow-up backlog is available at `docs/UX_AUDIT.md`.

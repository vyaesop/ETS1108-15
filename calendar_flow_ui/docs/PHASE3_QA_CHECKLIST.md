# Phase 3 QA Checklist (Flow-by-flow)

## Onboarding
- Launch app first time -> onboarding screen appears.
- Tap **Enter App** -> app opens home and persists onboarding.
- Reset data from profile -> onboarding appears again after reset.

## Home / Today
- Switch tabs: Today / Tomorrow / All.
- Open event details from a card.
- Tap `+` and create event; card appears and persists after restart.

## Create/Edit Event
- Title empty -> blocked with snackbar.
- End <= Start -> blocked with snackbar.
- Add attendees list -> persists and renders initials chips.
- Edit existing event from details -> changes persist.

## Event Detail
- Delete action requires confirmation.
- Cancel delete keeps event.
- Confirm delete removes event from list.

## Search & Filters
- Text query matches title, location, and attendees.
- Reminder-only filter narrows results.
- Date range filter narrows results.
- Clear range and Clear all reset filters.

## Month Overview
- Month cards show event count badges from persisted data.
- Mini calendar density highlight reflects month event count.
- Today icon returns to Today tab.

## Profile
- Save valid timezone (`GMT+7`) succeeds.
- Invalid timezone format blocked.
- Reset app data shows confirmation and restores seeds.

## Data / Persistence
- App uses SQLite tables: `events`, `event_attendees`, `profiles`, `app_state`.
- Migration path to v3 handles legacy attendee values.
- CI pipeline runs `pub get`, `analyze`, `test` on hosted runner.

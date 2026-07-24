# Demo Script — MVP User Journey

This follows Implementation Plan Section 4.2 exactly, since that section
is explicitly the acceptance test and the live demonstration script. Each
step notes what's real vs. seed data — say this out loud during the demo
rather than letting the evaluator assume otherwise.

## 1. Login and biometric unlock
- Open the app → Login screen (glass morphism panel over the ambient
  background).
- Enter any email/password → **this will fail against a real backend
  check** since no Auth API is connected yet; narrate that the JWT flow,
  token refresh interceptor, and secure storage are real and wired, only
  the endpoint is unconfirmed.
- Show "Unlock with Biometrics" button — will report unavailable in a
  simulator without biometric enrollment; real on a physical device with
  Face ID/Touch ID/fingerprint enrolled.

## 2. Dashboard
- Active course, active internship, today's tasks, upcoming deadlines,
  engineering score — **all composed from the Courses/Internship/
  Assignments repositories**, not hardcoded, but those repositories are
  themselves running on seed data. Say plainly: "the wiring is real, the
  data behind it is a placeholder."
- Tap the notification bell → Notification Center, showing unread badge.
- Tap "Live Learning" / "Portfolio" quick-access cards.

## 3. Course Management
- Open a course → real video playback (public sample video), real PDF
  viewer, lesson list with completion state.
- Scrub the video, background/foreground the app, come back — position
  persists (`updateLastPosition` → outbox → Hive cache).
- Add a note → appears instantly (optimistic write).
- Tap "Download for Offline" → downloads the video/PDF to local disk for
  real (Week 3/4 addition — Week 2's version only cached JSON).

## 4. Internship Portal
- Show the assigned case study (seeded with the FLUTR-002 brief itself —
  a deliberate touch, not filler).
- Check off a daily task.
- Submit a weekly report → appears in Submission History immediately as
  "Pending sync."

## 5. Assignment Management
- Open an assignment, pick a file via the file picker, optionally add a
  GitHub link, submit → appears as "Pending" in history.
- Point out the overdue/pending/evaluated status logic on the list
  screen.

## 6. Push notification → deep link
- **This step cannot be demonstrated live without a connected Firebase
  project.** Show the Notification Center's seed notifications instead,
  and tap one with a deep link (e.g. the assignment-deadline one) to show
  it navigating straight to that assignment — the deep-link mechanism is
  real, the "arrives as a push" part isn't connected yet.

## 7. Offline continuity
- Enable airplane mode.
- Open the downloaded course → video/PDF still play from local disk.
- Submit another weekly report or assignment while offline → it queues
  (offline indicator shows "N pending").
- Disable airplane mode → within ~15 seconds (the sync worker's periodic
  check) or immediately on the connectivity event, the indicator updates
  to reflect syncing, then clears once the (currently absent) backend
  would accept it. Narrate: "the retry/backoff logic is real and tested
  in isolation (see `test/core/offline/`); the successful round-trip to a
  server can't be shown today because there's no server."

## Talking points to have ready

- **What's genuinely done**: architecture, offline-first read/write
  pipeline with real backoff, glass morphism design system, all 9 MVP
  screens, unit-tested domain logic.
- **What's seed data, not integration**: every list, score, and status —
  because none of the 6 outstanding API contracts (see README) have been
  confirmed.
- **What's deliberately out of scope**: Community, full Analytics, live
  session chat/recording, AI study plans, bonus challenges — all called
  out as Full-Scope Backlog in your own Implementation Plan Section 4.3,
  not things dropped without acknowledgment.
- **The one open risk worth stating in the room**: 4 weeks of feature
  work sit on unconfirmed API contracts. That's a real risk for the
  Business Logic and API Integration evaluation criteria, and it's on
  you/the client to close, not something more UI code fixes.

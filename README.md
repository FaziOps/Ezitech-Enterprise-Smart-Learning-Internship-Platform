# Ezitech — Enterprise Smart Learning & Internship Platform

A Flutter-based enterprise learning and internship management platform, built as part of the Ezitech case study. This README reflects the real state of the project as of **Week 4 (finalization pass)** — what's working, what's seeded, and what's genuinely outstanding.

---

## Status

**Week 4 complete.** All 9 MVP modules are built. This week focused on bug fixes, a performance/accessibility/responsive pass, and the documentation and deployment artifacts required by the case study — deliberately no new features, so the project could be stabilized and honestly assessed before moving further.

> ⚠️ This project has **zero confirmed backend integrations**. Every module currently runs on seed/mock data. See [API Requirements](#api-requirements) below — this is the single biggest risk to the project and is called out on purpose, not buried.

---

## Documentation

| Doc | What's in it |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layer structure, module map, offline-first design, security notes, what's real vs. seed data |
| [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) | Glass morphism design tokens, components, accessibility notes |
| [`docs/STATE_MANAGEMENT.md`](docs/STATE_MANAGEMENT.md) | Riverpod patterns used and where |
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | Exact steps to generate native scaffolding, sign an Android build, and configure iOS |
| [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) | Step-by-step live demo script, annotated with what's real vs. seeded |
| [`docs/DELIVERABLES_CHECKLIST.md`](docs/DELIVERABLES_CHECKLIST.md) | Honest done/not-done status against the case study's deliverables list |
| [`docs/presentation/Ezitech_Technical_Presentation.pptx`](docs/presentation/Ezitech_Technical_Presentation.pptx) | Technical presentation deck |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | `flutter analyze` + `flutter test` on every PR |

---

## What's Built (9 MVP Modules)

The app ships with the following modules, all UI-complete and running on seed data:

1. Authentication (login, refresh, logout, sessions)
2. Dashboard
3. Course Management
4. Internship Portal
5. Assignment Management
6. Live Learning
7. Engineering Portfolio
8. AI Learning Assistant
9. Notifications

---

## Week 4 Changes

### Bug Fixes
- Fixed bottom navigation incorrectly highlighting **Dashboard** when on screens with no matching tab (Notifications, Live, Portfolio).
- Removed a redundant Hive adapter registration in `main.dart` that could have thrown on a future refactor.
- Removed a dead provider left over from Week 2's dashboard rewrite.

### Performance
- The ambient background's continuously-animating blobs are now wrapped in a `RepaintBoundary`, so that animation no longer forces repaints of the glass panels and content sitting on top of it.

### Accessibility
- Icon-only buttons (back arrows, password visibility toggle, send buttons) now have `tooltip` set.
- **Documented, left honestly unverified**: text-scale behavior and screen-reader navigation order need a real device pass — not something checkable without one.

### Responsive Layout
- Courses, Assignments, Internship, Live, and Portfolio screens now cap content width on tablets via a new `ResponsiveCenter` wrapper. Previously only the Dashboard had tablet treatment.

---

## What Is *Not* Done (Stated Plainly)

- **No signed Android APK. No iOS build.** There is no native `android/` or `ios/` scaffolding in this repo — `flutter create` has never been run (no SDK in the build environment used so far). There is correctly no signing keystore included; that's the project owner's to generate, never something to fabricate. `docs/DEPLOYMENT.md` walks through generating both in roughly 20 minutes in a real Flutter environment.
- **`flutter analyze` and `flutter build` have never been run against this code.** Everything has been hand-reviewed as carefully as possible, and the domain-layer test suite (`flutter test`) is real and traced by hand — but "reviewed carefully" and "compiler-confirmed" are different claims. Run `flutter analyze` before trusting this further.
- **Zero real backend integrations.** Four weeks of features sit on unconfirmed API assumptions. See [`docs/DELIVERABLES_CHECKLIST.md`](docs/DELIVERABLES_CHECKLIST.md) for the full accounting.

---

## API Requirements

None of the following APIs have been provided or confirmed across 4 weeks of development. This table is the complete, current list (previous weekly updates summarized this down to "see Week 1," which became useless — this is the full restore).

| # | API | Used By | What's Needed |
|---|---|---|---|
| 1 | Ezitech Auth API | Login, refresh, logout, sessions | Base URL, and confirmation/correction of guessed response field names (`access_token` / `refresh_token` / `user`) |
| 2 | Ezitech LMS API | Course Management, Dashboard | Course list/detail, video stream URLs, PDF URLs, notes CRUD, progress read/write |
| 3 | Internship Portal API | Internship Portal | Case studies, daily tasks, weekly report submission, mentor feedback |
| 4 | Assignment Management API | Assignment Management | Assignment detail, multipart file upload endpoint, deadlines, evaluation results |
| 5 | GitHub API | Internship & Assignment GitHub submission | Decision needed: OAuth flow vs. plain pasted repo URL (no API call) |
| 6 | Live Session / Video Conferencing API | Live Learning | Provider decision (Zoom / Jitsi / Agora / plain link) — determines external-link vs. embedded SDK |
| 7 | Video Streaming API / CDN | Video playback | Signed URLs? DRM? Plain HTTPS? |
| 8 | Socket.IO / WebSocket server | Real-time chat/notifications (Full-Scope Backlog item, not yet built) | Namespace/event spec, once prioritized |
| 9 | Firebase project | Push notifications | `google-services.json` + `GoogleService-Info.plist` |
| 10 | AI Assistant backend | AI Learning Assistant | Proxy to a hosted LLM, or direct provider call — determines where the API key lives |
| 11 | Analytics/Portfolio data API | Engineering Portfolio, future Analytics module | Likely the same LMS API as #2 — needs confirmation |

**35% of the stated evaluation weight (Business Logic 20% + API Integration 15%) rests on API contracts nobody has confirmed yet.** Before any further feature work (Community, Analytics, etc.), the recommendation is to verify one real integration end-to-end. Continuing to build on seed data is a legitimate call — but it should be made on purpose, not by default.

---

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod (see [`docs/STATE_MANAGEMENT.md`](docs/STATE_MANAGEMENT.md))
- **Local Storage**: Hive
- **Design**: Glass morphism design system (see [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md))
- **CI**: GitHub Actions running `flutter analyze` + `flutter test` on every PR

---

## Getting Started

```bash
# Clone the repo
git clone <your-repo-url>
cd ezitech

# Install dependencies
flutter pub get

# Run static analysis (has not yet been run in this build environment — do this first)
flutter analyze

# Run the domain-layer test suite
flutter test

# Run the app
flutter run
```

> Note: Since `flutter create` has never been run in this environment, native `android/` and `ios/` folders do not yet exist. Follow [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) to generate native scaffolding and produce a signed Android build / configured iOS build.

---

## Project Structure

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full layer structure and module map, including an explicit breakdown of what's real logic versus what's currently backed by seed data.

---

## Contributing / Next Steps

Before further feature work:

1. Pick **one** API from the [API Requirements](#api-requirements) table and integrate it end-to-end (real network calls, real error states, real loading states).
2. Run `flutter analyze` and fix anything it surfaces.
3. Do a real-device accessibility pass (text scaling, screen-reader navigation order).
4. Generate native scaffolding and produce a signed build per `docs/DEPLOYMENT.md`.

---

## License

*(Add your license here.)*

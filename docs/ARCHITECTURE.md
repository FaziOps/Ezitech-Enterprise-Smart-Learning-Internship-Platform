# Architecture

This document is written so a new engineer can understand the codebase
without a verbal walkthrough — that's an explicit Definition of Done
requirement, not just good practice.

## Layering

Every feature under `lib/features/<name>/` follows the same three-layer
split:

```
<feature>/
  domain/         — pure Dart. No Flutter, Dio, or Hive imports.
    entities/     — plain data classes (Equatable, no JSON logic)
    repositories/ — abstract contracts (interfaces)
    usecases/     — single business actions, unit-testable with a fake repository
  data/           — implements the domain contracts
    models/       — entities + fromJson/toJson
    datasources/  — remote (Dio) and local (Hive) data access
    repositories/ — implements the domain repository, coordinates remote+local
  presentation/   — Flutter + Riverpod
    providers/    — DI wiring + state
    screens/      — full-page widgets
    widgets/      — feature-scoped reusable widgets
```

**Why this split, concretely, not just "it's Clean Architecture":** a
domain-layer use case (e.g. `LoginUseCase`, `SubmitAssignmentUseCase`) can
be unit-tested against a hand-written fake repository with zero network,
zero device, zero widget tree — see `test/features/auth/login_usecase_test.dart`
and `test/features/week2_usecases_test.dart`. That's the actual payoff;
everything else is organizational hygiene.

## Dependency direction

`presentation` depends on `domain` (via the abstract repository).
`data` depends on `domain` (implements the abstract repository).
`domain` depends on nothing feature-specific.

Riverpod providers in each feature's `presentation/providers/` file are
where the concrete `data` implementation gets bound to the abstract
`domain` contract — e.g. in `course_providers.dart`:

```dart
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(...); // concrete data-layer class
});
```

Everywhere else in the app, code depends on `CourseRepository` (the
interface), never `CourseRepositoryImpl` directly — except the one place
that needs the concrete download-path helpers
(`lib/features/courses/presentation/providers/course_providers.dart`'s
`_impl()` cast), which is called out in a comment explaining why that's
a deliberate, narrow exception rather than a pattern to copy.

## Module map

| Module | Status |
|---|---|
| Auth (JWT + biometric) | Built, Week 1 |
| Dashboard | Built, Week 1-2 (now composed from real repositories) |
| Course Management | Built, Week 2-3 (video/PDF, offline downloads) |
| Internship Portal | Built, Week 2 |
| Assignment Management | Built, Week 2 |
| Live Learning (schedule/join/attendance) | Built, Week 3 |
| AI Learning Assistant (chat) | Built, Week 3 (canned fallback, no real AI backend) |
| Engineering Portfolio (read-only) | Built, Week 3 |
| Notification Center (FCM) | Built, Week 3 (fails soft without Firebase project) |
| Community | Not built — Full-Scope Backlog per Implementation Plan 4.3 |
| Full Analytics module | Not built — Full-Scope Backlog |
| Live session chat/recording | Not built — explicitly Full-Scope Backlog |
| AI study plans/recommendations | Not built — explicitly Full-Scope Backlog |
| Multi-device session UI | Domain interface exists (`AuthRepository.listActiveSessions`/`revokeSession`), no screen built |
| Bonus challenges | Not built |

## Offline-first design

See `core/offline/`:

- **`OutboxItem` / `OutboxQueue`**: every write that should survive being
  offline (weekly reports, assignment submissions, lesson progress, notes,
  task toggles, live-session attendance) is enqueued here, keyed by a
  `payloadType` string, instead of being sent directly over Dio.
- **`SyncWorker`**: drains the queue on connectivity restore and on a 15s
  periodic timer, respecting per-item exponential backoff
  (`OutboxItem.nextRetryAt`, computed in `OutboxQueue.recordFailure`).
  Repositories register a handler per `payloadType` at provider
  construction — the worker itself never imports Dio or any repository.
- **`DownloadManager`**: separate from the outbox (it's a read-path
  concern, not a write queue) — fetches video/PDF files to local disk for
  the "Download for Offline" action, keyed by lesson id + asset type.

This is the mechanism described in Implementation Plan Section 3.3, and
it's genuinely offline for both reads (cached data, downloaded files) and
writes (outbox), not just one or the other.

## Security

- JWT access + refresh tokens in `flutter_secure_storage`
  (`core/storage/secure_storage_service.dart`) — Keychain-backed on iOS,
  encrypted SharedPreferences on Android. Never in Hive.
- `ApiClient`'s auth interceptor (`core/network/api_client.dart`) attaches
  the token to every request and retries once on 401 after a token
  refresh.
- Biometric unlock via `local_auth`
  (`features/auth/data/datasources/auth_local_datasource.dart`).
- Multi-session listing/revocation has a domain contract
  (`AuthRepository.listActiveSessions`/`revokeSession`) but no UI — Full
  Scope Backlog per the plan.

## What isn't real yet — read this before assuming otherwise

Every repository in this codebase follows the same pattern:
`try { call the real API } catch { fall back to cache, then to
hand-written seed data }`. This makes the entire app clickable and
demoable without any backend connected. It does **not** mean the API
integrations are correct — none of them have been verified against a real
endpoint, because none of the API contracts in the README's requirements
table have been confirmed. Treat every seed-data fallback as an assumed
contract, not a validated one, until it's been checked against a real spec.

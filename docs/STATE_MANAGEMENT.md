# State Management — Riverpod

Riverpod is used consistently across every module — no BLoC mixed in,
per the Implementation Plan's explicit instruction that mixing state
management approaches is out of scope for a 2-person team.

## The four patterns used, and when each applies

### 1. Plain `Provider` — dependency injection
For anything that's constructed once and handed down: API clients,
repositories, use cases, data sources.

```dart
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(
    ref.watch(courseRemoteDataSourceProvider),
    ref.watch(courseLocalDataSourceProvider),
    ref.watch(outboxQueueProvider),
    ref.watch(downloadManagerProvider),
  );
});
```

Notice the provider's declared type is the **abstract** `CourseRepository`,
not `CourseRepositoryImpl` — anything reading this provider only ever sees
the interface. This is what makes the domain layer's use cases fake-able
in tests.

### 2. `FutureProvider` (and `.family`) — one-shot async reads
For "fetch this and show it" — course lists, assignment details, chat
history load. Handles loading/error/data states via `.when(...)` in the
UI without manual `FutureBuilder` boilerplate.

```dart
final courseDetailProvider =
    FutureProvider.family<CourseDetailEntity, String>((ref, courseId) async {
  final result = await ref.watch(courseRepositoryProvider).getCourseDetail(courseId);
  return result.fold((failure) => throw failure.message, (detail) => detail);
});
```

### 3. `StateNotifierProvider` — state that changes over time from multiple triggers
Used where a `FutureProvider` re-read would cause visible flicker: auth
status (`AuthController`) and chat history (`ChatController`). The chat
controller in particular appends optimistically rather than re-fetching
the whole list on every message, so the UI doesn't flash empty-loading-data
on every send.

### 4. `StreamProvider` — ongoing external events
Connectivity status, sync worker status, incoming FCM notifications —
anything that's fundamentally a stream rather than a one-shot fetch.

## The offline-write pattern (used by every feature with a write action)

1. UI calls a repository method directly — e.g.
   `ref.read(courseRepositoryProvider).markLessonComplete(...)`.
2. The repository updates its local Hive cache synchronously and enqueues
   an `OutboxItem`, returning immediately — no `await` on any network call.
3. The UI calls `ref.invalidate(someProvider)` to force the relevant
   `FutureProvider` to re-read from the now-updated cache.
4. `SyncWorker`, running independently, drains the outbox in the
   background whenever a handler is registered for that payload type.

This means every "submit"/"save"/"mark complete" action in the app
follows the identical shape — once you've read one, you've read them all.

## Eager provider registration at startup

Riverpod providers are lazy by default — a provider's body doesn't run
until something reads it. This matters for the outbox: if a repository's
`SyncWorker.registerHandler` call only happened when its screen was first
opened, a write queued before that screen was ever visited could sit
unhandled. `main.dart` works around this by explicitly reading each
repository provider at startup:

```dart
container.read(courseRepositoryProvider);
container.read(internshipRepositoryProvider);
container.read(assignmentRepositoryProvider);
container.read(liveRepositoryProvider);
container.read(syncWorkerProvider).start();
```

If a new feature adds outbox writes, its repository provider needs to be
added to this list too — that's the one piece of this pattern that isn't
automatic and is easy to forget.

## Testing

Every domain-layer use case is tested against a hand-written fake
repository (implementing the abstract interface directly, no mocking
framework) — see `test/features/`. This works precisely because
`presentation` and `domain` never depend on `data`'s concrete classes.

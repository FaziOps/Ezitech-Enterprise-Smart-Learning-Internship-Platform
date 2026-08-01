# Ezitech Enterprise Smart Learning & Internship Platform

Status: **Week 4 complete — finalization pass.** All 9 MVP modules are
built. This week was bug fixes, a performance/accessibility/responsive
pass, and the documentation + deployment artifacts the plan calls for.
No new features this week, deliberately — see the recommendation at the
bottom.

## Documentation index

| Doc | What's in it |
|---|---|
| `docs/ARCHITECTURE.md` | Layer structure, module map, offline-first design, security, what's real vs. seed data |
| `docs/DESIGN_SYSTEM.md` | Glass morphism tokens, components, accessibility notes |
| `docs/STATE_MANAGEMENT.md` | Riverpod patterns used and where |
| `docs/DEPLOYMENT.md` | Exact steps to generate native scaffolding, sign an Android build, and configure iOS |
| `docs/DEMO_SCRIPT.md` | Step-by-step live demo script, annotated with what's real vs. seeded |
| `docs/DELIVERABLES_CHECKLIST.md` | Honest done/not-done status against the case study's deliverables list |
| `docs/presentation/Ezitech_Technical_Presentation.pptx` | Technical presentation deck |
| `.github/workflows/ci.yml` | `flutter analyze` + `flutter test` on every PR |

## Week 4 changes to the code itself

- **Bug fixes**: bottom nav no longer incorrectly highlights Dashboard
  when on Notifications/Live/Portfolio (screens with no matching tab);
  removed a redundant Hive adapter registration in `main.dart` that could
  have thrown on a future refactor; removed a dead provider left over
  from Week 2's dashboard rewrite.
- **Performance**: the ambient background's continuously-animating blobs
  are now wrapped in a `RepaintBoundary`, so that animation no longer
  forces repaints of the glass panels and content sitting on top of it.
- **Accessibility**: icon-only buttons (back arrows, password visibility
  toggle, send buttons) now have `tooltip` set. Documented, and left
  honestly unverified: text-scale behavior and screen-reader navigation
  order need a real device pass, not something checkable without one.
- **Responsive layout**: Courses, Assignments, Internship, Live, and
  Portfolio screens now cap content width on tablets via a new
  `ResponsiveCenter` wrapper — previously only the Dashboard had tablet
  treatment.


## What I will not claim is done


- **No signed Android APK, no iOS build.** This project has no native
  `android/`/`ios/` scaffolding (never ran `flutter create` — no SDK in
  this build environment) and correctly has no signing keystore (that's
  yours to generate, never mine to fabricate). `docs/DEPLOYMENT.md` gets
  you both in about 20 minutes in a real environment.
- **`flutter analyze` and `flutter build` have never been run against
  this code.** Everything has been hand-reviewed as carefully as I can
  manage, and the domain-layer test suite (`flutter test`) is real and
  traced by hand — but "I read it carefully" and "the compiler confirmed
  it" are different claims. Run `flutter analyze` before you trust this
  further.
- **Zero real backend integrations, still.** Four weeks of features now
  sit on the same unconfirmed API assumptions flagged in Week 2 and
  Week 3. See `docs/DELIVERABLES_CHECKLIST.md` for the full accounting.


## Full API requirements table

Restoring this in full — it got progressively summarized down to "see
Week 1" references across Weeks 2 and 3, which made it useless without
digging through old messages. This is the complete, current list.

| # | API | Used by | What's needed from you |
|---|---|---|---|
| 1 | Ezitech Auth API | Login, refresh, logout, sessions | Base URL, and confirm/correct the response field names I guessed (`access_token`/`refresh_token`/`user`) |
| 2 | Ezitech LMS API | Course Management, Dashboard | Course list/detail, video stream URLs, PDF URLs, notes CRUD, progress read/write |
| 3 | Internship Portal API | Internship Portal | Case studies, daily tasks, weekly report submission, mentor feedback |
| 4 | Assignment Management API | Assignment Management | Assignment detail, multipart file upload endpoint, deadlines, evaluation results |
| 5 | GitHub API | Internship & Assignment GitHub submission | OAuth flow, or just a pasted repo URL with no API call — tell me which |
| 6 | Live Session / Video Conferencing API | Live Learning | Which provider (Zoom/Jitsi/Agora/plain link) — determines external-link vs. embedded SDK |
| 7 | Video Streaming API/CDN | Video playback | Signed URLs? DRM? Plain HTTPS? |
| 8 | Socket.IO / WebSocket server | Real-time chat/notifications (Full-Scope Backlog item, not yet built) | Namespace/event spec, once this is prioritized |
| 9 | Firebase project | Push notifications | `google-services.json` + `GoogleService-Info.plist` |
| 10 | AI Assistant backend | AI Learning Assistant | Proxy to a hosted LLM, or direct provider call — determines where the API key lives |
| 11 | Analytics/Portfolio data API | Engineering Portfolio, future Analytics module | Likely the same LMS API as #2 — confirm |

Zero of these have been provided across 4 weeks. That's the single
biggest risk to this project, stated as plainly as I can put it.

## The one thing worth acting on

35% of the stated evaluation weight (Business Logic 20% + API
Integration 15%) rests on API contracts nobody has confirmed. I said this
at Week 3 and it's still true. Before any Week 5 / Community / Analytics
work, I'd verify one real integration end-to-end. If you'd rather keep
building on seed data, that's a legitimate call — but make it on purpose,
not by default.




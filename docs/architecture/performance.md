# Performance (Firebase Performance Monitoring)

This document defines the performance-monitoring conventions established in TASK-019, the
counterpart of `analytics.md` (TASK-017) for infrastructure/technical telemetry.

## Abstraction

No feature is allowed to call `FirebasePerformance.instance` directly. Every custom trace goes
through `PerformanceMonitor` (`lib/core/performance/performance_monitor.dart`):

```dart
abstract interface class PerformanceMonitor {
  Future<void> startTrace(String name, {Map<String, String>? attributes});
  Future<void> stopTrace(String name);
  Future<T> wrapAsync<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  });
}
```

- `FirebasePerformanceMonitor` (`lib/core/performance/firebase_performance_monitor.dart`) is the
  real implementation, registered in DI as `@LazySingleton(as: PerformanceMonitor)`. It never
  throws: any failure calling the underlying SDK is caught and logged locally instead of
  propagating, same defensive pattern as `FirebaseCrashReporter`/`FirebaseAnalyticsService`.
- `FakePerformanceMonitor` (`lib/core/performance/fake_performance_monitor.dart`) is an in-memory
  implementation for unit/BLoC tests — no `mocktail` boilerplate required for the common case of
  asserting "this trace was started/stopped".
- `wrapAsync` is the preferred entry point for any operation that fits a single `await`-able call:
  it always stops the trace, including when the wrapped operation throws, and always propagates the
  wrapped operation's result/exception unchanged. `startTrace`/`stopTrace` exist for spans that do
  not fit a single call (e.g. a paginated sync loop spanning multiple callback-driven steps).

## Timeout guard

Every `Trace.start()`/`Trace.stop()` call made by `FirebasePerformanceMonitor` is wrapped in
`performanceTraceOperationTimeout` (3 seconds) on top of its own `try`/`catch`. This was added after
reproducing, while building this task, that calling the real SDK's `Trace.start()` in an environment
where the native Performance Monitoring channel never answers (e.g. a `flutter_test` VM run with no
platform plugin registered) leaves the call pending indefinitely instead of failing fast like most
other Firebase plugins do. Without this guard, a single unresponsive trace call could hang the
measured flow itself — the opposite of what an "instrumentation" mechanism is allowed to do. See
"Known risk" below for the direct consequence this had on this task's scope.

## Trace name catalog

Trace names live exclusively in `PerformanceTraces` (`lib/core/performance/performance_traces.dart`)
— never as string literals at the call site. Convention: `snake_case`, ending in `_duration`.

```text
sync_incremental_duration            — planned; connects to the offline sync engine (EPIC-14)
order_submit_duration                — planned; connects to order submission (TASK-101)
catalog_load_duration                — planned; connects to catalog loading (EPIC-10)
dependency_injection_setup_duration  — planned; see "Known risk" below
```

A trace name must stay stable once real historical data exists for it in the Firebase console —
`test/core/performance/performance_traces_test.dart` only guards against accidental duplicates, not
against renames, so that discipline is a code-review responsibility.

## Automatic native traces vs. manual traces

Firebase Performance Monitoring's native SDKs (Android/iOS) automatically capture "automatic
traces" for network requests made through the platform's own HTTP stack (e.g. `OkHttp` on Android,
`NSURLSession` on iOS) once `setPerformanceCollectionEnabled(true)` is in effect — there is no extra
Dart-side call needed to "enable" that mechanism beyond the collection toggle already applied by
`configurePerformance`.

In practice, this automatic instrumentation covers little of VestiPro's real traffic:

- `dio` (the app's HTTP client, see `docs/adr/0001-dependencias-base.md`) uses Dart's own
  `dart:io HttpClient`/`BrowserClient` transport, which does not route through the native
  OkHttp/NSURLSession stack the automatic instrumentation hooks into.
- Firestore/Cloud Functions/Storage calls go through their own native SDKs/gRPC transports, not
  through the automatically-instrumented HTTP stack either.

Because of this, every trace that matters for VestiPro's critical flows (sync, order submission,
catalog load) is a **manual** trace via `PerformanceMonitor`, not something the automatic mechanism
already covers. This is a deliberate, documented decision — not a gap to close with more native
configuration.

## Attributes

Traces may carry custom attributes (`Trace.putAttribute`) to allow segmentation in the Firebase
console — e.g. `platform`, a truncated/anonymized `organizationId`. Same LGPD restriction as
`AnalyticsService`/`CrashReporter`: never a personal or sensitive value, and never the raw request
payload.

## Environment collection policy

`configurePerformance` (`lib/core/performance/configure_performance.dart`) toggles collection per
environment exactly like `configureCrashlytics` (TASK-016) and `configureAnalytics` (TASK-017):
disabled for `development`, enabled for `staging`/`production`. Registered lazily in DI
(`lib/app/injection_module.dart`, `firebasePerformance`), the same on-demand pattern as every other
Firebase product wired so far — nothing touches the real SDK until something actually resolves
`PerformanceMonitor`.

## Known risk: no production flow wired yet

TASK-019 ships the full abstraction, catalog, DI wiring, timeout guard and unit tests (all exercised
against a mocked `FirebasePerformance`), but does **not** connect any of the four catalog entries
above to a real running flow yet:

- `sync_incremental_duration`, `order_submit_duration` and `catalog_load_duration` are planned
  ahead of the flows that will use them (sync engine, order submission, catalog loading do not exist
  yet) — this was expected from the start (see the task's own "Escopo técnico").
- `dependency_injection_setup_duration` was meant to be the one trace connected end-to-end in this
  task (wrapping `configureDependencies` in `lib/app/bootstrap.dart`), to validate the mechanism
  before the real flows land. That wiring was implemented, exercised against the actual
  `flutter test` suite, and **reverted** after it reproduced the hang described above: touching the
  real `FirebasePerformance.instance` eagerly on every `bootstrap()` call — including in
  `test/app/bootstrap_test.dart`, which runs the full `bootstrap()` function — hung the test suite
  indefinitely even with the internal `try`/`catch` guard, because a hang is not an exception the
  guard can catch. The (now-added) `performanceTraceOperationTimeout` bounds that specific failure
  mode, but wiring it back into the always-on `bootstrap()` path was judged out of scope for this
  task to re-validate safely (it would need either a mocked Performance Monitoring channel in
  `bootstrap_test.dart`, or moving the trace to a call site not exercised by that widget test).

Manual verification that a trace appears in the real Firebase Performance console (mentioned in the
task's own "Testes obrigatórios") was **not** performed — it requires running the app on a real
device/emulator or in profile mode, which this environment cannot do. The follow-up task that first
implements a real flow above (sync, order submission or catalog loading) should be the one to wire
its `PerformanceMonitor.wrapAsync` call and perform that console verification, since by then there is
a real, already-tested flow to attach it to instead of a synthetic one.

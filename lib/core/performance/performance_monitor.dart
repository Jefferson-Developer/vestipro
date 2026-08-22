/// Central abstraction over Firebase Performance Monitoring (TASK-019). No
/// feature is allowed to call `FirebasePerformance.instance` directly —
/// every custom trace goes through this interface, so the concrete SDK stays
/// swappable and mockable in tests (same reasoning as `AnalyticsService` for
/// `firebase_analytics`, TASK-017, and `CrashReporter` for
/// `firebase_crashlytics`, TASK-016).
///
/// Implementations must never throw: a failure while *measuring* performance
/// must never itself become the reason a critical flow (sync, order
/// submission, catalog load) fails, slows down or masks the caller's own
/// error handling.
abstract interface class PerformanceMonitor {
  /// Starts a trace named [name] — always one of the constants defined in
  /// `PerformanceTraces`, never a string literal — optionally tagging it
  /// with [attributes] (e.g. `platform`, a truncated/anonymized
  /// `organizationId`; never personal or sensitive data, and never the raw
  /// payload itself).
  ///
  /// Prefer [wrapAsync] whenever the measured operation is a single
  /// `Future`-returning call: it guarantees the trace is always stopped,
  /// even when the operation throws. Use [startTrace]/[stopTrace] only when
  /// the measured span does not fit a single `await`-able call (e.g. it
  /// spans multiple callback-driven steps, like a paginated sync loop).
  Future<void> startTrace(String name, {Map<String, String>? attributes});

  /// Stops the trace previously started with [startTrace] under the same
  /// [name]. A no-op (never throws) if no matching trace is currently
  /// running — e.g. it was already stopped, or [startTrace] itself failed.
  Future<void> stopTrace(String name);

  /// Runs [action], measuring its duration as a trace named [name],
  /// optionally tagged with [attributes]. The trace is always stopped —
  /// including when [action] throws — and [action]'s result/exception is
  /// always propagated to the caller unchanged.
  Future<T> wrapAsync<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  });
}

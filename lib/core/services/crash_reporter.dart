/// Central abstraction for crash/error reporting (TASK-016). No feature is
/// allowed to call `FirebaseCrashlytics.instance` directly — every report
/// goes through this interface, so the concrete SDK stays swappable and
/// mockable in tests (same reasoning as `CloudFunctionsService` for
/// `cloud_functions`, TASK-015).
///
/// Implementations must never throw: a failure while *reporting* an error
/// must not itself crash the app or mask the original error.
abstract interface class CrashReporter {
  /// Records [exception] (with [stackTrace], when available) as a crash
  /// report.
  ///
  /// [reason] is a short, human-readable hint about where/why the error was
  /// raised (e.g. the originating module or Bloc) — never include personal
  /// or sensitive data in it. Set [fatal] to `true` when the error would
  /// have crashed the app had it not been caught (e.g. an error that reached
  /// `FlutterError.onError`/`PlatformDispatcher.onError`); leave it `false`
  /// for unexpected-but-recovered errors surfaced deeper in the app (e.g. a
  /// Bloc's `onError`).
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Associates subsequent reports with the signed-in user's technical
  /// [userId]. Never pass an e-mail or display name here (LGPD — see
  /// `AGENTS.md`). Pass `null` to clear it (e.g. on logout).
  Future<void> setUserIdentifier(String? userId);

  /// Attaches a custom key/value pair to subsequent reports — the extension
  /// point future tasks use to add safe context (e.g. `organizationId`,
  /// `companyId`, current module) once that domain data exists. [value] must
  /// never be personal or sensitive data.
  Future<void> setCustomKey(String key, Object value);
}

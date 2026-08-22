/// Central abstraction for product/commercial analytics (TASK-017). No
/// feature is allowed to call `FirebaseAnalytics.instance` directly — every
/// event goes through this interface, so the concrete SDK stays swappable
/// and mockable in tests (same reasoning as `CrashReporter` for
/// `firebase_crashlytics`, TASK-016).
///
/// Implementations must never throw: a failure while *reporting* analytics
/// must not itself crash the app or mask the caller's own error handling.
abstract interface class AnalyticsService {
  /// Logs an analytics event named [name] — always one of the constants
  /// defined in `AnalyticsEvents`, never a string literal — with optional
  /// [parameters].
  ///
  /// [parameters] must never contain personal or sensitive data (full name,
  /// e-mail, phone, CPF/CNPJ) — only technical identifiers and business
  /// metrics (ids, counts, statuses, amounts).
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});

  /// Associates subsequent events with the signed-in user's technical
  /// [userId]. Never pass an e-mail or display name here (LGPD — see
  /// `AGENTS.md`). Pass `null` to clear it (e.g. on logout).
  Future<void> setUserId(String? userId);

  /// Attaches a [name]/[value] user property to subsequent events — the
  /// extension point used to segment analytics by tenant/role once that
  /// domain data exists (see `AnalyticsUserProperties`). [name] must always
  /// come from `AnalyticsUserProperties`, never a string literal, and
  /// [value] must never be personal or sensitive data. Pass `null` as
  /// [value] to clear the property.
  Future<void> setUserProperty({required String name, required String? value});
}

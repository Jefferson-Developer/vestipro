/// Central abstraction for feature flags/remote parameters (TASK-018), built
/// on top of Firebase Remote Config. No feature is allowed to call
/// `FirebaseRemoteConfig.instance` directly — every flag read goes through
/// this interface, so the concrete SDK stays swappable and mockable in
/// tests (same reasoning as `AnalyticsService`/`CrashReporter`).
///
/// Every [String] key passed to these methods must be one of the constants
/// declared in `FeatureFlagRegistry`
/// (`lib/core/feature_flags/feature_flag_registry.dart`). Implementations
/// fall back to that registry's code-defined default whenever Remote Config
/// itself has not (yet) produced a real value for the key, or fails — the
/// app's default behavior must never depend solely on the remote console
/// (see `AGENTS.md`).
///
/// Reserved for functionality/experience toggles and non-critical
/// parameters only: authorization, pricing, order numbering and approval
/// rules must never depend exclusively on a flag read here — those stay in
/// Cloud Functions/Security Rules, per `AGENTS.md`.
///
/// Implementations must never throw: a failure while reading a flag must
/// fall back to the code-defined default instead of crashing the app or
/// blocking the caller.
abstract interface class FeatureFlagService {
  /// Whether the boolean flag [flagKey] is enabled.
  bool isEnabled(String flagKey);

  /// The string value of the Remote Config parameter [flagKey].
  String getString(String flagKey);

  /// The integer value of the Remote Config parameter [flagKey].
  int getInt(String flagKey);
}

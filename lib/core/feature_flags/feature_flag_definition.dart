/// The Remote Config value type a flag/parameter is read as (TASK-018).
enum FeatureFlagValueType { boolean, string, integer }

/// Metadata for a single Remote Config-backed feature flag/parameter
/// (TASK-018). Every key read through `FeatureFlagService` must be
/// registered as one of these in `FeatureFlagRegistry`
/// (`lib/core/feature_flags/feature_flag_registry.dart`) — reading an
/// unregistered key is a programming error, so no flag can exist without a
/// documented owner, review date and code-defined default.
///
/// Mirrors the table required by `docs/architecture/feature-flags.md`: a
/// flag/parameter with a missing [owner] or [reviewBy] must not be merged
/// (see `AGENTS.md`).
final class FeatureFlagDefinition {
  const FeatureFlagDefinition({
    required this.key,
    required this.description,
    required this.owner,
    required this.createdAt,
    required this.reviewBy,
    required this.type,
    required this.defaultValue,
  });

  /// Remote Config parameter key. Must follow the naming convention
  /// documented in `docs/architecture/feature-flags.md`:
  /// `feature_<modulo>_<nome>_enabled` for booleans,
  /// `config_<modulo>_<parametro>` for string/int parameters.
  final String key;

  /// Short, human-readable description of what the flag/parameter controls.
  final String description;

  /// Person or squad responsible for the flag — required so a stale/dead
  /// flag always has someone to ask before removal.
  final String owner;

  /// When the flag was created.
  final DateTime createdAt;

  /// Planned date to review whether the flag is still needed. Temporary
  /// rollout flags must be removed once stabilized (retirement process in
  /// `docs/architecture/feature-flags.md`), instead of accumulating dead
  /// flags across the rest of the backlog.
  final DateTime reviewBy;

  /// The Remote Config value type this flag is read as.
  final FeatureFlagValueType type;

  /// Safe local default — used both as the value passed to
  /// `FirebaseRemoteConfig.setDefaults` (see `configureRemoteConfig`) and as
  /// the fallback `FirebaseFeatureFlagService` returns whenever the SDK
  /// itself has not yet produced a real value for [key], or throws. Must
  /// be a `bool`, `String` or `int` matching [type].
  final Object defaultValue;
}

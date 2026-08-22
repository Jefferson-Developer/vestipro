import 'feature_flag_definition.dart';

/// Central registry/table of every feature flag and Remote Config parameter
/// the app reads (TASK-018) — the source of truth documented in full at
/// `docs/architecture/feature-flags.md`. No feature is allowed to pass a raw
/// string literal to `FeatureFlagService`; every key used there must have a
/// matching constant and [FeatureFlagDefinition] entry here first, exactly
/// like `AnalyticsEvents` for analytics event names.
final class FeatureFlagRegistry {
  const FeatureFlagRegistry._();

  /// Example flag (TASK-018), created to validate the Remote Config pipeline
  /// end to end: defined here with a safe (disabled) default, read through
  /// `FeatureFlagService.isEnabled`, and used to conditionally show the
  /// "Insights" shortcut in `AboutAppPage` (the feature-first reference
  /// module). Remove once a real Insights module (EPIC-17) ships with its
  /// own permanent flag — see the retirement process in
  /// `docs/architecture/feature-flags.md`.
  static const String featureInsightsEnabled = 'feature_insights_enabled';

  static final List<FeatureFlagDefinition> _definitions =
      <FeatureFlagDefinition>[
        FeatureFlagDefinition(
          key: featureInsightsEnabled,
          description:
              'Exibe o atalho de Insights Comerciais no modulo de '
              'referencia (Sobre o app) — placeholder criado para validar '
              'o pipeline do Remote Config ponta a ponta antes do modulo '
              'real de insights (EPIC-17).',
          owner: 'flutter-senior-architect',
          createdAt: DateTime.utc(2026, 8, 22),
          reviewBy: DateTime.utc(2026, 11, 22),
          type: FeatureFlagValueType.boolean,
          defaultValue: false,
        ),
      ];

  /// Read-only view of every registered flag/parameter — used to keep
  /// `docs/architecture/feature-flags.md` and [remoteConfigDefaults] in
  /// sync, and by `test/core/feature_flags/feature_flag_registry_test.dart`
  /// to catch duplicate/malformed entries.
  static List<FeatureFlagDefinition> get all => List.unmodifiable(_definitions);

  /// The map passed to `FirebaseRemoteConfig.setDefaults` (see
  /// `configureRemoteConfig`) — one entry per registered flag/parameter, so
  /// no flag can ever be read by the SDK without a safe local default
  /// already applied.
  static Map<String, Object> get remoteConfigDefaults => <String, Object>{
    for (final definition in _definitions)
      definition.key: definition.defaultValue,
  };

  /// Looks up the [FeatureFlagDefinition] for [key]. Throws [ArgumentError]
  /// for an unregistered key — every flag must be declared above before
  /// `FeatureFlagService` can read it, so a typo or a removed-but-still-
  /// referenced flag fails fast during development instead of silently
  /// always returning a fallback of the wrong type.
  static FeatureFlagDefinition definitionOf(String key) {
    for (final definition in _definitions) {
      if (definition.key == key) return definition;
    }

    throw ArgumentError.value(
      key,
      'key',
      'Unregistered feature flag. Add it to FeatureFlagRegistry first '
          '(see docs/architecture/feature-flags.md).',
    );
  }
}

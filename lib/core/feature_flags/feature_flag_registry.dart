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
  static const String featureInventoryReservationsEnabled =
      'feature_inventory_reservations_enabled';

  /// Maximum accepted product video duration (TASK-068), read by
  /// `ProductMediaBloc` and enforced client-side *before* any byte is
  /// transferred — `storage.rules` cannot inspect video duration server-side,
  /// so this is the only enforcement point for this particular limit (file
  /// size/content-type are still re-validated server-side, see
  /// `isValidProductMedia` in `storage.rules`).
  static const String configProductsVideoMaxDurationSeconds =
      'config_products_video_max_duration_seconds';

  /// Maximum accepted product video file size in megabytes (TASK-068),
  /// pre-checked client-side for a fast/clear rejection message; the real
  /// authorization boundary is still `storage.rules`' own byte-size check.
  static const String configProductsVideoMaxSizeMb =
      'config_products_video_max_size_mb';

  /// JSON array describing the catalog home's section composition
  /// (TASK-076) — one `{type, title, order, priority, enabled, itemLimit}`
  /// object per `CatalogHomeSectionType`, read by
  /// `RemoteConfigCatalogHomeConfigRepository`. Empty string default means
  /// "no override yet": the repository falls back to
  /// `defaultCatalogHomeSectionConfigs` (code-defined), so a manager can
  /// reorder/rename/disable a section from the Remote Config console
  /// without an app deploy, without the app ever depending solely on the
  /// remote value being present.
  static const String configCatalogHomeSectionsJson =
      'config_catalog_home_sections_json';

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
        FeatureFlagDefinition(
          key: featureInventoryReservationsEnabled,
          description:
              'Habilita a reserva comercial temporaria de estoque para '
              'pedidos em elaboracao (TASK-092). Valor padrao desligado '
              'ate estabilizacao do fluxo server-side de expiracao, '
              'liberacao e consumo.',
          owner: 'flutter-senior-architect',
          createdAt: DateTime.utc(2026, 8, 28),
          reviewBy: DateTime.utc(2026, 11, 28),
          type: FeatureFlagValueType.boolean,
          defaultValue: false,
        ),
        FeatureFlagDefinition(
          key: configProductsVideoMaxDurationSeconds,
          description:
              'Duracao maxima (em segundos) aceita para um video curto de '
              'produto no cadastro/galeria de midia — rejeitado no '
              'cliente antes do upload (TASK-068).',
          owner: 'flutter-senior-architect',
          createdAt: DateTime.utc(2026, 8, 24),
          reviewBy: DateTime.utc(2027, 2, 24),
          type: FeatureFlagValueType.integer,
          defaultValue: 60,
        ),
        FeatureFlagDefinition(
          key: configProductsVideoMaxSizeMb,
          description:
              'Tamanho maximo (em megabytes) aceito para um video curto de '
              'produto no cadastro/galeria de midia — rejeitado no '
              'cliente antes do upload (TASK-068).',
          owner: 'flutter-senior-architect',
          createdAt: DateTime.utc(2026, 8, 24),
          reviewBy: DateTime.utc(2027, 2, 24),
          type: FeatureFlagValueType.integer,
          defaultValue: 50,
        ),
        FeatureFlagDefinition(
          key: configCatalogHomeSectionsJson,
          description:
              'Composicao das secoes da home do catalogo premium (JSON), '
              'permitindo reordenar/renomear/desabilitar uma secao sem '
              'deploy do app (TASK-076). Vazio = usa a composicao padrao '
              'definida em codigo (defaultCatalogHomeSectionConfigs).',
          owner: 'flutter-senior-architect',
          createdAt: DateTime.utc(2026, 8, 25),
          reviewBy: DateTime.utc(2027, 2, 25),
          type: FeatureFlagValueType.string,
          defaultValue: '',
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

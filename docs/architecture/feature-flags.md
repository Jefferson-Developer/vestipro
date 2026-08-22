# Feature Flags (Firebase Remote Config)

This document defines the feature flag conventions established in TASK-018, the counterpart of
`analytics.md` for functionality/experience toggles and non-critical remote parameters.

## Abstraction

No feature is allowed to call `FirebaseRemoteConfig.instance` directly. Every flag/parameter read
goes through `FeatureFlagService` (`lib/core/feature_flags/feature_flag_service.dart`):

```dart
abstract interface class FeatureFlagService {
  bool isEnabled(String flagKey);
  String getString(String flagKey);
  int getInt(String flagKey);
}
```

- `FirebaseFeatureFlagService` (`lib/core/feature_flags/firebase_feature_flag_service.dart`) is the
  real implementation, registered in DI as `@LazySingleton(as: FeatureFlagService)`. It never
  throws: any failure reading the underlying SDK is caught and logged locally instead of
  propagating (same defensive pattern as `FirebaseAnalyticsService`/`FirebaseCrashReporter`).
- `FakeFeatureFlagService` (`lib/core/feature_flags/fake_feature_flag_service.dart`) is an in-memory
  implementation for unit/BLoC/widget tests, with an `overrideFlag`/`reset` API — no `mocktail`
  boilerplate required for the common case of "this flag is on/off in this test".

Every key passed to `FeatureFlagService` must be one of the constants declared in
`FeatureFlagRegistry` (`lib/core/feature_flags/feature_flag_registry.dart`), never a raw string
literal at the call site — same reasoning as `AnalyticsEvents` for analytics event names.

## Naming convention

- `feature_<modulo>_<nome>_enabled` for boolean flags read through `isEnabled`.
- `config_<modulo>_<parametro>` for string/int Remote Config parameters read through
  `getString`/`getInt`.

## Flag registry (table)

`FeatureFlagRegistry` is the single source of truth for every flag/parameter the app reads. A flag
without an `owner` and a `reviewBy` date must not be merged (see `AGENTS.md`). Current table:

| Key                          | Type      | Default | Description                                                                                                                      | Owner                        | Created    | Review by  |
| ----------------------------- | --------- | ------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ---------- | ---------- |
| `feature_insights_enabled`    | boolean   | `false` | Shows the "Insights" shortcut in the reference module (`AboutAppPage`) — placeholder created to validate the Remote Config pipeline end to end, before the real Insights module ships (EPIC-17). | `flutter-senior-architect`    | 2026-08-22 | 2026-11-22 |

## Defaults and fetch policy

`configureRemoteConfig` (`lib/core/feature_flags/configure_remote_config.dart`) wires
`FirebaseRemoteConfig` once, the first time it is resolved from DI
(`lib/app/injection_module.dart`), in this order:

1. `setConfigSettings` — applies a per-environment `minimumFetchInterval`: `Duration.zero` in
   `development` (a change in the console/Emulator is visible on the next fetch, without waiting
   out a cache window during active development), `15 minutes` in `staging`, `1 hour` in
   `production` (so the app does not hammer the backend with every cold start across the whole
   install base). `fetchTimeout` stays at `10 seconds` for every environment.
2. `setDefaults` — applies every flag/parameter registered in `FeatureFlagRegistry` as the SDK's own
   local defaults. This step must fully complete before the rest of the app can trust a Remote
   Config value as "real" (see below).
3. `fetchAndActivate` — best-effort, guarded by an extra `remoteConfigFetchGuardTimeout` (10
   seconds) on top of the SDK's own `fetchTimeout`.

There is no local Remote Config Emulator to connect to (same limitation as Crashlytics, TASK-016):
`dev`/`staging`/`production` all read from the same real Remote Config backend, per ADR-0002.

`configureRemoteConfig` never throws: every step above is wrapped in `try`/`catch`, because it runs
fire-and-forget (`unawaited`) from the `FirebaseRemoteConfig` DI provider — nothing downstream ever
awaits or catches this Future.

### How a flag stays safe before the fetch completes

`FirebaseFeatureFlagService` never trusts `FirebaseRemoteConfig`'s own raw built-in default
(`ValueSource.valueStatic`, returned before `setDefaults`/a fetch has ever applied a value for a
key). It only reads through to the SDK once the value's source is `valueDefault` (applied by
`setDefaults`) or `valueRemote` (fetched from the backend and activated); otherwise it falls back to
the flag's own code-defined default in `FeatureFlagRegistry`. This is what keeps a flag read correct
even while `configureRemoteConfig`'s `setDefaults` call is still in flight, or if `Firebase`/Remote
Config cannot be resolved at all (e.g. a widget test that renders the app without going through the
real `bootstrap`) — see `bootstrap.dart`'s `_resolveShowInsightsShortcut`, which additionally guards
the whole `FeatureFlagService` resolution itself so a flag can never keep the rest of the app from
rendering.

## Reserved for functionality/experience only

Remote Config is for functionality/experience toggles and non-critical parameters. Authorization,
pricing, order numbering and approval rules must never depend exclusively on a flag read through
`FeatureFlagService` — those stay in Cloud Functions/Security Rules, per `AGENTS.md`.

## End-to-end example: `feature_insights_enabled`

`AboutAppPage.showInsightsShortcut` (`lib/features/settings/presentation/pages/about_app_page.dart`)
conditionally renders an "Insights" shortcut in the reference module's app bar. The flag is resolved
once at the composition boundary (`VestiProApp.build`, `lib/app/bootstrap.dart`) through
`FeatureFlagService.isEnabled(FeatureFlagRegistry.featureInsightsEnabled)`, then passed down as a
plain constructor parameter — the page itself never reads the flag or touches DI. No real Insights
module exists yet (EPIC-17); tapping the shortcut only confirms the flag reached the widget.

## Retirement process for temporary flags

Every flag created to gate a rollout (as opposed to a long-lived operational parameter) must be
removed once stabilized, to avoid accumulating dead flags across the rest of the backlog:

1. Once the flagged feature has been enabled for every organization/environment and no rollback is
   expected, remove the conditional branch from the call site (keep the feature's code, delete the
   `if (flagService.isEnabled(...))` check).
2. Remove the flag's entry from `FeatureFlagRegistry` and its row from the table above.
3. Delete the parameter from the Remote Config console.
4. Update/remove the flag's dedicated tests.

`reviewBy` in `FeatureFlagRegistry` is the trigger to check whether a flag is due for this process —
not a hard deadline that fails a build, but a signal for whoever owns the flag to revisit it.

## Testing

- `test/core/feature_flags/feature_flag_registry_test.dart` — every registered flag has an owner, a
  review date after its creation date, no duplicate keys, and `remoteConfigDefaults` matches the
  registry.
- `test/core/feature_flags/fake_feature_flag_service_test.dart` — `FakeFeatureFlagService` returns
  registry defaults, honors `overrideFlag`/`reset`, and throws for an unregistered key like the real
  implementation.
- `test/core/feature_flags/firebase_feature_flag_service_test.dart` — `FirebaseFeatureFlagService`
  falls back to the registry default for `ValueSource.valueStatic` and for SDK failures, and reads
  through to the SDK for `valueDefault`/`valueRemote`.
- `test/core/feature_flags/configure_remote_config_test.dart` — call order
  (`setConfigSettings` → `setDefaults` → `fetchAndActivate`), per-environment fetch interval, and
  that no step ever throws past `configureRemoteConfig`.
- `test/features/settings/presentation/pages/about_app_page_test.dart` — the "Insights" shortcut is
  hidden by default and shown end to end when `showInsightsShortcut` is `true`.

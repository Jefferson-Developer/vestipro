# Analytics (Firebase Analytics)

This document defines the analytics conventions established in TASK-017, the counterpart of
`static-quality.md`/`testing.md` for product/commercial telemetry.

## Abstraction

No feature is allowed to call `FirebaseAnalytics.instance` directly. Every event goes through
`AnalyticsService` (`lib/core/analytics/analytics_service.dart`):

```dart
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty({required String name, required String? value});
}
```

- `FirebaseAnalyticsService` (`lib/core/analytics/firebase_analytics_service.dart`) is the real
  implementation, registered in DI as `@LazySingleton(as: AnalyticsService)`. It never throws: any
  failure calling the underlying SDK is caught and logged locally instead of propagating, so a
  broken analytics call never crashes the app or masks the caller's own error handling (same
  defensive pattern as `FirebaseCrashReporter`, TASK-016).
- `FakeAnalyticsService` (`lib/core/analytics/fake_analytics_service.dart`) is an in-memory
  implementation for unit/BLoC tests — no `mocktail` boilerplate required for the common case of
  asserting "this event was logged with these parameters".

## Event naming convention

Event names live exclusively in `AnalyticsEvents`
(`lib/core/analytics/analytics_events.dart`) — never as string literals at the call site.

Convention: `snake_case`, verb in the past participle. Examples already defined:

```text
login_completed
organization_created
customer_created
product_viewed
catalog_filtered
order_created
order_submitted
order_sync_failed
crm_activity_created
insight_opened
insight_action_clicked
report_exported
offline_pack_downloaded
product_added_to_order
```

When a future task needs a new event, add a constant to `AnalyticsEvents` (and to its `values`
list, used by `test/core/analytics/analytics_events_test.dart` to catch duplicates) instead of
inlining a string. RBAC/audit metrics must not be mixed into this same catalog if/when they need
their own taxonomy — keep commercial/product analytics and administrative auditing separate.

## User properties and tenant segmentation

User property names also live in a single catalog, `AnalyticsUserProperties`
(`lib/core/analytics/analytics_user_properties.dart`):

- `organization_id` — the signed-in user's tenant, so metrics can be segmented per organization.
- `role` — the signed-in user's RBAC role, so metrics can be segmented per role (e.g.
  representative vs. manager).
- `is_test_account` — see "Filtering test/QA traffic" below.

`AnalyticsService.setUserId`/`setUserProperty` exist so a future auth/RBAC feature can associate
`organization_id`/`role` with subsequent events. No such call site exists yet in this task: TASK-017
only ships the infrastructure, since login/organization/RBAC land in later tasks (EPIC-03/EPIC-04).
Only technical identifiers belong in these properties — never personal or sensitive data (full
name, e-mail, phone, CPF/CNPJ), per the LGPD restriction in `AGENTS.md`.

## Filtering test/QA traffic

Per ADR-0002 (TASK-010), VestiPro uses a single real Firebase project for every flavor — there is
no separate Firebase project (nor a local Analytics emulator) to isolate `dev`/`staging` traffic
from `production`. `configureAnalytics` (`lib/core/analytics/configure_analytics.dart`) handles
this the same way `configureCrashlytics` does for Crashlytics collection, plus an extra tag:

- `development`: Analytics collection is disabled entirely — a developer's local run never reaches
  the real Analytics console.
- `staging`: collection stays enabled (so the event pipeline itself is validated before release),
  but every event is tagged with `is_test_account = 'true'`. Any BI dashboard/report built on top of
  this data (EPIC-17/EPIC-18) must filter out `is_test_account = 'true'` before computing real
  commercial metrics.
- `production`: collection stays enabled and `is_test_account` is explicitly cleared (`null`).

## Testing

- `test/core/analytics/analytics_events_test.dart` — the taxonomy has no duplicates and matches the
  list documented above.
- `test/core/analytics/fake_analytics_service_test.dart` — `FakeAnalyticsService` records
  `logEvent`/`setUserId`/`setUserProperty` calls correctly, exercised through an example call site.
- `test/core/analytics/firebase_analytics_service_test.dart` — `FirebaseAnalyticsService` forwards
  calls to the SDK, strips `null` parameter values (the SDK requires non-null values), and never
  throws when the SDK itself fails.
- `test/core/analytics/configure_analytics_test.dart` — collection toggling and the
  `is_test_account` tag behave as documented above per environment.

/// Centralized catalog of Firebase Analytics user property names (TASK-017),
/// the `AnalyticsEvents` counterpart for `AnalyticsService.setUserProperty`.
/// No feature is allowed to pass a raw string literal as a property name —
/// always reference a constant defined here.
///
/// Only technical/segmentation identifiers belong here — never personal or
/// sensitive data (name, e-mail, phone, CPF/CNPJ), per the LGPD restriction
/// in TASK-017 and `AGENTS.md`.
final class AnalyticsUserProperties {
  const AnalyticsUserProperties._();

  /// Tenant the signed-in user currently operates in. Lets analytics be
  /// segmented by organization without exposing any personal data — the
  /// value is always the technical `organizationId`, never the
  /// organization's display name.
  static const String organizationId = 'organization_id';

  /// The user's current RBAC role, so product metrics can be segmented by
  /// role (e.g. representative vs. manager) without exposing who the user
  /// actually is.
  static const String role = 'role';

  /// Marks events coming from a non-production environment/test account so
  /// downstream BI dashboards can filter them out of real commercial
  /// metrics. Set by `configureAnalytics` based on the running
  /// `AppEnvironment` (see `docs/architecture/analytics.md`); features must
  /// not set this property themselves.
  static const String isTestAccount = 'is_test_account';
}

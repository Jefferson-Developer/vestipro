/// Typed route definitions for [AppRouter].
///
/// No feature may hardcode a route path string inside a widget. Every route
/// is declared once here; features navigate through these types or through
/// helpers exposed by `AppRouter`.
library;

/// Base type for every route VestiPro can navigate to.
sealed class AppRoute {
  const AppRoute();

  /// The resolved location for this route instance, with parameters filled
  /// in.
  String get location;
}

/// Example module route (see TASK-004) rendering the "About app" page.
///
/// Every authenticated feature route must follow the same
/// `/org/:orgId/...` convention documented in
/// `docs/architecture/navigation.md`, so that deep links and Flutter Web
/// reloads keep working once real organizations exist (TASK-026/TASK-037).
final class AboutAppRoute extends AppRoute {
  const AboutAppRoute({required this.orgId});

  final String orgId;

  static const name = 'aboutApp';
  static const pathPattern = '/org/:orgId/settings/about';

  @override
  String get location => '/org/$orgId/settings/about';
}

/// Route shown when a guard denies access to the requested location.
final class ForbiddenRoute extends AppRoute {
  const ForbiddenRoute();

  static const name = 'forbidden';
  static const pathPattern = '/forbidden';

  @override
  String get location => pathPattern;
}

/// Route shown when no declared route matches the requested location.
///
/// Not registered as its own [GoRoute]: any unmatched location already
/// falls back to this page through `AppRouter`'s `errorBuilder`. The type
/// exists so features can reference it by name instead of a literal string.
final class NotFoundRoute extends AppRoute {
  const NotFoundRoute();

  static const name = 'notFound';
  static const pathPattern = '/not-found';

  @override
  String get location => pathPattern;
}

/// Placeholder organization id used while TASK-026 (model Organization) and
/// TASK-037 (create the first Organization) do not exist yet.
///
/// [ActiveOrganizationGuard] does not validate this value today — it only
/// becomes meaningful once a real active organization can be resolved.
const kPlaceholderOrganizationId = 'default';

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

/// Route shown to sign a user in (TASK-034).
///
/// [SessionAuthGuard] (TASK-012) already redirects here for any
/// unauthenticated request to a protected route; [AppRouter] is not wired
/// to use [SessionAuthGuard] by default yet (that guard swap is TASK-041's
/// persistent-session responsibility), so this route only becomes the
/// actual entry point of the app once that task lands.
final class LoginRoute extends AppRoute {
  const LoginRoute();

  static const name = 'login';
  static const pathPattern = '/login';

  @override
  String get location => pathPattern;
}

/// Route shown for the "forgot password" flow.
///
/// Declared ahead of its own implementation, same precedent as [LoginRoute]
/// before TASK-034: not registered as a [GoRoute] yet, so navigating here
/// today falls back to [NotFoundRoute]'s `errorBuilder`. The login screen
/// (TASK-034) already links to [PasswordResetRoute.location] through
/// `go_router` so that TASK-036 only has to register the real `GoRoute` and
/// page builder, without touching the login screen again.
final class PasswordResetRoute extends AppRoute {
  const PasswordResetRoute();

  static const name = 'passwordReset';
  static const pathPattern = '/password-reset';

  @override
  String get location => pathPattern;
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

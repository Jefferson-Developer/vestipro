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

/// Route shown to create a brand-new account (TASK-035).
///
/// Linked from [LoginRoute] ("Criar conta") and links back to it ("Já tem
/// conta? Entrar"), same reciprocal-link precedent as [PasswordResetRoute].
final class SignUpRoute extends AppRoute {
  const SignUpRoute();

  static const name = 'signUp';
  static const pathPattern = '/sign-up';

  @override
  String get location => pathPattern;
}

/// Route shown for the "forgot password" flow (TASK-036).
///
/// Linked from [LoginRoute] ("Esqueci minha senha") and links back to it
/// ("Voltar para o login"), same reciprocal-link precedent as [SignUpRoute].
final class PasswordResetRoute extends AppRoute {
  const PasswordResetRoute();

  static const name = 'passwordReset';
  static const pathPattern = '/password-reset';

  @override
  String get location => pathPattern;
}

/// Route shown for the initial onboarding wizard, right after a successful
/// sign-up (TASK-038).
///
/// Declared ahead of its own implementation, same precedent [PasswordResetRoute]
/// followed before TASK-036: not registered as a [GoRoute] yet, so
/// navigating here today falls back to [NotFoundRoute]'s `errorBuilder`.
/// `SignUpPage` (TASK-035) already navigates to
/// [OnboardingWizardRoute.location] through `go_router` so that TASK-037
/// (which actually creates the first Organization before the wizard can run)
/// only has to register the real `GoRoute`/page builder, without touching
/// the sign-up screen again.
final class OnboardingWizardRoute extends AppRoute {
  const OnboardingWizardRoute();

  static const name = 'onboardingWizard';
  static const pathPattern = '/onboarding';

  @override
  String get location => pathPattern;
}

/// Route shown for the Terms of Service/Privacy Policy content linked from
/// the sign-up form's acceptance checkbox (TASK-035/EPIC-20).
///
/// Declared ahead of its own implementation — the actual terms content is
/// TASK-156's responsibility (EPIC-20) — same precedent as
/// [OnboardingWizardRoute]: not registered as a [GoRoute] yet, so tapping
/// the link today falls back to [NotFoundRoute]'s `errorBuilder` instead of
/// crashing or silently doing nothing.
final class TermsOfServiceRoute extends AppRoute {
  const TermsOfServiceRoute();

  static const name = 'termsOfService';
  static const pathPattern = '/terms-of-service';

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

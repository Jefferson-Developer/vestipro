/// Typed route definitions for [AppRouter].
///
/// No feature may hardcode a route path string inside a widget. Every route
/// is declared once here; features navigate through these types or through
/// helpers exposed by `AppRouter`.
library;

import '../auth/domain/value_objects/session_ended_reason.dart';

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

/// Read-only administrative audit log route (TASK-047).
///
/// It lives under the active organization scope and is protected in
/// [AppRouter] by `audit.log.view`, currently OWNER/ADMIN only.
final class AuditLogRoute extends AppRoute {
  const AuditLogRoute({required this.orgId});

  final String orgId;

  static const name = 'auditLog';
  static const pathPattern = '/org/:orgId/settings/audit-log';

  @override
  String get location => '/org/$orgId/settings/audit-log';
}

/// Customer creation form route (TASK-049), scoped by Organization and
/// Company. Protected in [AppRouter] by `customer.create`.
final class CustomerFormRoute extends AppRoute {
  const CustomerFormRoute({required this.orgId, required this.companyId});

  final String orgId;
  final String companyId;

  static const name = 'customerForm';
  static const pathPattern = '/org/:orgId/companies/:companyId/customers/new';

  @override
  String get location => '/org/$orgId/companies/$companyId/customers/new';
}

/// Customer portfolio list route (TASK-051), scoped by Organization and
/// Company. Search and filters are carried as query parameters so Flutter Web
/// reloads/share links preserve the list state.
final class CustomerPortfolioRoute extends AppRoute {
  const CustomerPortfolioRoute({
    required this.orgId,
    required this.companyId,
    this.queryParameters = const <String, String>{},
  });

  final String orgId;
  final String companyId;
  final Map<String, String> queryParameters;

  static const name = 'customerPortfolio';
  static const pathPattern = '/org/:orgId/companies/:companyId/customers';

  @override
  String get location {
    final path = '/org/$orgId/companies/$companyId/customers';
    if (queryParameters.isEmpty) return path;
    return Uri(path: path, queryParameters: queryParameters).toString();
  }
}

/// Customer 360 detail route (TASK-052), scoped by Organization and protected
/// in [AppRouter] by `customer.view`.
final class CustomerDetailRoute extends AppRoute {
  const CustomerDetailRoute({required this.orgId, required this.customerId});

  final String orgId;
  final String customerId;

  static const name = 'customerDetail';
  static const pathPattern = '/org/:orgId/customers/:customerId';

  @override
  String get location => '/org/$orgId/customers/$customerId';
}

/// Route shown to sign a user in (TASK-034).
///
/// [SessionAuthGuard] (TASK-041) redirects here for any unauthenticated
/// request to a protected route, and for one whose session was detected as
/// revoked while navigating. Both cases may carry:
///
/// - [returnTo]: the location that was originally requested, so a future
///   post-login navigation can send the user back there instead of always
///   landing on the same placeholder destination `LoginPage` uses today.
/// - [endedSessionReason]: set only when an already-signed-in session just
///   ended (never for a plain "not signed in yet" redirect), so a future
///   UI can show *why* — e.g. "Sua sessão foi encerrada." Reading this
///   query parameter and rendering that message is not part of TASK-041's
///   scope (no front-end agent is assigned to it): this route only carries
///   the information forward.
final class LoginRoute extends AppRoute {
  const LoginRoute({this.returnTo, this.endedSessionReason});

  final String? returnTo;
  final SessionEndedReason? endedSessionReason;

  static const name = 'login';
  static const pathPattern = '/login';

  @override
  String get location {
    final queryParameters = <String, String>{
      if (returnTo != null && returnTo!.isNotEmpty) 'returnTo': returnTo!,
      if (endedSessionReason != null) 'reason': endedSessionReason!.name,
    };
    if (queryParameters.isEmpty) return pathPattern;
    return Uri(path: pathPattern, queryParameters: queryParameters).toString();
  }
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
/// `SignUpPage` (TASK-035) navigates here on a successful account creation;
/// `OnboardingWizardPage`, once its last step is submitted, navigates away
/// to [AboutAppRoute] with the real Organization id it just created — there
/// is no dedicated "post-onboarding home" route yet (that is a later task's
/// scope), so [AboutAppRoute] is reused as the first real in-app screen.
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

/// Route reached via the deep link/token sent by e-mail when someone is
/// invited to join an Organization (TASK-040, consuming the `Invite`
/// created by TASK-039's `createInvite`).
///
/// Deliberately outside the `/org/:orgId/...` convention every other
/// authenticated route follows: the organization is not known yet when
/// this route is opened — it is resolved from [token] itself, by
/// `validateInvite`, once `AcceptInvitePage` loads. Must never require
/// [AuthGuard]/[ActiveOrganizationGuard] the way protected routes do: an
/// invite link has to work for a visitor who is not signed in at all yet.
final class InviteAcceptanceRoute extends AppRoute {
  const InviteAcceptanceRoute({required this.token});

  final String token;

  static const name = 'inviteAcceptance';
  static const pathPattern = '/invite/:token';

  @override
  String get location => '/invite/$token';
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

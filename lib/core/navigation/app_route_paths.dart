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

/// Temporary company scope used while the real active-company selector is not
/// wired yet, mirroring [kPlaceholderOrganizationId]'s current role.
const kPlaceholderCompanyId = 'default';

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

/// Catalog entry route (TASK-076), the first real in-app screen already
/// available for representatives and customers.
final class CatalogHomeRoute extends AppRoute {
  const CatalogHomeRoute({required this.orgId, this.companyId});

  final String orgId;
  final String? companyId;

  static const name = 'catalogHome';
  static const pathPattern = '/org/:orgId/catalog';

  @override
  String get location {
    final path = '/org/$orgId/catalog';
    final scopedCompanyId = companyId?.trim();
    if (scopedCompanyId == null || scopedCompanyId.isEmpty) return path;
    return Uri(
      path: path,
      queryParameters: <String, String>{'companyId': scopedCompanyId},
    ).toString();
  }
}

/// The catalog's filterable, multi-view-mode browsing screen (TASK-082,
/// EPIC-10) — [queryParameters] carries the active view mode (`mode`) and
/// every `CatalogFilter` dimension (see `CatalogFilter.toQueryParameters`),
/// so a Flutter Web reload/shared link restores exactly the same view.
/// Kept as its own route (not folded into [CatalogHomeRoute]) since the
/// home screen (sections: lançamentos, campanhas, coleções) and this
/// browsing screen (one filterable, paginated grid/list) are different
/// screens with different states to reflect in the URL — same rationale
/// [CustomerPortfolioRoute] already sets apart from a customer's own detail
/// route.
final class CatalogBrowseRoute extends AppRoute {
  const CatalogBrowseRoute({
    required this.orgId,
    this.companyId,
    this.queryParameters = const <String, String>{},
  });

  final String orgId;
  final String? companyId;
  final Map<String, String> queryParameters;

  static const name = 'catalogBrowse';
  static const pathPattern = '/org/:orgId/catalog/browse';

  @override
  String get location {
    final path = '/org/$orgId/catalog/browse';
    final allParameters = <String, String>{
      ...queryParameters,
      if (companyId != null && companyId!.trim().isNotEmpty)
        'companyId': companyId!.trim(),
    };
    if (allParameters.isEmpty) return path;
    return Uri(path: path, queryParameters: allParameters).toString();
  }
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

/// User and permission management route (TASK-042/TASK-043), scoped by
/// Organization. Protected in [AppRouter] by `user.changeRole`.
final class UserManagementRoute extends AppRoute {
  const UserManagementRoute({required this.orgId});

  final String orgId;

  static const name = 'userManagement';
  static const pathPattern = '/org/:orgId/settings/users';

  @override
  String get location => '/org/$orgId/settings/users';
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

/// Product creation form route (TASK-065), scoped by Organization and Company.
/// Protected in [AppRouter] by `catalog.manage`.
final class ProductFormRoute extends AppRoute {
  const ProductFormRoute({required this.orgId, required this.companyId});

  final String orgId;
  final String companyId;

  static const name = 'productForm';
  static const pathPattern = '/org/:orgId/companies/:companyId/products/new';

  @override
  String get location => '/org/$orgId/companies/$companyId/products/new';
}

/// Pedidos listing/tracking route (TASK-102), scoped by Organization and
/// Company. Search and filters are carried as query parameters so Flutter Web
/// reloads/share links preserve the list state, same precedent
/// [CustomerPortfolioRoute] already sets. Protected in [AppRouter] by
/// `order.view`.
final class OrderListRoute extends AppRoute {
  const OrderListRoute({
    required this.orgId,
    required this.companyId,
    this.queryParameters = const <String, String>{},
  });

  final String orgId;
  final String companyId;
  final Map<String, String> queryParameters;

  static const name = 'orderList';
  static const pathPattern = '/org/:orgId/companies/:companyId/orders';

  @override
  String get location {
    final path = '/org/$orgId/companies/$companyId/orders';
    if (queryParameters.isEmpty) return path;
    return Uri(path: path, queryParameters: queryParameters).toString();
  }
}

/// Fila de aprovação de pedidos route (TASK-103), scoped by Organization and
/// Company. Protected in [AppRouter] by `order.approve` — granted today to
/// exactly OWNER/ADMIN/SALES_MANAGER (`RolePermissionMatrix`), the same
/// approvers `OrderListRoute`'s own "vendedor" filter is gated on.
final class OrderApprovalQueueRoute extends AppRoute {
  const OrderApprovalQueueRoute({required this.orgId, required this.companyId});

  final String orgId;
  final String companyId;

  static const name = 'orderApprovalQueue';
  static const pathPattern =
      '/org/:orgId/companies/:companyId/orders/approvals';

  @override
  String get location => '/org/$orgId/companies/$companyId/orders/approvals';
}

/// Pedido history/detail route (TASK-104), scoped by Organization and
/// Company — the "Ver histórico" destination from [OrderListRoute]. Protected
/// in [AppRouter] by `order.view`, the same capability [OrderListRoute]
/// itself requires.
final class OrderHistoryRoute extends AppRoute {
  const OrderHistoryRoute({
    required this.orgId,
    required this.companyId,
    required this.orderId,
  });

  final String orgId;
  final String companyId;
  final String orderId;

  static const name = 'orderHistory';
  static const pathPattern =
      '/org/:orgId/companies/:companyId/orders/:orderId/history';

  @override
  String get location =>
      '/org/$orgId/companies/$companyId/orders/$orderId/history';
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

/// "Novo pedido" (order draft) route (TASK-096, EPIC-13), scoped by
/// Organization and Company. Protected in [AppRouter] by `order.create`.
///
/// [draftId] is carried as a query parameter (not a path segment) so a
/// brand-new draft (no id yet — the seller has not picked a customer) and a
/// resumed one share the same route, same precedent
/// [CustomerPortfolioRoute] already sets for optional list state.
final class OrderDraftRoute extends AppRoute {
  const OrderDraftRoute({
    required this.orgId,
    required this.companyId,
    this.draftId,
  });

  final String orgId;
  final String companyId;
  final String? draftId;

  static const name = 'orderDraft';
  static const pathPattern = '/org/:orgId/companies/:companyId/orders/new';

  @override
  String get location {
    final path = '/org/$orgId/companies/$companyId/orders/new';
    final id = draftId?.trim();
    if (id == null || id.isEmpty) return path;
    return Uri(
      path: path,
      queryParameters: <String, String>{'draftId': id},
    ).toString();
  }
}

/// Catalog browsing screen scoped to an in-progress `Order` draft
/// (TASK-097, EPIC-13) — the "Adicionar produtos" destination from
/// [OrderDraftRoute]. Protected in [AppRouter] by `order.create`, same
/// capability [OrderDraftRoute] itself requires: this route only exists to
/// add items to a draft the seller is already authorized to edit.
final class OrderProductCatalogRoute extends AppRoute {
  const OrderProductCatalogRoute({
    required this.orgId,
    required this.companyId,
    required this.draftId,
  });

  final String orgId;
  final String companyId;
  final String draftId;

  static const name = 'orderProductCatalog';
  static const pathPattern =
      '/org/:orgId/companies/:companyId/orders/:draftId/products';

  @override
  String get location =>
      '/org/$orgId/companies/$companyId/orders/$draftId/products';
}

/// Product detail screen scoped to the same in-progress `Order` draft
/// (TASK-097, EPIC-13) — reached from [OrderProductCatalogRoute] when the
/// seller taps a product; confirming a variant/quantity selection here
/// persists the resulting items straight to [draftId]. Protected in
/// [AppRouter] by the same `order.create` capability.
final class OrderProductDetailRoute extends AppRoute {
  const OrderProductDetailRoute({
    required this.orgId,
    required this.companyId,
    required this.draftId,
    required this.productId,
    this.origin = 'grid',
  });

  final String orgId;
  final String companyId;
  final String draftId;
  final String productId;

  /// Surface the seller tapped the product from (`grid`, `search`,
  /// `favorites`) — carried through into `product_added_to_order`'s own
  /// `source` parameter via `ProductDetailPage.origin`.
  final String origin;

  static const name = 'orderProductDetail';
  static const pathPattern =
      '/org/:orgId/companies/:companyId/orders/:draftId/products/:productId';

  @override
  String get location {
    final path =
        '/org/$orgId/companies/$companyId/orders/$draftId/products/$productId';
    return Uri(
      path: path,
      queryParameters: <String, String>{'origin': origin},
    ).toString();
  }
}

/// Lista de conflitos de sincronização pendentes (TASK-111, EPIC-14),
/// scoped by Organization only — a [ConflictRecord] carries `companyId` as
/// optional metadata, never as a required scope, so this route (unlike
/// [OrderListRoute]/[CustomerPortfolioRoute]) is not nested under
/// `companies/:companyId`.
final class ConflictListRoute extends AppRoute {
  const ConflictListRoute({required this.orgId});

  final String orgId;

  static const name = 'conflictList';
  static const pathPattern = '/org/:orgId/sync/conflicts';

  @override
  String get location => '/org/$orgId/sync/conflicts';
}

/// Conflict detail/resolution route (TASK-111, EPIC-14) — the "Resolver"
/// destination from [ConflictListRoute], scoped by Organization and the
/// individual `ConflictRecord.id`.
final class ConflictDetailRoute extends AppRoute {
  const ConflictDetailRoute({required this.orgId, required this.conflictId});

  final String orgId;
  final String conflictId;

  static const name = 'conflictDetail';
  static const pathPattern = '/org/:orgId/sync/conflicts/:conflictId';

  @override
  String get location => '/org/$orgId/sync/conflicts/$conflictId';
}

/// Central de Sincronização (TASK-112, EPIC-14): transparency dashboard over
/// Outbox pendencies (TASK-108), sync failures (TASK-109) with manual retry,
/// and the shortcut into [ConflictListRoute] for open conflicts — scoped by
/// Organization *and* Company because it also renders the TASK-107 "última
/// carga completa" marker per entity, itself an Organization+Company scope
/// (`OfflinePackageStatusRepository`), unlike [ConflictListRoute].
final class SyncCenterRoute extends AppRoute {
  const SyncCenterRoute({required this.orgId, required this.companyId});

  final String orgId;
  final String companyId;

  static const name = 'syncCenter';
  static const pathPattern = '/org/:orgId/companies/:companyId/sync';

  @override
  String get location => '/org/$orgId/companies/$companyId/sync';
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
/// to [CatalogHomeRoute] with the real Organization id it just created —
/// that is the app's real post-onboarding home.
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

/// Route reached via the link a vendor sends a customer to view a shared
/// catalog selection (TASK-081, consuming the `CatalogShare` created by
/// `createCatalogShareLink`).
///
/// Deliberately outside the `/org/:orgId/...` convention every other
/// authenticated route follows, same rationale as [InviteAcceptanceRoute]:
/// the organization is not known ahead of time here — it is resolved from
/// [token] itself, by `getCatalogShareLink`, once `CatalogSharePublicPage`
/// loads. Must never require [AuthGuard]/[ActiveOrganizationGuard] the way
/// protected routes do: a share link has to work for a customer who is not
/// signed in at all (TASK-081: "sem exigir login do cliente").
final class CatalogSharePublicRoute extends AppRoute {
  const CatalogSharePublicRoute({required this.token});

  final String token;

  static const name = 'catalogSharePublic';
  static const pathPattern = '/share/:token';

  @override
  String get location => '/share/$token';
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

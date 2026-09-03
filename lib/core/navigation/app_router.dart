import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../permissions/permissions.dart';
import 'active_organization_guard.dart';
import 'app_route_paths.dart';
import 'auth_guard.dart';
import 'authorization_guard.dart';
import 'widgets/forbidden_page.dart';
import 'widgets/not_found_page.dart';

/// Single navigation entry point for VestiPro.
///
/// No feature may create its own [GoRouter] or navigate through raw
/// [Navigator] calls or string routes. Every authenticated route lives
/// under the `/org/:orgId/...` convention documented in
/// `docs/architecture/navigation.md`, and every guard is declared here so a
/// feature never has to reimplement one.
class AppRouter {
  AppRouter({
    required this.aboutAppPageBuilder,
    required this.catalogHomePageBuilder,
    required this.auditLogPageBuilder,
    required this.userManagementPageBuilder,
    this.targetDashboardPageBuilder,
    required this.loginPageBuilder,
    required this.signUpPageBuilder,
    required this.forgotPasswordPageBuilder,
    required this.onboardingWizardPageBuilder,
    required this.acceptInvitePageBuilder,
    required this.catalogSharePublicPageBuilder,
    this.customerFormPageBuilder,
    this.productFormPageBuilder,
    this.customerPortfolioPageBuilder,
    this.customerDetailPageBuilder,
    this.catalogBrowsePageBuilder,
    this.orderListPageBuilder,
    this.orderApprovalQueuePageBuilder,
    this.orderHistoryPageBuilder,
    this.orderDraftPageBuilder,
    this.orderProductCatalogPageBuilder,
    this.orderProductDetailPageBuilder,
    this.conflictListPageBuilder,
    this.conflictDetailPageBuilder,
    this.syncCenterPageBuilder,
    this.opportunityCenterPageBuilder,
    this.executiveDashboardPageBuilder,
    AuthGuard? authGuard,
    ActiveOrganizationGuard? organizationGuard,
    AuthorizationGuard? authorizationGuard,
  }) : authGuard = authGuard ?? const AlwaysAllowAuthGuard(),
       organizationGuard =
           organizationGuard ?? const AlwaysAllowActiveOrganizationGuard(),
       authorizationGuard =
           authorizationGuard ?? const AlwaysAllowAuthorizationGuard();

  final AuthGuard authGuard;
  final ActiveOrganizationGuard organizationGuard;
  final AuthorizationGuard authorizationGuard;
  final Widget Function(BuildContext context, String orgId) aboutAppPageBuilder;
  final Widget Function(BuildContext context, String orgId, String? companyId)
  catalogHomePageBuilder;
  final Widget Function(BuildContext context, String orgId) auditLogPageBuilder;
  final Widget Function(BuildContext context, String orgId)
  userManagementPageBuilder;
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  targetDashboardPageBuilder;
  final Widget Function(BuildContext context, String orgId, String companyId)?
  customerFormPageBuilder;
  final Widget Function(BuildContext context, String orgId, String companyId)?
  productFormPageBuilder;
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  customerPortfolioPageBuilder;
  final Widget Function(BuildContext context, String orgId, String customerId)?
  customerDetailPageBuilder;

  /// Builds the pedidos listing/tracking screen (TASK-102), given
  /// `orgId`/`companyId` and the raw `queryParameters` of [OrderListRoute] —
  /// same "router hands raw params, page owns parsing" contract
  /// [customerPortfolioPageBuilder] already sets.
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  orderListPageBuilder;

  /// Builds the fila de aprovação de pedidos screen (TASK-103), given
  /// `orgId`/`companyId` from [OrderApprovalQueueRoute].
  final Widget Function(BuildContext context, String orgId, String companyId)?
  orderApprovalQueuePageBuilder;

  /// Builds the pedido history/detail screen (TASK-104), given
  /// `orgId`/`companyId`/`orderId` from [OrderHistoryRoute].
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    String orderId,
  )?
  orderHistoryPageBuilder;

  /// Builds the "novo pedido" screen (TASK-096), given `orgId`/`companyId`
  /// and the raw `queryParameters` of [OrderDraftRoute] — the caller decides
  /// how to turn `draftId` into the resume flow, same "router hands raw
  /// params, page owns parsing" contract [customerPortfolioPageBuilder]
  /// already sets.
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  orderDraftPageBuilder;

  /// Builds the catalog screen scoped to an in-progress `Order` draft
  /// (TASK-097), given `orgId`/`companyId`/`draftId` from
  /// [OrderProductCatalogRoute].
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    String draftId,
  )?
  orderProductCatalogPageBuilder;

  /// Builds the product detail screen scoped to the same in-progress `Order`
  /// draft (TASK-097), given `orgId`/`companyId`/`draftId`/`productId` and
  /// the raw `queryParameters` of [OrderProductDetailRoute] (`origin`).
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    String draftId,
    String productId,
    Map<String, String> queryParameters,
  )?
  orderProductDetailPageBuilder;

  /// Builds the pending-conflicts list screen (TASK-111), given `orgId` from
  /// [ConflictListRoute].
  final Widget Function(BuildContext context, String orgId)?
  conflictListPageBuilder;

  /// Builds the conflict comparison/resolution screen (TASK-111), given
  /// `orgId`/`conflictId` from [ConflictDetailRoute].
  final Widget Function(BuildContext context, String orgId, String conflictId)?
  conflictDetailPageBuilder;

  /// Builds the Central de Sincronização screen (TASK-112), given
  /// `orgId`/`companyId` from [SyncCenterRoute].
  final Widget Function(BuildContext context, String orgId, String companyId)?
  syncCenterPageBuilder;

  /// Builds the Central de Oportunidades screen (TASK-132), given
  /// `orgId`/`companyId` and the raw `queryParameters` of
  /// [OpportunityCenterRoute] — the caller decides how to turn those into an
  /// `OpportunityCenterFilters`, same "router hands raw params, page owns
  /// parsing" contract [customerPortfolioPageBuilder] already sets.
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  opportunityCenterPageBuilder;

  /// Builds the Executive Dashboard screen (TASK-134), given
  /// `orgId`/`companyId` and the raw `queryParameters` of
  /// [ExecutiveDashboardRoute] — the caller decides how to turn those into
  /// an `ExecutiveDashboardFilters`, same "router hands raw params, page
  /// owns parsing" contract [opportunityCenterPageBuilder] already sets.
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  executiveDashboardPageBuilder;

  /// Builds the catalog's filterable browsing screen (TASK-082), given
  /// `orgId` and the raw `queryParameters` of [CatalogBrowseRoute] — the
  /// caller decides how to turn those into a `CatalogViewMode`/
  /// `CatalogFilter`, same "router hands raw params, page owns parsing"
  /// contract [customerPortfolioPageBuilder] already sets.
  final Widget Function(
    BuildContext context,
    String orgId,
    Map<String, String> queryParameters,
  )?
  catalogBrowsePageBuilder;

  /// Builds the real login screen (TASK-034). Injected from `VestiProApp`
  /// instead of imported here so `lib/core/navigation/` never depends on a
  /// concrete `lib/features/authentication/` widget — same composition
  /// rationale as [aboutAppPageBuilder].
  final WidgetBuilder loginPageBuilder;

  /// Builds the real sign-up screen (TASK-035). Same composition rationale
  /// as [loginPageBuilder].
  final WidgetBuilder signUpPageBuilder;

  /// Builds the real "forgot password" screen (TASK-036). Same composition
  /// rationale as [loginPageBuilder].
  final WidgetBuilder forgotPasswordPageBuilder;

  /// Builds the real onboarding wizard screen (TASK-038). Same composition
  /// rationale as [loginPageBuilder].
  final WidgetBuilder onboardingWizardPageBuilder;

  /// Builds the real invite-acceptance screen (TASK-040), given the `token`
  /// path parameter extracted from [InviteAcceptanceRoute]. Same
  /// composition rationale as [loginPageBuilder].
  final Widget Function(BuildContext context, String token)
  acceptInvitePageBuilder;

  /// Builds the real public catalog share screen (TASK-081), given the
  /// `token` path parameter extracted from [CatalogSharePublicRoute]. Same
  /// composition rationale as [loginPageBuilder].
  final Widget Function(BuildContext context, String token)
  catalogSharePublicPageBuilder;

  late final GoRouter router = GoRouter(
    initialLocation: const CatalogHomeRoute(
      orgId: kPlaceholderOrganizationId,
    ).location,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: CatalogHomeRoute.pathPattern,
        name: CatalogHomeRoute.name,
        builder: (context, state) => catalogHomePageBuilder(
          context,
          state.pathParameters['orgId']!,
          state.uri.queryParameters['companyId'],
        ),
      ),
      GoRoute(
        path: CatalogBrowseRoute.pathPattern,
        name: CatalogBrowseRoute.name,
        builder: (context, state) {
          final builder = catalogBrowsePageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: AboutAppRoute.pathPattern,
        name: AboutAppRoute.name,
        builder: (context, state) =>
            aboutAppPageBuilder(context, state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: AuditLogRoute.pathPattern,
        name: AuditLogRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.auditLogView,
        ),
        builder: (context, state) =>
            auditLogPageBuilder(context, state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: UserManagementRoute.pathPattern,
        name: UserManagementRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.userChangeRole,
        ),
        builder: (context, state) =>
            userManagementPageBuilder(context, state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: TargetDashboardRoute.pathPattern,
        name: TargetDashboardRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.targetView,
        ),
        builder: (context, state) {
          final builder = targetDashboardPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: OpportunityCenterRoute.pathPattern,
        name: OpportunityCenterRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.insightView,
        ),
        builder: (context, state) {
          final builder = opportunityCenterPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: ExecutiveDashboardRoute.pathPattern,
        name: ExecutiveDashboardRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.reportViewSensitive,
        ),
        builder: (context, state) {
          final builder = executiveDashboardPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: OrderListRoute.pathPattern,
        name: OrderListRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderView,
        ),
        builder: (context, state) {
          final builder = orderListPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: OrderApprovalQueueRoute.pathPattern,
        name: OrderApprovalQueueRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderApprove,
        ),
        builder: (context, state) {
          final builder = orderApprovalQueuePageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
          );
        },
      ),
      GoRoute(
        path: OrderHistoryRoute.pathPattern,
        name: OrderHistoryRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderView,
        ),
        builder: (context, state) {
          final builder = orderHistoryPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.pathParameters['orderId']!,
          );
        },
      ),
      GoRoute(
        path: CustomerPortfolioRoute.pathPattern,
        name: CustomerPortfolioRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.customerView,
        ),
        builder: (context, state) {
          final builder = customerPortfolioPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: CustomerDetailRoute.pathPattern,
        name: CustomerDetailRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.customerView,
        ),
        builder: (context, state) {
          final builder = customerDetailPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['customerId']!,
          );
        },
      ),
      GoRoute(
        path: OrderDraftRoute.pathPattern,
        name: OrderDraftRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderCreate,
        ),
        builder: (context, state) {
          final builder = orderDraftPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: OrderProductCatalogRoute.pathPattern,
        name: OrderProductCatalogRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderCreate,
        ),
        builder: (context, state) {
          final builder = orderProductCatalogPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.pathParameters['draftId']!,
          );
        },
      ),
      GoRoute(
        path: OrderProductDetailRoute.pathPattern,
        name: OrderProductDetailRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.orderCreate,
        ),
        builder: (context, state) {
          final builder = orderProductDetailPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.pathParameters['draftId']!,
            state.pathParameters['productId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: ConflictListRoute.pathPattern,
        name: ConflictListRoute.name,
        builder: (context, state) {
          final builder = conflictListPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(context, state.pathParameters['orgId']!);
        },
      ),
      GoRoute(
        path: ConflictDetailRoute.pathPattern,
        name: ConflictDetailRoute.name,
        builder: (context, state) {
          final builder = conflictDetailPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['conflictId']!,
          );
        },
      ),
      GoRoute(
        path: SyncCenterRoute.pathPattern,
        name: SyncCenterRoute.name,
        builder: (context, state) {
          final builder = syncCenterPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
          );
        },
      ),
      GoRoute(
        path: CustomerFormRoute.pathPattern,
        name: CustomerFormRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.customerCreate,
        ),
        builder: (context, state) {
          final builder = customerFormPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
          );
        },
      ),
      GoRoute(
        path: ProductFormRoute.pathPattern,
        name: ProductFormRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.catalogManage,
        ),
        builder: (context, state) {
          final builder = productFormPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
          );
        },
      ),
      GoRoute(
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => loginPageBuilder(context),
      ),
      GoRoute(
        path: SignUpRoute.pathPattern,
        name: SignUpRoute.name,
        builder: (context, state) => signUpPageBuilder(context),
      ),
      GoRoute(
        path: PasswordResetRoute.pathPattern,
        name: PasswordResetRoute.name,
        builder: (context, state) => forgotPasswordPageBuilder(context),
      ),
      GoRoute(
        path: OnboardingWizardRoute.pathPattern,
        name: OnboardingWizardRoute.name,
        builder: (context, state) => onboardingWizardPageBuilder(context),
      ),
      GoRoute(
        path: InviteAcceptanceRoute.pathPattern,
        name: InviteAcceptanceRoute.name,
        builder: (context, state) =>
            acceptInvitePageBuilder(context, state.pathParameters['token']!),
      ),
      GoRoute(
        path: CatalogSharePublicRoute.pathPattern,
        name: CatalogSharePublicRoute.name,
        builder: (context, state) => catalogSharePublicPageBuilder(
          context,
          state.pathParameters['token']!,
        ),
      ),
      GoRoute(
        path: ForbiddenRoute.pathPattern,
        name: ForbiddenRoute.name,
        builder: (context, state) => const ForbiddenPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final authRedirect = await authGuard.redirect(context, state);
    if (authRedirect != null) return authRedirect;
    if (!context.mounted) return null;

    return organizationGuard.redirect(context, state);
  }
}

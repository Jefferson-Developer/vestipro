import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics/analytics.dart';
import '../core/auth/auth.dart';
import '../core/connectivity/connectivity.dart';
import '../core/design_system/design_system.dart';
import '../core/environment/app_environment.dart';
import '../core/errors/errors.dart';
import '../core/feature_flags/feature_flags.dart';
import '../core/navigation/navigation.dart';
import '../core/permissions/permissions.dart';
import '../core/services/services.dart';
import '../features/authentication/authentication.dart';
import '../features/authentication/presentation/bloc/forgot_password_bloc.dart';
import '../features/authentication/presentation/bloc/login_bloc.dart';
import '../features/authentication/presentation/bloc/sign_up_bloc.dart';
import '../features/audit_log/audit_log.dart';
import '../features/catalog/catalog.dart';
import '../features/customers/customers.dart';
import '../features/catalog_share/catalog_share.dart';
import '../features/dashboards/dashboards.dart';
import '../features/insights/insights.dart';
import '../features/invites/invites.dart';
import '../features/onboarding/onboarding.dart';
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../features/orders/orders.dart';
import '../features/organizations/organizations.dart';
import '../features/products/products.dart';
import '../core/sync/sync.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
import '../features/targets/targets.dart';
import '../features/users/users.dart';
import '../firebase_options.dart';
import 'firebase_bootstrap_error_app.dart';
import 'injection.dart';
import 'vestipro_bloc_observer.dart';

/// Central bootstrap for every entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`). Firebase must be initialized here, and only here: no
/// feature is allowed to call `Firebase.initializeApp` on its own.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    final exception = FirebaseInitializationException(
      'Falha ao inicializar o Firebase para o ambiente '
      '"${environment.value}".',
      cause: error,
      stackTrace: stackTrace,
    );
    _reportBootstrapFailure(exception);
    runApp(
      FirebaseBootstrapErrorApp(
        environment: environment,
        errorDetail: exception.toString(),
        onRetry: () => bootstrap(environment),
      ),
    );
    return;
  }

  usePathUrlStrategy();
  Bloc.observer = const VestiProBlocObserver();
  configureDependencies(environment);
  configureGlobalErrorHandlers();
  runApp(VestiProApp(environment: environment));
}

void _reportBootstrapFailure(FirebaseInitializationException exception) {
  developer.log(
    exception.toString(),
    name: 'vestipro.bootstrap',
    level: 1000,
    error: exception.cause,
    stackTrace: exception.stackTrace,
  );
}

/// Routes every uncaught Flutter framework error and every uncaught async
/// error to [CrashReporter] (TASK-016), preserving whatever default handling
/// (console logging, the debug red screen) was already installed.
///
/// [resolveCrashReporter] defaults to resolving [CrashReporter] from [getIt]
/// — but only inside the handler closures below, i.e. only when an error is
/// actually reported, never eagerly at bootstrap time. Overridable so tests
/// can assert on the wiring itself without a real Firebase Crashlytics
/// instance.
@visibleForTesting
void configureGlobalErrorHandlers({
  CrashReporter Function()? resolveCrashReporter,
}) {
  final resolve = resolveCrashReporter ?? () => getIt<CrashReporter>();

  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutterOnError?.call(details);
    if (isUnexpectedError(details.exception)) {
      unawaited(
        resolve().recordError(
          details.exception,
          details.stack,
          reason: details.library,
          fatal: true,
        ),
      );
    }
  };

  // Uses the real `dart:ui` singleton directly, not
  // `WidgetsBinding.instance.platformDispatcher` — in a `flutter_test`
  // environment the latter is a `TestPlatformDispatcher` whose `onError`
  // setter is a deliberate no-op, so setting it there would silently never
  // fire. `PlatformDispatcher.instance` behaves identically in production
  // and is what Firebase's own Crashlytics setup guide recommends.
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (isUnexpectedError(error)) {
      unawaited(resolve().recordError(error, stackTrace, fatal: true));
    }
    return previousPlatformOnError?.call(error, stackTrace) ?? true;
  };
}

class VestiProApp extends StatelessWidget {
  const VestiProApp({required this.environment, this.router, super.key});

  final AppEnvironment environment;

  /// Overridable for tests. Defaults to the real [AppRouter] wired to the
  /// example module.
  final AppRouter? router;

  @override
  Widget build(BuildContext context) {
    final appRouter =
        router ??
        AppRouter(
          // TASK-041: the only place a session-aware [AuthGuard] gets wired
          // for real — [AppRouter] itself keeps [AlwaysAllowAuthGuard] as
          // its own default so tests/examples that build their own
          // [AppRouter] are unaffected unless they opt in.
          authGuard: SessionAuthGuard(getIt<SessionService>()),
          organizationGuard: const _LazyActiveOrganizationGuard(),
          authorizationGuard: const _LazyPermissionAuthorizationGuard(),
          aboutAppPageBuilder: (context, orgId) => AboutAppPage(
            createBloc: () => getIt<AboutAppBloc>(),
            showInsightsShortcut: _resolveShowInsightsShortcut(),
          ),
          catalogHomePageBuilder: (context, orgId, companyId) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId ?? kPlaceholderCompanyId,
                child: CatalogHomePage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  createBloc: () => getIt<CatalogHomeBloc>(),
                  onCreateProductTap: () => context.go(
                    ProductFormRoute(
                      orgId: orgId,
                      companyId: companyId ?? kPlaceholderCompanyId,
                    ).location,
                  ),
                ),
              ),
          auditLogPageBuilder: (context, orgId) => AuditLogPage(
            organizationId: orgId,
            userId: getIt<AuthRepository>().currentUser?.uid ?? '',
            permissionService: getIt<PermissionService>(),
            createBloc: () => AuditLogBloc(
              listAuditLogEntries: getIt<ListAuditLogEntriesUseCase>(),
            ),
          ),
          userManagementPageBuilder: (context, orgId) => UserListPage(
            organizationId: orgId,
            userId: getIt<AuthRepository>().currentUser?.uid ?? '',
            permissionService: getIt<PermissionService>(),
            createBloc: () => getIt<UserListBloc>(),
            createRoleEditBloc: () => getIt<UserRoleEditBloc>(),
          ),
          targetDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: TargetDashboardPage(
                      organizationId: orgId,
                      companyId: companyId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      initialTargetId: queryParameters['targetId'],
                      createCubit: () => getIt<TargetDashboardCubit>(),
                    ),
                  ),
          opportunityCenterPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: OpportunityCenterPage(
                      organizationId: orgId,
                      companyId: companyId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<OpportunityCenterBloc>(),
                      initialFilters:
                          OpportunityCenterFilters.fromQueryParameters(
                            queryParameters,
                          ),
                      onUrlStateChanged: (filters) => context.go(
                        OpportunityCenterRoute(
                          orgId: orgId,
                          companyId: companyId,
                          queryParameters: filters.toQueryParameters(),
                        ).location,
                      ),
                      onActionExecuted: (insight, action) =>
                          _navigateForInsightAction(
                            context: context,
                            orgId: orgId,
                            companyId: companyId,
                            action: action,
                          ),
                    ),
                  ),
          executiveDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: ExecutiveDashboardPage(
                      organizationId: orgId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<ExecutiveDashboardBloc>(),
                      initialFilters:
                          ExecutiveDashboardFilters.fromQueryParameters(
                            queryParameters,
                            defaultCompanyId: companyId,
                          ),
                      onUrlStateChanged: (filters) => context.go(
                        ExecutiveDashboardRoute(
                          orgId: orgId,
                          companyId: filters.companyId,
                          queryParameters: filters.toQueryParameters(),
                        ).location,
                      ),
                      onOpenOpportunityCenter: () => context.go(
                        OpportunityCenterRoute(
                          orgId: orgId,
                          companyId: companyId,
                        ).location,
                      ),
                    ),
                  ),
          salesDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: SalesDashboardPage(
                      organizationId: orgId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<SalesDashboardBloc>(),
                      initialFilters: SalesDashboardFilters.fromQueryParameters(
                        queryParameters,
                        defaultCompanyId: companyId,
                      ),
                      onUrlStateChanged: (filters) => context.go(
                        SalesDashboardRoute(
                          orgId: orgId,
                          companyId: filters.companyId,
                          queryParameters: filters.toQueryParameters(),
                        ).location,
                      ),
                      onDrillDownToOrders: (orderFilters) => context.go(
                        OrderListRoute(
                          orgId: orgId,
                          companyId: companyId,
                          queryParameters: orderFilters.toQueryParameters(),
                        ).location,
                      ),
                    ),
                  ),
          customerDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: CustomerDashboardPage(
                      organizationId: orgId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<CustomerDashboardBloc>(),
                      initialFilters:
                          CustomerDashboardFilters.fromQueryParameters(
                            queryParameters,
                            defaultCompanyId: companyId,
                          ),
                      onUrlStateChanged: (filters) => context.go(
                        CustomerDashboardRoute(
                          orgId: orgId,
                          companyId: filters.companyId,
                          queryParameters: filters.toQueryParameters(),
                        ).location,
                      ),
                      onDrillDownToCustomer: (customerId) => context.go(
                        CustomerDetailRoute(
                          orgId: orgId,
                          customerId: customerId,
                        ).location,
                      ),
                    ),
                  ),
          productDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: ProductDashboardPage(
                      organizationId: orgId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<ProductDashboardBloc>(),
                      initialFilters:
                          ProductDashboardFilters.fromQueryParameters(
                            queryParameters,
                            defaultCompanyId: companyId,
                          ),
                      onUrlStateChanged: (filters) => context.go(
                        ProductDashboardRoute(
                          orgId: orgId,
                          companyId: filters.companyId,
                          queryParameters: filters.toQueryParameters(),
                        ).location,
                      ),
                      onDrillDownToProduct: (productId) => context.go(
                        ProductDetailRoute(
                          orgId: orgId,
                          productId: productId,
                        ).location,
                      ),
                    ),
                  ),
          productDetailPageBuilder: (context, orgId, productId) =>
              ProductDetailPage(
                organizationId: orgId,
                productId: productId,
                createBloc: () => getIt<ProductDetailBloc>(),
              ),
          customerFormPageBuilder: (context, orgId, companyId) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: CustomerFormPage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<CustomerFormBloc>(),
                ),
              ),
          productFormPageBuilder: (context, orgId, companyId) {
            final currentUser = getIt<AuthRepository>().currentUser;
            return _withConnectivityIndicator(
              orgId: orgId,
              companyId: companyId,
              child: ProductFormPage(
                organizationId: orgId,
                companyId: companyId,
                userId: currentUser?.uid ?? '',
                actorName:
                    currentUser?.displayName ?? currentUser?.email ?? 'Usuário',
                permissionService: getIt<PermissionService>(),
                createBloc: () => getIt<ProductFormBloc>(),
                createMediaBloc: () => getIt<ProductMediaBloc>(),
              ),
            );
          },
          customerPortfolioPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: CustomerPortfolioPage(
                      organizationId: orgId,
                      companyId: companyId,
                      userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                      permissionService: getIt<PermissionService>(),
                      createBloc: () => getIt<CustomerPortfolioBloc>(),
                      createSegmentBloc: () => getIt<CustomerSegmentBloc>(),
                      onCustomerSelected: (customer) => context.go(
                        CustomerDetailRoute(
                          orgId: orgId,
                          customerId: customer.id,
                        ).location,
                      ),
                      initialSearchQuery: queryParameters['q'] ?? '',
                      initialFilters:
                          CustomerPortfolioFilters.fromQueryParameters(
                            queryParameters,
                          ),
                      onUrlStateChanged: (searchQuery, filters) => context.go(
                        CustomerPortfolioRoute(
                          orgId: orgId,
                          companyId: companyId,
                          queryParameters: filters.toQueryParameters(
                            search: searchQuery,
                          ),
                        ).location,
                      ),
                    ),
                  ),
          orderListPageBuilder: (context, orgId, companyId, queryParameters) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: OrderListPage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<OrderListBloc>(),
                  initialSearchQuery: queryParameters['q'] ?? '',
                  initialFilters: OrderListFilters.fromQueryParameters(
                    queryParameters,
                  ),
                  onOrderDraftSelected: (order) => context.go(
                    OrderDraftRoute(
                      orgId: orgId,
                      companyId: companyId,
                      draftId: order.id,
                    ).location,
                  ),
                  onOrderHistorySelected: (order) => context.go(
                    OrderHistoryRoute(
                      orgId: orgId,
                      companyId: companyId,
                      orderId: order.id,
                    ).location,
                  ),
                  onUrlStateChanged: (searchQuery, filters) => context.go(
                    OrderListRoute(
                      orgId: orgId,
                      companyId: companyId,
                      queryParameters: filters.toQueryParameters(
                        search: searchQuery,
                      ),
                    ).location,
                  ),
                ),
              ),
          orderApprovalQueuePageBuilder: (context, orgId, companyId) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: OrderApprovalQueuePage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<OrderApprovalQueueBloc>(),
                ),
              ),
          orderHistoryPageBuilder: (context, orgId, companyId, orderId) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: OrderHistoryPage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  orderId: orderId,
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<OrderHistoryBloc>(),
                  createDuplicationCubit: () => getIt<OrderDuplicationCubit>(),
                  onDuplicated: (order) => context.go(
                    OrderDraftRoute(
                      orgId: orgId,
                      companyId: companyId,
                      draftId: order.id,
                    ).location,
                  ),
                ),
              ),
          orderDraftPageBuilder: (context, orgId, companyId, queryParameters) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: OrderDraftPage(
                  organizationId: orgId,
                  companyId: companyId,
                  sellerId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<OrderDraftBloc>(),
                  createCustomerPortfolioBloc: () =>
                      getIt<CustomerPortfolioBloc>(),
                  createOrderItemsGridCubit: () => getIt<OrderItemsGridCubit>(),
                  createOrderPricingSummaryCubit: () =>
                      getIt<OrderPricingSummaryCubit>(),
                  createOrderSubmissionValidationCubit: () =>
                      getIt<OrderSubmissionValidationCubit>(),
                  draftId: queryParameters['draftId'],
                  onContinueToProducts: (order) async {
                    await context.push(
                      OrderProductCatalogRoute(
                        orgId: orgId,
                        companyId: companyId,
                        draftId: order.id,
                      ).location,
                    );
                  },
                  onSubmitOrder: (order) => _submitOrder(context, order),
                ),
              ),
          orderProductCatalogPageBuilder:
              (context, orgId, companyId, draftId) =>
                  _withConnectivityIndicator(
                    orgId: orgId,
                    companyId: companyId,
                    child: OrderProductCatalogPage(
                      organizationId: orgId,
                      companyId: companyId,
                      draftId: draftId,
                      createCatalogFilterBloc: () => getIt<CatalogFilterBloc>(),
                      createItemsCounterCubit: () =>
                          getIt<OrderItemsCounterCubit>(),
                    ),
                  ),
          orderProductDetailPageBuilder:
              (
                context,
                orgId,
                companyId,
                draftId,
                productId,
                queryParameters,
              ) => _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: OrderProductAdditionPage(
                  organizationId: orgId,
                  companyId: companyId,
                  draftId: draftId,
                  productId: productId,
                  origin: queryParameters['origin'] ?? 'grid',
                  createProductDetailBloc: () => getIt<ProductDetailBloc>(),
                  createAdditionCubit: () => getIt<OrderProductAdditionCubit>(),
                ),
              ),
          conflictListPageBuilder: (context, orgId) => ConflictListPage(
            organizationId: orgId,
            createCubit: () => getIt<ConflictListCubit>(),
            onConflictSelected: (conflict) => context.go(
              ConflictDetailRoute(
                orgId: orgId,
                conflictId: conflict.id,
              ).location,
            ),
          ),
          conflictDetailPageBuilder: (context, orgId, conflictId) =>
              ConflictDetailPage(
                conflictId: conflictId,
                resolvedBy: getIt<AuthRepository>().currentUser?.uid ?? '',
                createCubit: () => getIt<ConflictResolutionCubit>(),
                onResolved: (_) =>
                    context.go(ConflictListRoute(orgId: orgId).location),
              ),
          syncCenterPageBuilder: (context, orgId, companyId) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: SyncCenterPage(
                  organizationId: orgId,
                  companyId: companyId,
                  createCubit: () => getIt<SyncCenterCubit>(),
                  onOpenConflicts: () =>
                      context.go(ConflictListRoute(orgId: orgId).location),
                ),
              ),
          catalogBrowsePageBuilder: (context, orgId, queryParameters) =>
              _withConnectivityIndicator(
                orgId: orgId,
                companyId:
                    queryParameters['companyId'] ?? kPlaceholderCompanyId,
                child: CatalogFilterPage(
                  organizationId: orgId,
                  companyId: queryParameters['companyId'],
                  createBloc: () => getIt<CatalogFilterBloc>(),
                  initialViewMode: queryParameters.containsKey('mode')
                      ? CatalogViewMode.fromCode(queryParameters['mode'])
                      : null,
                  initialFilter: CatalogFilter.fromQueryParameters(
                    queryParameters,
                  ),
                  onProductSelected: (product) =>
                      context.go(CatalogBrowseRoute(orgId: orgId).location),
                  onUrlStateChanged: (viewMode, filter) => context.go(
                    CatalogBrowseRoute(
                      orgId: orgId,
                      queryParameters: <String, String>{
                        'mode': viewMode.code,
                        ...filter.toQueryParameters(),
                      },
                    ).location,
                  ),
                ),
              ),
          customerDetailPageBuilder: (context, orgId, customerId) =>
              CustomerDetailPage(
                organizationId: orgId,
                customerId: customerId,
                userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                permissionService: getIt<PermissionService>(),
                createBloc: () => getIt<CustomerDetailBloc>(),
              ),
          loginPageBuilder: (context) =>
              LoginPage(createBloc: () => getIt<LoginBloc>()),
          signUpPageBuilder: (context) =>
              SignUpPage(createBloc: () => getIt<SignUpBloc>()),
          forgotPasswordPageBuilder: (context) =>
              ForgotPasswordPage(createBloc: () => getIt<ForgotPasswordBloc>()),
          onboardingWizardPageBuilder: (context) =>
              OnboardingWizardPage(createBloc: () => getIt<OnboardingBloc>()),
          acceptInvitePageBuilder: (context, token) => AcceptInvitePage(
            token: token,
            createBloc: () => getIt<AcceptInviteBloc>(),
            createSignUpBloc: () => getIt<SignUpBloc>(),
          ),
          catalogSharePublicPageBuilder: (context, token) =>
              CatalogSharePublicPage(
                token: token,
                createBloc: () => getIt<CatalogSharePublicBloc>(),
              ),
        );

    return MaterialApp.router(
      title: environment.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter.router,
    );
  }
}

/// Handles "Enviar pedido" (EPIC-13, TASK-101): submits [order] through the
/// idempotent `submitOrder` Cloud Function — the only place a definitive
/// `orderNumber`, price/estoque revalidation and the `submitted` transition
/// are decided — then reconciles the local offline draft with whatever the
/// server actually persisted (`status`/`syncStatus`/the new
/// `OrderStatusHistoryEntry`), so the seller's own device never keeps
/// showing a stale `draft`/`pendingSync` copy once the order has truly
/// reached the backend. The outcome is always surfaced through a
/// [SnackBar] — success or failure — never silently, matching every other
/// autosave/failure surface already on `OrderDraftPage`.
///
/// Navigates back to [CatalogHomeRoute] on success: EPIC-13 has no order
/// list/confirmation screen yet (TASK-102's own scope), so the catalog home
/// is simply the closest existing "there is nothing else to do here"
/// destination — a later task can replace this with a proper order detail/
/// confirmation route without touching anything else in this flow.
Future<void> _submitOrder(BuildContext context, Order order) async {
  await submitOrderFromDraft(
    context: context,
    order: order,
    submitOrderUseCase: getIt<SubmitOrderUseCase>(),
    saveOrderDraftUseCase: getIt<SaveOrderDraftUseCase>(),
    navigateTo: (location) => context.go(location),
  );
}

/// Resolves the already-existing, already-validated destination for an
/// `Insight`'s quick/secondary action (TASK-132) — the Central de
/// Oportunidades itself never hard-codes another feature's route (same
/// composition-root contract `_submitOrder`/`onOrderDraftSelected` already
/// follow), so every `InsightActionType` is mapped here to a real
/// [AppRoute] already reachable elsewhere in the app.
///
/// Every action type carrying a `customerId` (open cliente, agendar
/// contato, iniciar pedido, ver histórico/oportunidades, ...) resolves to
/// [CustomerDetailRoute]: the customer 360 (TASK-052) is the one existing
/// hub that already hosts CRM activities/follow-ups (TASK-059/060), order
/// history and "próxima melhor ação" (TASK-063) for that customer — never a
/// second, bespoke screen per insight type. `resumeOrder` resolves to the
/// abandoned draft itself via [OrderDraftRoute]. Action types with neither
/// (pure product/seller-level insights, e.g. `suggestCampaign`/
/// `notifyReplenishment`/`viewSellerDetail`) have no dedicated destination
/// page registered in [AppRouter] yet — a real, documented gap (see
/// `docs/tasks/TASK-132-implementar-central-de-oportunidades-CONCLUIDA.md`)
/// — so they only surface an [AppSnackbar] instead of silently doing
/// nothing or crashing.
void _navigateForInsightAction({
  required BuildContext context,
  required String orgId,
  required String companyId,
  required InsightAction action,
}) {
  final customerId = action.customerId;
  if (action.type == InsightActionType.resumeOrder) {
    final orderId = action.payload['orderId'] as String?;
    if (orderId != null && orderId.trim().isNotEmpty) {
      context.go(
        OrderDraftRoute(
          orgId: orgId,
          companyId: companyId,
          draftId: orderId,
        ).location,
      );
      return;
    }
  }
  if (customerId != null && customerId.trim().isNotEmpty) {
    context.go(
      CustomerDetailRoute(orgId: orgId, customerId: customerId).location,
    );
    return;
  }
  AppSnackbar.show(
    context,
    message:
        'Ainda não há uma tela dedicada para esta ação — use a evidência do '
        'insight para decidir o próximo passo.',
    variant: AppSnackbarVariant.info,
  );
}

Widget _withConnectivityIndicator({
  required String orgId,
  required String companyId,
  required Widget child,
}) {
  return ConnectivityIndicatorShell(
    organizationId: orgId,
    companyId: companyId,
    createCubit: () => ConnectivityIndicatorCubit(
      getIt<ConnectivityService>(),
      getIt<OutboxRepository>(),
      getIt<AnalyticsService>(),
    ),
    child: child,
  );
}

/// Resolves whether the `feature_insights_enabled` shortcut (TASK-018)
/// should be shown in the reference module, defaulting to `false` (its own
/// code-defined default in `FeatureFlagRegistry`) whenever
/// [FeatureFlagService] itself cannot be resolved — e.g. a widget test that
/// renders [VestiProApp] without going through the real [bootstrap] (and
/// therefore without `Firebase.initializeApp`, which [FeatureFlagService]
/// transitively depends on). A feature flag must never keep the rest of
/// the app from rendering; worst case, the flagged shortcut simply stays
/// hidden, exactly like it would if Remote Config itself were unreachable.
bool _resolveShowInsightsShortcut() {
  try {
    return getIt<FeatureFlagService>().isEnabled(
      FeatureFlagRegistry.featureInsightsEnabled,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to resolve FeatureFlagService; hiding the flagged shortcut.',
      name: 'vestipro.bootstrap',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}

/// Lazily resolves [MembershipActiveOrganizationGuard]'s dependencies from
/// [getIt] only when a redirect is actually evaluated — same rationale as
/// [_LazyPermissionAuthorizationGuard]: `VestiProApp.build` must not force a
/// real DI resolution just to construct [AppRouter].
final class _LazyActiveOrganizationGuard implements ActiveOrganizationGuard {
  const _LazyActiveOrganizationGuard();

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) {
    return MembershipActiveOrganizationGuard(
      getIt<AuthRepository>(),
      getIt<GetUserMembershipUseCase>(),
      getIt<ResolveActiveOrganizationIdUseCase>(),
    ).redirect(context, state);
  }
}

final class _LazyPermissionAuthorizationGuard implements AuthorizationGuard {
  const _LazyPermissionAuthorizationGuard();

  @override
  Future<String?> redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    return PermissionAuthorizationGuard(
      getIt<PermissionService>(),
      getIt<AuthRepository>(),
    ).redirect(context, state, requiredCapability: requiredCapability);
  }
}

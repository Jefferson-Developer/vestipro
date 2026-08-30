import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth.dart';
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
import '../features/invites/invites.dart';
import '../features/onboarding/onboarding.dart';
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../features/orders/orders.dart';
import '../features/organizations/organizations.dart';
import '../features/products/products.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
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
              CatalogHomePage(
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
          customerFormPageBuilder: (context, orgId, companyId) =>
              CustomerFormPage(
                organizationId: orgId,
                companyId: companyId,
                userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                permissionService: getIt<PermissionService>(),
                createBloc: () => getIt<CustomerFormBloc>(),
              ),
          productFormPageBuilder: (context, orgId, companyId) {
            final currentUser = getIt<AuthRepository>().currentUser;
            return ProductFormPage(
              organizationId: orgId,
              companyId: companyId,
              userId: currentUser?.uid ?? '',
              actorName:
                  currentUser?.displayName ?? currentUser?.email ?? 'Usuário',
              permissionService: getIt<PermissionService>(),
              createBloc: () => getIt<ProductFormBloc>(),
              createMediaBloc: () => getIt<ProductMediaBloc>(),
            );
          },
          customerPortfolioPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  CustomerPortfolioPage(
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
          orderDraftPageBuilder: (context, orgId, companyId, queryParameters) =>
              OrderDraftPage(
                organizationId: orgId,
                companyId: companyId,
                sellerId: getIt<AuthRepository>().currentUser?.uid ?? '',
                permissionService: getIt<PermissionService>(),
                createBloc: () => getIt<OrderDraftBloc>(),
                createCustomerPortfolioBloc: () =>
                    getIt<CustomerPortfolioBloc>(),
                createOrderItemsGridCubit: () => getIt<OrderItemsGridCubit>(),
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
              ),
          orderProductCatalogPageBuilder:
              (context, orgId, companyId, draftId) => OrderProductCatalogPage(
                organizationId: orgId,
                companyId: companyId,
                draftId: draftId,
                createCatalogFilterBloc: () => getIt<CatalogFilterBloc>(),
                createItemsCounterCubit: () => getIt<OrderItemsCounterCubit>(),
              ),
          orderProductDetailPageBuilder:
              (
                context,
                orgId,
                companyId,
                draftId,
                productId,
                queryParameters,
              ) => OrderProductAdditionPage(
                organizationId: orgId,
                companyId: companyId,
                draftId: draftId,
                productId: productId,
                origin: queryParameters['origin'] ?? 'grid',
                createProductDetailBloc: () => getIt<ProductDetailBloc>(),
                createAdditionCubit: () => getIt<OrderProductAdditionCubit>(),
              ),
          catalogBrowsePageBuilder: (context, orgId, queryParameters) =>
              CatalogFilterPage(
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

import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/analytics/analytics.dart';
import '../core/auth/auth.dart';
import '../core/connectivity/connectivity.dart';
import '../core/design_system/design_system.dart';
import '../core/database/app_database.dart';
import '../core/environment/app_environment.dart';
import '../core/errors/errors.dart';
import '../core/feature_flags/feature_flags.dart';
import '../core/functions/functions.dart';
import '../core/localization/localization.dart';
import '../core/navigation/navigation.dart';
import '../core/notifications/notifications.dart';
import '../core/permissions/permissions.dart';
import '../core/services/services.dart';
import '../core/utils/utils.dart';
import '../features/authentication/authentication.dart';
import '../features/authentication/presentation/bloc/forgot_password_bloc.dart';
import '../features/authentication/presentation/bloc/login_bloc.dart';
import '../features/authentication/presentation/bloc/sign_up_bloc.dart';
import '../features/audit_log/audit_log.dart';
import '../features/admin_portal/admin_portal.dart';
import '../features/barcode_scanner/barcode_scanner.dart';
import '../features/catalog/catalog.dart';
import '../features/customer_import/customer_import.dart';
import '../features/product_import/product_import.dart';
import '../features/customers/customers.dart';
import '../features/credit/credit.dart';
import '../features/receivables/receivables.dart';
import '../features/fulfillment/fulfillment.dart';
import '../features/customer_portal/customer_portal.dart';
import '../features/demand_forecast/demand_forecast.dart';
import '../features/visit_routes/visit_routes.dart';
import '../features/catalog_share/catalog_share.dart';
import '../features/buyer_collaboration/buyer_collaboration.dart';
import '../features/cart_share/cart_share.dart';
import '../features/dashboards/dashboards.dart';
import '../features/insights/insights.dart';
import '../features/invites/invites.dart';
import '../features/onboarding/onboarding.dart';
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../features/orders/orders.dart';
import '../features/returns/returns.dart';
import '../features/exchanges/exchanges.dart';
import '../features/after_sales/after_sales.dart';
import '../features/nps/nps.dart';
import '../features/organizations/organizations.dart';
import '../features/products/products.dart';
import '../features/privacy/privacy.dart';
import '../features/product_recommendations/product_recommendations.dart';
import '../features/product_recognition/product_recognition.dart';
import '../features/replenishment/replenishment.dart';
import '../features/reports/reports.dart';
import '../core/sync/sync.dart';
import '../features/settings/presentation/bloc/about_app_bloc.dart';
import '../features/settings/settings.dart';
import '../features/targets/targets.dart';
import '../features/users/users.dart';
import '../features/approach_suggestion/approach_suggestion.dart';
import '../features/daily_rep_summary/daily_rep_summary.dart';
import '../features/report_explanation/report_explanation.dart';
import '../features/wallet_summary/wallet_summary.dart';
import '../features/whatsapp_business/whatsapp_business.dart';
import '../firebase_options.dart';
import '../l10n/generated/app_localizations.dart';
import 'firebase_bootstrap_error_app.dart';
import 'injection.dart';
import 'vestipro_bloc_observer.dart';

enum _MainMenuSection {
  catalog,
  customers,
  orders,
  opportunities,
  dashboards,
  reports,
  notifications,
  settings,
}

final class _MainMenuDestination {
  const _MainMenuDestination({
    required this.section,
    required this.destination,
    required this.location,
    this.requiredCapabilities = const <Capability>[],
  });

  final _MainMenuSection? section;
  final AppNavDestination destination;
  final String location;
  final List<Capability> requiredCapabilities;

  bool isAllowed(Set<Capability> capabilities) {
    return requiredCapabilities.isEmpty ||
        requiredCapabilities.any(capabilities.contains);
  }
}

/// Central bootstrap for every entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`). Firebase must be initialized here, and only here: no
/// feature is allowed to call `Firebase.initializeApp` on its own.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // TASK-150: registered unconditionally, right after Firebase itself
    // initializes — must happen this early (FlutterFire's own requirement),
    // never gated behind whether anything later resolves `FirebaseMessaging`
    // through `getIt`, since the platform SDK needs to know the background
    // isolate entry point before any background push could ever arrive.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
  configurePushNotificationLifecycle();
  configureQuietHoursTimezoneSync();
  // TASK-174: loads whichever language this device already saved (or
  // `AppLocale.fallback` the very first run) *before* the first frame, so
  // `VestiProApp` never has to render a loading state — or a flash of the
  // wrong language — just to know what to pass `MaterialApp.locale`.
  await getIt<LocaleCubit>().loadInitial();
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

/// Wires push notification plumbing that must start as soon as the app
/// boots, independent of any UI ever resolving these services through
/// [getIt] on its own (TASK-150):
///
/// - Eagerly resolves [PushNotificationRouter] so its `onMessage`/
///   `onMessageOpenedApp` subscriptions start immediately — otherwise,
///   being a lazy singleton like every other DI-registered service here, it
///   would only start listening the first time some future UI (TASK-151)
///   happens to resolve it, silently missing any push received before then.
/// - Registers this device's FCM token for whoever the session changes to:
///   a real login, or an already-signed-in session simply restored on a
///   fresh app launch (`SessionService.sessionChanges` emits the current
///   user immediately upon subscription). Resolves that user's active
///   Organization itself (same [ResolveActiveOrganizationIdUseCase]
///   `LoginBloc` already uses, and the same single-Organization limitation
///   it already documents), so no other call site needs to know push
///   exists at all.
/// - Unregisters/invalidates this device's token the moment the session
///   goes back to signed-out (logout, or a remotely revoked session —
///   TASK-046), so a different account signing in afterwards on this same
///   device never inherits the previous one's push registration.
///
/// Every step here is best-effort by design: a [PushTokenService]/
/// [ResolveActiveOrganizationIdUseCase] failure must never surface as a
/// login/session-restore/logout failure anywhere else in the app — both
/// services this depends on already guarantee they never throw.
@visibleForTesting
void configurePushNotificationLifecycle({
  SessionService Function()? resolveSessionService,
  PushTokenService Function()? resolvePushTokenService,
  ResolveActiveOrganizationIdUseCase Function()?
  resolveActiveOrganizationIdUseCase,
  PushNotificationRouter Function()? resolvePushNotificationRouter,
}) {
  final resolveSession = resolveSessionService ?? () => getIt<SessionService>();
  final resolveToken =
      resolvePushTokenService ?? () => getIt<PushTokenService>();
  final resolveOrg =
      resolveActiveOrganizationIdUseCase ??
      () => getIt<ResolveActiveOrganizationIdUseCase>();
  final resolveRouter =
      resolvePushNotificationRouter ?? () => getIt<PushNotificationRouter>();

  resolveRouter();

  resolveSession().sessionChanges.listen((user) {
    if (user == null) {
      unawaited(resolveToken().unregisterCurrentDevice());
      return;
    }

    unawaited(_registerPushDeviceForUser(user.uid, resolveOrg, resolveToken));
  });
}

/// Keeps this device's recipient-side quiet-hours timezone in sync
/// (TASK-155) for whoever the session changes to — mirrors
/// [configurePushNotificationLifecycle]'s own "resolve the active
/// Organization once per session change" shape, but only on sign-in: there
/// is nothing to unregister on sign-out (unlike a push token), quiet hours
/// are simply not evaluated for a signed-out user.
///
/// Best-effort by design — `SyncDeviceTimezoneUseCase` itself never throws
/// (see its own doc), so a failure here can only come from
/// [resolveActiveOrganizationIdUseCase] itself, already the same
/// [ResolveActiveOrganizationIdUseCase] every other session-lifecycle hook
/// resolves.
@visibleForTesting
void configureQuietHoursTimezoneSync({
  SessionService Function()? resolveSessionService,
  SyncDeviceTimezoneUseCase Function()? resolveSyncDeviceTimezoneUseCase,
  ResolveActiveOrganizationIdUseCase Function()?
  resolveActiveOrganizationIdUseCase,
}) {
  final resolveSession = resolveSessionService ?? () => getIt<SessionService>();
  final resolveSync =
      resolveSyncDeviceTimezoneUseCase ??
      () => getIt<SyncDeviceTimezoneUseCase>();
  final resolveOrg =
      resolveActiveOrganizationIdUseCase ??
      () => getIt<ResolveActiveOrganizationIdUseCase>();

  resolveSession().sessionChanges.listen((user) {
    if (user == null) return;
    unawaited(_syncDeviceTimezoneForUser(user.uid, resolveOrg, resolveSync));
  });
}

Future<void> _syncDeviceTimezoneForUser(
  String userId,
  ResolveActiveOrganizationIdUseCase Function() resolveOrg,
  SyncDeviceTimezoneUseCase Function() resolveSync,
) async {
  final organizationResult = await resolveOrg()(userId: userId);
  final organizationId = organizationResult.fold(
    onSuccess: (id) => id,
    onFailure: (_) => null,
  );
  if (organizationId == null) return;

  await resolveSync()(organizationId: organizationId, userId: userId);
}

Future<void> _registerPushDeviceForUser(
  String userId,
  ResolveActiveOrganizationIdUseCase Function() resolveOrg,
  PushTokenService Function() resolveToken,
) async {
  final organizationResult = await resolveOrg()(userId: userId);
  final organizationId = organizationResult.fold(
    onSuccess: (id) => id,
    onFailure: (_) => null,
  );
  if (organizationId == null) return;

  await resolveToken().registerDevice(
    organizationId: organizationId,
    userId: userId,
  );
}

PolicyAcceptanceCubit _createPolicyAcceptanceCubit({required String userId}) {
  final repository = FirestorePolicyRepository(getIt<FirebaseFirestore>());
  return PolicyAcceptanceCubit(
    evaluate: EvaluatePolicyAcceptanceUseCase(repository),
    acceptCurrent: AcceptCurrentPoliciesUseCase(repository),
    getDocuments: GetCurrentPolicyDocumentsUseCase(repository),
    userId: userId,
    device: defaultTargetPlatform.name,
  );
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
          vestiProOperatorGuard: const _LazyVestiProOperatorGuard(),
          policyAcceptanceGuard: CurrentPolicyAcceptanceGuard(
            getIt<AuthRepository>(),
            EvaluatePolicyAcceptanceUseCase(
              FirestorePolicyRepository(getIt<FirebaseFirestore>()),
            ),
          ),
          aboutAppPageBuilder: (context, orgId) => _withAuthenticatedMenu(
            context: context,
            orgId: orgId,
            selectedSection: _MainMenuSection.settings,
            child: AboutAppPage(
              createBloc: () => getIt<AboutAppBloc>(),
              showInsightsShortcut: _resolveShowInsightsShortcut(),
              onPrivacyTap: () =>
                  context.go(PrivacySettingsRoute(orgId: orgId).location),
              onLanguageTap: () =>
                  context.go(LocaleSettingsRoute(orgId: orgId).location),
            ),
          ),
          localeSettingsPageBuilder: (context, orgId) => _withAuthenticatedMenu(
            context: context,
            orgId: orgId,
            selectedSection: _MainMenuSection.settings,
            child: LocaleSettingsPage(
              organizationId: orgId,
              userId: getIt<AuthRepository>().currentUser?.uid ?? '',
            ),
          ),
          catalogHomePageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.catalog,
                child: _withConnectivityIndicator(
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
              ),
          auditLogPageBuilder: (context, orgId) => _withAuthenticatedMenu(
            context: context,
            orgId: orgId,
            selectedSection: _MainMenuSection.settings,
            child: AuditLogPage(
              organizationId: orgId,
              userId: getIt<AuthRepository>().currentUser?.uid ?? '',
              permissionService: getIt<PermissionService>(),
              createBloc: () => AuditLogBloc(
                listAuditLogEntries: getIt<ListAuditLogEntriesUseCase>(),
              ),
            ),
          ),
          vestiProAdminPortalPageBuilder: (context) {
            final repository = CloudFunctionsAdminPortalRepository(
              getIt<CloudFunctionsService>(),
            );
            return AdminPortalPage(
              createCubit: () => AdminPortalCubit(
                resolveSession: ResolveVestiProOperatorSessionUseCase(
                  repository,
                ),
                searchOrganizations: SearchAdminOrganizationsUseCase(
                  repository,
                ),
                loadDiagnosticReport: LoadAdminDiagnosticReportUseCase(
                  repository,
                ),
                reprocessOutboxItem: ReprocessAdminOutboxItemUseCase(
                  repository,
                ),
              ),
            );
          },
          userManagementPageBuilder: (context, orgId) => _withAuthenticatedMenu(
            context: context,
            orgId: orgId,
            selectedSection: _MainMenuSection.settings,
            child: UserListPage(
              organizationId: orgId,
              userId: getIt<AuthRepository>().currentUser?.uid ?? '',
              permissionService: getIt<PermissionService>(),
              createBloc: () => getIt<UserListBloc>(),
              createRoleEditBloc: () => getIt<UserRoleEditBloc>(),
            ),
          ),
          notificationCenterPageBuilder: (context, orgId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                selectedSection: _MainMenuSection.notifications,
                child: NotificationCenterPage(
                  organizationId: orgId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  createBloc: () => getIt<NotificationCenterBloc>(),
                  onOpenDeepLink: (location) => context.go(location),
                  onOpenPreferences: () => context.go(
                    CommunicationPreferencesRoute(orgId: orgId).location,
                  ),
                  onSendWhatsApp: (notification) => WhatsAppSendSheet.show(
                    context: context,
                    createCubit: () => getIt<WhatsAppSendCubit>(),
                    organizationId: orgId,
                    customerId: notification.customerId!,
                    notificationId: notification.id,
                  ),
                ),
              ),
          communicationPreferencesPageBuilder: (context, orgId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                selectedSection: _MainMenuSection.settings,
                child: CommunicationPreferencesPage(
                  organizationId: orgId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  createCubit: () => getIt<CommunicationPreferencesCubit>(),
                ),
              ),
          privacyConsentsPageBuilder: (context, orgId) {
            final repository = FirestoreConsentRepository(
              getIt<FirebaseFirestore>(),
            );
            final exportRepository = FirestorePersonalDataExportRepository(
              getIt<FirebaseFirestore>(),
              getIt<CloudFunctionsService>(),
            );
            final deletionRepository = FirebaseAccountDeletionRepository(
              getIt<CloudFunctionsService>(),
            );
            return _withAuthenticatedMenu(
              context: context,
              orgId: orgId,
              selectedSection: _MainMenuSection.settings,
              child: PrivacyAndConsentsPage(
                createCubit: () => ConsentManagementCubit(
                  repository: repository,
                  grantConsent: GrantConsent(repository),
                  revokeConsent: RevokeConsent(repository),
                  organizationId: orgId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                ),
                createExportCubit: () => PersonalDataExportCubit(
                  repository: exportRepository,
                  requestExport: RequestPersonalDataExport(exportRepository),
                  getDownload: GetPersonalDataExportDownload(exportRepository),
                  organizationId: orgId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                ),
                createDeletionCubit: () => AccountDeletionCubit(
                  requestAccountDeletion: RequestAccountDeletion(
                    deletionRepository,
                    DeviceAccountDeletionLocalCleaner(
                      database: getIt<AppDatabase>(),
                      pushTokenService: getIt<PushTokenService>(),
                      sessionService: getIt<SessionService>(),
                    ),
                  ),
                  organizationId: orgId,
                ),
                onPolicyDocumentsTap: () => context.push(
                  PolicyDocumentsSettingsRoute(orgId: orgId).location,
                ),
              ),
            );
          },
          policyDocumentsPageBuilder: (context) => PolicyDocumentsPage(
            requireAcceptance: false,
            createCubit: () => _createPolicyAcceptanceCubit(userId: ''),
          ),
          policyAcceptancePageBuilder: (context, returnTo) =>
              PolicyDocumentsPage(
                requireAcceptance: true,
                createCubit: () => _createPolicyAcceptanceCubit(
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                ),
                onAccepted: () {
                  final destination =
                      returnTo != null && returnTo.startsWith('/')
                      ? returnTo
                      : const CatalogHomeRoute(
                          orgId: kPlaceholderOrganizationId,
                        ).location;
                  context.go(destination);
                },
              ),
          targetDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
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
                  ),
          opportunityCenterPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.opportunities,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: OpportunityCenterPage(
                        organizationId: orgId,
                        companyId: companyId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<OpportunityCenterBloc>(),
                        createApproachSuggestionCubit: () =>
                            getIt<ApproachSuggestionCubit>(),
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
                  ),
          executiveDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
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
                  ),
          salesDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: SalesDashboardPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<SalesDashboardBloc>(),
                        initialFilters:
                            SalesDashboardFilters.fromQueryParameters(
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
                  ),
          customerDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
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
                  ),
          productDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
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
                  ),
          collectionDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: CollectionDashboardPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<CollectionDashboardBloc>(),
                        initialFilters:
                            CollectionDashboardFilters.fromQueryParameters(
                              queryParameters,
                              defaultCompanyId: companyId,
                            ),
                        onUrlStateChanged: (filters) => context.go(
                          CollectionDashboardRoute(
                            orgId: orgId,
                            companyId: filters.companyId,
                            queryParameters: filters.toQueryParameters(),
                          ).location,
                        ),
                        onDrillDownToCollection: (collectionId) => context.go(
                          ProductDashboardRoute(
                            orgId: orgId,
                            companyId: companyId,
                            queryParameters: <String, String>{
                              'collectionId': collectionId,
                            },
                          ).location,
                        ),
                      ),
                    ),
                  ),
          inventoryDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: InventoryDashboardPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<InventoryDashboardBloc>(),
                        initialFilters:
                            InventoryDashboardFilters.fromQueryParameters(
                              queryParameters,
                              defaultCompanyId: companyId,
                            ),
                        onUrlStateChanged: (filters) => context.go(
                          InventoryDashboardRoute(
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
                  ),
          replenishmentSuggestionsPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: ReplenishmentSuggestionsPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<ReplenishmentSuggestionsBloc>(),
                        initialWarehouseId: queryParameters['warehouseId'],
                      ),
                    ),
                  ),
          demandForecastPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: DemandForecastPage(
                        organizationId: orgId,
                        companyId: companyId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        permissionService: getIt<PermissionService>(),
                        createBloc: () => getIt<DemandForecastBloc>(),
                        initialScopeType: _parseDemandForecastScopeType(
                          queryParameters['scopeType'],
                        ),
                        initialScopeId: queryParameters['scopeId'],
                      ),
                    ),
                  ),
          representativeDashboardPageBuilder:
              (context, orgId, companyId, sellerId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: RepresentativeDashboardPage(
                        organizationId: orgId,
                        requesterUserId:
                            getIt<AuthRepository>().currentUser?.uid ?? '',
                        initialFilters:
                            RepresentativeDashboardFilters.fromQueryParameters(
                              queryParameters,
                              defaultCompanyId: companyId,
                              defaultSellerId: sellerId,
                            ),
                        createBloc: () => getIt<RepresentativeDashboardBloc>(),
                        createWalletSummaryCubit: () =>
                            getIt<WalletSummaryCubit>(),
                        createDailyRepSummaryCubit: () =>
                            getIt<DailyRepSummaryCubit>(),
                        createNpsScoreCardCubit: () =>
                            getIt<NpsScoreCardCubit>(),
                        onOpenCrmActivity: (task) {
                          final customerId = task.customerId;
                          if (customerId != null) {
                            context.go(
                              CustomerDetailRoute(
                                orgId: orgId,
                                customerId: customerId,
                              ).location,
                            );
                          } else {
                            context.go(
                              OpportunityCenterRoute(
                                orgId: orgId,
                                companyId: companyId,
                              ).location,
                            );
                          }
                        },
                        onOpenCustomer: (customerId) => context.go(
                          CustomerDetailRoute(
                            orgId: orgId,
                            customerId: customerId,
                          ).location,
                        ),
                        onOpenInsight: (insight) {
                          final customerId = insight.customerId;
                          if (customerId != null) {
                            context.go(
                              CustomerDetailRoute(
                                orgId: orgId,
                                customerId: customerId,
                              ).location,
                            );
                          } else {
                            context.go(
                              OpportunityCenterRoute(
                                orgId: orgId,
                                companyId: companyId,
                              ).location,
                            );
                          }
                        },
                      ),
                    ),
                  ),
          funnelDashboardPageBuilder:
              (
                context,
                orgId,
                companyId,
                queryParameters,
              ) => _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.dashboards,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: FunnelDashboardPage(
                    organizationId: orgId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    initialFilters: FunnelDashboardFilters.fromQueryParameters(
                      queryParameters,
                      fallbackMonthKey: DateFormat(
                        'yyyy-MM',
                      ).format(DateTime.now().toUtc()),
                      fallbackCompanyId: companyId,
                    ),
                    createBloc: () => getIt<FunnelDashboardBloc>(),
                    onOpenStageOpportunities: (stageId) => context.go(
                      OpportunityCenterRoute(
                        orgId: orgId,
                        companyId: companyId,
                        queryParameters: <String, String>{'stageId': stageId},
                      ).location,
                    ),
                    onFiltersChanged: (filters) => context.go(
                      FunnelDashboardRoute(
                        orgId: orgId,
                        companyId: companyId,
                        queryParameters: filters.toQueryParameters(),
                      ).location,
                    ),
                  ),
                ),
              ),
          targetsDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: TargetsDashboardPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        initialFilters:
                            TargetsDashboardFilters.fromQueryParameters(
                              queryParameters,
                              fallbackCompanyId: companyId,
                            ),
                        createBloc: () => getIt<TargetsDashboardBloc>(),
                        onOpenOpportunities: (sellerId) => context.go(
                          OpportunityCenterRoute(
                            orgId: orgId,
                            companyId: companyId,
                            queryParameters: <String, String>{
                              'sellerId': sellerId,
                              'types': 'sellerBelowTarget',
                            },
                          ).location,
                        ),
                      ),
                    ),
                  ),
          geographicDashboardPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.dashboards,
                    child: _withConnectivityIndicator(
                      orgId: orgId,
                      companyId: companyId,
                      child: GeographicDashboardPage(
                        organizationId: orgId,
                        userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                        initialFilters:
                            GeographicDashboardFilters.fromQueryParameters(
                              queryParameters,
                              fallbackCompanyId: companyId,
                            ),
                        createBloc: () => getIt<GeographicDashboardBloc>(),
                        onOpenCustomers: (customerIds) => context.go(
                          CustomerPortfolioRoute(
                            orgId: orgId,
                            companyId: companyId,
                            queryParameters: <String, String>{
                              'customerIds': customerIds.join(','),
                            },
                          ).location,
                        ),
                        onOpenOrders: (orderIds) => context.go(
                          OrderListRoute(
                            orgId: orgId,
                            companyId: companyId,
                            queryParameters: <String, String>{
                              'orderIds': orderIds.join(','),
                            },
                          ).location,
                        ),
                      ),
                    ),
                  ),
          reportBuilderPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.reports,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: ReportBuilderPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    createBloc: () => getIt<ReportBuilderBloc>(),
                    createSavedReportsBloc: () => getIt<SavedReportsBloc>(),
                    createReportExplanationCubit: () =>
                        getIt<ReportExplanationCubit>(),
                    permissionService: getIt<PermissionService>(),
                    onOpenSavedReports: () => context.go(
                      SavedReportsRoute(
                        orgId: orgId,
                        companyId: companyId,
                      ).location,
                    ),
                  ),
                ),
              ),
          savedReportsPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.reports,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: SavedReportsPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createBloc: () => getIt<SavedReportsBloc>(),
                    onOpenReportBuilder: () => context.go(
                      ReportBuilderRoute(
                        orgId: orgId,
                        companyId: companyId,
                      ).location,
                    ),
                  ),
                ),
              ),
          productDetailPageBuilder: (context, orgId, productId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                selectedSection: _MainMenuSection.catalog,
                child: ProductDetailPage(
                  organizationId: orgId,
                  productId: productId,
                  createBloc: () => getIt<ProductDetailBloc>(),
                  userId: getIt<AuthRepository>().currentUser?.uid,
                  createRecommendationsBloc: () =>
                      getIt<ProductRecommendationsBloc>(),
                  onRecommendationTap: (recommendedProductId) => context.go(
                    ProductDetailRoute(
                      orgId: orgId,
                      productId: recommendedProductId,
                    ).location,
                  ),
                ),
              ),
          customerFormPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.customers,
                child: _withConnectivityIndicator(
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
              ),
          customerImportPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.customers,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: CustomerImportPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createBloc: () => getIt<CustomerImportBloc>(),
                  ),
                ),
              ),
          productFormPageBuilder: (context, orgId, companyId) {
            final currentUser = getIt<AuthRepository>().currentUser;
            return _withAuthenticatedMenu(
              context: context,
              orgId: orgId,
              companyId: companyId,
              selectedSection: _MainMenuSection.catalog,
              child: _withConnectivityIndicator(
                orgId: orgId,
                companyId: companyId,
                child: ProductFormPage(
                  organizationId: orgId,
                  companyId: companyId,
                  userId: currentUser?.uid ?? '',
                  actorName:
                      currentUser?.displayName ??
                      currentUser?.email ??
                      'Usuário',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<ProductFormBloc>(),
                  createMediaBloc: () => getIt<ProductMediaBloc>(),
                ),
              ),
            );
          },
          productImportPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.catalog,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: ProductImportPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createBloc: () => getIt<ProductImportBloc>(),
                  ),
                ),
              ),
          customerPortfolioPageBuilder:
              (context, orgId, companyId, queryParameters) =>
                  _withAuthenticatedMenu(
                    context: context,
                    orgId: orgId,
                    companyId: companyId,
                    selectedSection: _MainMenuSection.customers,
                    child: _withConnectivityIndicator(
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
                        onImportRequested: () => context.go(
                          CustomerImportRoute(
                            orgId: orgId,
                            companyId: companyId,
                          ).location,
                        ),
                        onPlanVisitRouteRequested: () => context.go(
                          VisitRouteRoute(
                            orgId: orgId,
                            companyId: companyId,
                          ).location,
                        ),
                      ),
                    ),
                  ),
          visitRoutePageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.customers,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: VisitRoutePage(
                    organizationId: orgId,
                    companyId: companyId,
                    salesRepId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createBloc: () => getIt<VisitRouteBloc>(),
                    createPortfolioBloc: () => getIt<CustomerPortfolioBloc>(),
                  ),
                ),
              ),
          productRecognitionPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.catalog,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: ProductRecognitionPage(
                    organizationId: orgId,
                    companyId: companyId,
                    createCubit: () => getIt<ProductRecognitionCubit>(),
                    onProductSelected: (productId) => context.go(
                      ProductDetailRoute(
                        orgId: orgId,
                        productId: productId,
                      ).location,
                    ),
                  ),
                ),
              ),
          orderListPageBuilder: (context, orgId, companyId, queryParameters) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
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
              ),
          orderApprovalQueuePageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
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
              ),
          returnRequestAnalysisPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: ReturnRequestAnalysisPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createCubit: () => getIt<ReturnRequestQueueCubit>(),
                  ),
                ),
              ),
          exchangeRequestAnalysisPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: ExchangeRequestAnalysisPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    permissionService: getIt<PermissionService>(),
                    createCubit: () => getIt<ExchangeRequestQueueCubit>(),
                  ),
                ),
              ),
          orderHistoryPageBuilder: (context, orgId, companyId, orderId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: OrderHistoryPage(
                    organizationId: orgId,
                    companyId: companyId,
                    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                    orderId: orderId,
                    permissionService: getIt<PermissionService>(),
                    createBloc: () => getIt<OrderHistoryBloc>(),
                    createDuplicationCubit: () =>
                        getIt<OrderDuplicationCubit>(),
                    createSignatureCubit: () => getIt<OrderSignatureCubit>(),
                    createReturnRequestHistoryCubit: () =>
                        getIt<ReturnRequestHistoryCubit>(),
                    createReturnRequestFormCubit: () =>
                        getIt<ReturnRequestFormCubit>(),
                    createExchangeRequestHistoryCubit: () =>
                        getIt<ExchangeRequestHistoryCubit>(),
                    createExchangeRequestFormCubit: () =>
                        getIt<ExchangeRequestFormCubit>(),
                    createPostSaleTimelineCubit: () =>
                        getIt<PostSaleTimelineCubit>(),
                    createRegisterPostSaleEventCubit: () =>
                        getIt<RegisterPostSaleEventCubit>(),
                    createBillingPanelCubit: () =>
                        getIt<CustomerBillingCubit>(),
                    createFulfillmentPanelCubit: () =>
                        getIt<OrderFulfillmentCubit>(),
                    onDuplicated: (order) => context.go(
                      OrderDraftRoute(
                        orgId: orgId,
                        companyId: companyId,
                        draftId: order.id,
                      ).location,
                    ),
                  ),
                ),
              ),
          orderDraftPageBuilder: (context, orgId, companyId, queryParameters) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
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
                    createOrderItemsGridCubit: () =>
                        getIt<OrderItemsGridCubit>(),
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
                    onGenerateQuote: (order) => _generateQuote(context, order),
                    onShareCart: (order, productNames) =>
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CartShareSheet(
                            organizationId: order.organizationId,
                            sourceCartId: order.id,
                            sourceCartVersion: order.version,
                            items: order.items
                                .map(
                                  (item) => CartShareDraftItem(
                                    itemId: item.id,
                                    productId: item.productId,
                                    productName:
                                        productNames[item.productId] ??
                                        item.productId,
                                    variantId: item.variantId,
                                    quantity: item.quantity,
                                    unitPrice: item.unitPrice,
                                  ),
                                )
                                .toList(growable: false),
                            createCubit: () => getIt<CartShareCubit>(),
                          ),
                        ),
                    onCollaborate: (order, productNames) =>
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => BuyerCollaborationEntrySheet(
                            organizationId: order.organizationId,
                            companyId: order.companyId,
                            customerId: order.customerId,
                            priceListId: order.priceListId,
                            sourceType: BuyerCollaborationSourceType.orderDraft,
                            sourceId: order.id,
                            items: order.items
                                .map(
                                  (item) => BuyerCollaborationItem(
                                    itemId: item.id,
                                    productId: item.productId,
                                    productName:
                                        productNames[item.productId] ??
                                        item.productId,
                                    variantId: item.variantId,
                                    quantity: item.quantity,
                                    unitPrice: item.unitPrice,
                                    subtotal: item.subtotal,
                                  ),
                                )
                                .toList(growable: false),
                            createCubit: () => getIt<BuyerCollaborationCubit>(),
                            onConvertRequested: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Converter em pedido'),
                                  content: const Text(
                                    'Confirme que este pedido já foi enviado '
                                    '("Enviar pedido") com os itens combinados '
                                    'antes de converter a colaboração.',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text('Já enviei o pedido'),
                                    ),
                                  ],
                                ),
                              );
                              return confirmed == true ? order.id : null;
                            },
                          ),
                        ),
                    onSendWhatsApp: (order) => WhatsAppSendSheet.show(
                      context: context,
                      createCubit: () => getIt<WhatsAppSendCubit>(),
                      organizationId: order.organizationId,
                      customerId: order.customerId,
                    ),
                  ),
                ),
              ),
          orderProductCatalogPageBuilder:
              (context, orgId, companyId, draftId) => _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: OrderProductCatalogPage(
                    organizationId: orgId,
                    companyId: companyId,
                    draftId: draftId,
                    createCatalogFilterBloc: () => getIt<CatalogFilterBloc>(),
                    createItemsCounterCubit: () =>
                        getIt<OrderItemsCounterCubit>(),
                    createBarcodeScanCubit: () => getIt<BarcodeScanCubit>(),
                  ),
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
              ) => _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.orders,
                child: _withConnectivityIndicator(
                  orgId: orgId,
                  companyId: companyId,
                  child: OrderProductAdditionPage(
                    organizationId: orgId,
                    companyId: companyId,
                    draftId: draftId,
                    productId: productId,
                    origin: queryParameters['origin'] ?? 'grid',
                    createProductDetailBloc: () => getIt<ProductDetailBloc>(),
                    createAdditionCubit: () =>
                        getIt<OrderProductAdditionCubit>(),
                  ),
                ),
              ),
          conflictListPageBuilder: (context, orgId) => _withAuthenticatedMenu(
            context: context,
            orgId: orgId,
            selectedSection: _MainMenuSection.settings,
            child: ConflictListPage(
              organizationId: orgId,
              createCubit: () => getIt<ConflictListCubit>(),
              onConflictSelected: (conflict) => context.go(
                ConflictDetailRoute(
                  orgId: orgId,
                  conflictId: conflict.id,
                ).location,
              ),
            ),
          ),
          conflictDetailPageBuilder: (context, orgId, conflictId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                selectedSection: _MainMenuSection.settings,
                child: ConflictDetailPage(
                  conflictId: conflictId,
                  resolvedBy: getIt<AuthRepository>().currentUser?.uid ?? '',
                  createCubit: () => getIt<ConflictResolutionCubit>(),
                  onResolved: (_) =>
                      context.go(ConflictListRoute(orgId: orgId).location),
                ),
              ),
          syncCenterPageBuilder: (context, orgId, companyId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: companyId,
                selectedSection: _MainMenuSection.settings,
                child: _withConnectivityIndicator(
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
              ),
          catalogBrowsePageBuilder: (context, orgId, queryParameters) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                companyId: queryParameters['companyId'],
                selectedSection: _MainMenuSection.catalog,
                child: _withConnectivityIndicator(
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
              ),
          customerDetailPageBuilder: (context, orgId, customerId) =>
              _withAuthenticatedMenu(
                context: context,
                orgId: orgId,
                selectedSection: _MainMenuSection.customers,
                child: CustomerDetailPage(
                  organizationId: orgId,
                  customerId: customerId,
                  userId: getIt<AuthRepository>().currentUser?.uid ?? '',
                  permissionService: getIt<PermissionService>(),
                  createBloc: () => getIt<CustomerDetailBloc>(),
                  createApproachSuggestionCubit: () =>
                      getIt<ApproachSuggestionCubit>(),
                  createCreditPanelCubit: () => getIt<CustomerCreditCubit>(),
                  createBillingPanelCubit: () => getIt<CustomerBillingCubit>(),
                  createProductRecommendationsBloc: () =>
                      getIt<ProductRecommendationsBloc>(),
                ),
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
          cartSharePublicPageBuilder: (context, token) => CartSharePublicPage(
            token: token,
            createCubit: () => getIt<CartShareCubit>(),
          ),
          npsResponsePageBuilder: (context, token) => NpsResponsePage(
            token: token,
            createBloc: () => getIt<NpsResponseBloc>(),
          ),
          customerPortalPageBuilder: (context, orgId) {
            final repository = getIt<CustomerPortalRepository>();
            return CustomerPortalPage(
              organizationId: orgId,
              cubit: CustomerPortalCubit(
                LoadCustomerPortalUseCase(repository),
                RepeatCustomerPortalOrderUseCase(repository),
              ),
            );
          },
          buyerCollaborationBuyerPageBuilder: (context, orgId, sessionId) =>
              BuyerCollaborationPage(
                organizationId: orgId,
                sessionId: sessionId,
                role: BuyerCollaborationViewerRole.buyer,
                createCubit: () => getIt<BuyerCollaborationCubit>(),
              ),
          buyerCollaborationSellerPageBuilder: (context, orgId, sessionId) =>
              BuyerCollaborationPage(
                organizationId: orgId,
                sessionId: sessionId,
                role: BuyerCollaborationViewerRole.seller,
                createCubit: () => getIt<BuyerCollaborationCubit>(),
              ),
        );

    // TASK-174: `appRouter` above is built exactly once per `build()` call —
    // `BlocProvider`/`BlocBuilder` below only wrap the returned
    // `MaterialApp.router`, they never cause `VestiProApp.build` itself to
    // re-run, so `routerConfig` stays the exact same `GoRouter` instance
    // across every locale change. That is what makes a language switch
    // "imediata... sem perder estado de formulário": nothing above this
    // point (navigation stack, open forms) is ever recreated because of it.
    return BlocProvider<LocaleCubit>.value(
      value: getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, AppLocale>(
        builder: (context, locale) {
          return MaterialApp.router(
            title: environment.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            locale: locale.toFlutterLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter.router,
          );
        },
      ),
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

Future<void> _generateQuote(BuildContext context, Order order) async {
  final repository = OrderQuoteRepositoryImpl(
    CloudFunctionsOrderQuoteDataSource(getIt<CloudFunctionsService>()),
  );
  await generateQuoteFromDraft(
    context: context,
    order: order,
    generateQuoteUseCase: GenerateOrderQuoteUseCase(
      repository,
      getIt<AnalyticsService>(),
    ),
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
/// abandoned draft itself via [OrderDraftRoute]. `notifyReplenishment`
/// resolves to [ReplenishmentSuggestionsRoute] (TASK-184, EPIC-27) — closing
/// the gap `docs/tasks/TASK-132-implementar-central-de-oportunidades-CONCLUIDA.md`
/// documented for it. Every remaining action type with neither a
/// `customerId` nor one of these two special cases (pure seller-level
/// insights, e.g. `suggestCampaign`/`viewSellerDetail`) still has no
/// dedicated destination page registered in [AppRouter] — so those only
/// surface an [AppSnackbar] instead of silently doing nothing or crashing.
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
  if (action.type == InsightActionType.notifyReplenishment) {
    final productId = action.productId;
    final variantId = action.payload['variantId'] as String?;
    context.go(
      ReplenishmentSuggestionsRoute(
        orgId: orgId,
        companyId: companyId,
        queryParameters: <String, String>{
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (variantId != null && variantId.trim().isNotEmpty)
            'variantId': variantId,
        },
      ).location,
    );
    return;
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

/// Parses [DemandForecastRoute]'s optional `scopeType` query parameter,
/// falling back to [DemandForecastScopeType.product] for a missing or
/// unrecognized value — same "router hands raw params, page owns parsing,
/// never crashes on a malformed deep link" contract every other query
/// parameter parser in this file follows.
DemandForecastScopeType _parseDemandForecastScopeType(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return DemandForecastScopeType.product;
  }
  try {
    return parseDemandForecastScopeType(raw.trim());
  } on ArgumentError {
    return DemandForecastScopeType.product;
  }
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

Widget _withAuthenticatedMenu({
  required BuildContext context,
  required String orgId,
  required _MainMenuSection selectedSection,
  required Widget child,
  String? companyId,
}) {
  return _AuthenticatedMenuShell(
    organizationId: orgId,
    companyId: companyId ?? kPlaceholderCompanyId,
    userId: getIt<AuthRepository>().currentUser?.uid ?? '',
    permissionService: getIt<PermissionService>(),
    selectedSection: selectedSection,
    child: child,
  );
}

final class _AuthenticatedMenuShell extends StatefulWidget {
  const _AuthenticatedMenuShell({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.selectedSection,
    required this.child,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final _MainMenuSection selectedSection;
  final Widget child;

  @override
  State<_AuthenticatedMenuShell> createState() =>
      _AuthenticatedMenuShellState();
}

final class _AuthenticatedMenuShellState
    extends State<_AuthenticatedMenuShell> {
  late Future<AppResult<Set<Capability>>> _capabilitiesFuture;

  @override
  void initState() {
    super.initState();
    _capabilitiesFuture = _resolveCapabilities();
  }

  @override
  void didUpdateWidget(_AuthenticatedMenuShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId ||
        oldWidget.userId != widget.userId ||
        oldWidget.permissionService != widget.permissionService) {
      _capabilitiesFuture = _resolveCapabilities();
    }
  }

  Future<AppResult<Set<Capability>>> _resolveCapabilities() {
    if (widget.userId.trim().isEmpty) {
      return Future<AppResult<Set<Capability>>>.value(
        const AppSuccess<Set<Capability>>(<Capability>{}),
      );
    }
    return widget.permissionService.resolveCapabilities(
      organizationId: widget.organizationId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppResult<Set<Capability>>>(
      future: _capabilitiesFuture,
      builder: (context, snapshot) {
        final capabilities =
            snapshot.data?.fold(
              onSuccess: (value) => value,
              onFailure: (_) => const <Capability>{},
            ) ??
            const <Capability>{};
        return _buildShell(context, capabilities);
      },
    );
  }

  Widget _buildShell(BuildContext context, Set<Capability> capabilities) {
    final primaryItems = _primaryDestinations(capabilities);
    final selectedIndex = primaryItems.indexWhere(
      (item) => item.section == widget.selectedSection,
    );
    final effectiveSelectedIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final secondaryItems = _secondaryDestinations(capabilities);

    return AppAdaptiveShell(
      destinations: [for (final item in primaryItems) item.destination],
      selectedIndex: effectiveSelectedIndex,
      onDestinationSelected: (index) =>
          context.go(primaryItems[index].location),
      secondaryDestinations: [
        for (final item in secondaryItems) item.destination,
      ],
      onSecondaryDestinationSelected: (index) =>
          context.go(secondaryItems[index].location),
      body: widget.child,
    );
  }

  List<_MainMenuDestination> _primaryDestinations(
    Set<Capability> capabilities,
  ) {
    final dashboardLocation =
        capabilities.contains(Capability.reportViewSensitive)
        ? ExecutiveDashboardRoute(
            orgId: widget.organizationId,
            companyId: widget.companyId,
          ).location
        : TargetDashboardRoute(
            orgId: widget.organizationId,
            companyId: widget.companyId,
          ).location;

    final items = <_MainMenuDestination>[
      _MainMenuDestination(
        section: _MainMenuSection.catalog,
        destination: const AppNavDestination(
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
          label: 'Catalogo',
        ),
        location: CatalogHomeRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
      ),
      _MainMenuDestination(
        section: _MainMenuSection.customers,
        destination: const AppNavDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Clientes',
        ),
        location: CustomerPortfolioRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
        requiredCapabilities: const <Capability>[Capability.customerView],
      ),
      _MainMenuDestination(
        section: _MainMenuSection.orders,
        destination: const AppNavDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Pedidos',
        ),
        location: OrderListRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
        requiredCapabilities: const <Capability>[
          Capability.orderView,
          Capability.orderCreate,
        ],
      ),
      _MainMenuDestination(
        section: _MainMenuSection.opportunities,
        destination: const AppNavDestination(
          icon: Icons.lightbulb_outline,
          selectedIcon: Icons.lightbulb,
          label: 'Oportunidades',
        ),
        location: OpportunityCenterRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
        requiredCapabilities: const <Capability>[Capability.insightView],
      ),
      _MainMenuDestination(
        section: _MainMenuSection.dashboards,
        destination: const AppNavDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Dashboards',
        ),
        location: dashboardLocation,
        requiredCapabilities: const <Capability>[
          Capability.reportViewSensitive,
          Capability.targetView,
        ],
      ),
      _MainMenuDestination(
        section: _MainMenuSection.reports,
        destination: const AppNavDestination(
          icon: Icons.query_stats_outlined,
          selectedIcon: Icons.query_stats,
          label: 'Relatorios',
        ),
        location: ReportBuilderRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
        requiredCapabilities: const <Capability>[
          Capability.reportExport,
          Capability.reportViewSensitive,
        ],
      ),
      _MainMenuDestination(
        section: _MainMenuSection.notifications,
        destination: const AppNavDestination(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: 'Notificacoes',
        ),
        location: NotificationCenterRoute(
          orgId: widget.organizationId,
        ).location,
      ),
      _MainMenuDestination(
        section: _MainMenuSection.settings,
        destination: const AppNavDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Ajustes',
        ),
        location: AboutAppRoute(orgId: widget.organizationId).location,
      ),
    ];

    return items.where((item) => item.isAllowed(capabilities)).toList();
  }

  List<_MainMenuDestination> _secondaryDestinations(
    Set<Capability> capabilities,
  ) {
    final items = <_MainMenuDestination>[
      _MainMenuDestination(
        section: null,
        destination: const AppNavDestination(
          icon: Icons.sync_outlined,
          selectedIcon: Icons.sync,
          label: 'Sincronizacao',
        ),
        location: SyncCenterRoute(
          orgId: widget.organizationId,
          companyId: widget.companyId,
        ).location,
      ),
      _MainMenuDestination(
        section: null,
        destination: const AppNavDestination(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: 'Usuarios',
        ),
        location: UserManagementRoute(orgId: widget.organizationId).location,
        requiredCapabilities: const <Capability>[Capability.userChangeRole],
      ),
      _MainMenuDestination(
        section: null,
        destination: const AppNavDestination(
          icon: Icons.policy_outlined,
          selectedIcon: Icons.policy,
          label: 'Auditoria',
        ),
        location: AuditLogRoute(orgId: widget.organizationId).location,
        requiredCapabilities: const <Capability>[Capability.auditLogView],
      ),
      _MainMenuDestination(
        section: null,
        destination: const AppNavDestination(
          icon: Icons.privacy_tip_outlined,
          selectedIcon: Icons.privacy_tip,
          label: 'Privacidade',
        ),
        location: PrivacySettingsRoute(orgId: widget.organizationId).location,
      ),
      _MainMenuDestination(
        section: null,
        destination: const AppNavDestination(
          icon: Icons.language_outlined,
          selectedIcon: Icons.language,
          label: 'Idioma',
        ),
        location: LocaleSettingsRoute(orgId: widget.organizationId).location,
      ),
    ];

    return items.where((item) => item.isAllowed(capabilities)).toList();
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

final class _LazyVestiProOperatorGuard implements VestiProOperatorGuard {
  const _LazyVestiProOperatorGuard();

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) {
    return RepositoryVestiProOperatorGuard(
      CloudFunctionsAdminPortalRepository(getIt<CloudFunctionsService>()),
    ).redirect(context, state);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';

void main() {
  group('AppRouter', () {
    testWidgets('shows the not found page for an unknown path', (tester) async {
      final appRouter = _buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go('/this-path-does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('Página não encontrada'), findsOneWidget);
    });

    testWidgets('shows the forbidden page when a guard denies access', (
      tester,
    ) async {
      final appRouter = _buildRouter(authGuard: const _DenyOrgRoutesGuard());

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('Sem permissão'), findsOneWidget);
    });

    testWidgets('resolves the orgId path parameter for the example module', (
      tester,
    ) async {
      String? capturedOrgId;
      final appRouter = _buildRouter(
        aboutAppPageBuilder: (context, orgId) {
          capturedOrgId = orgId;
          return Scaffold(body: Text('about-app:$orgId'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme-fashion').location);
      await tester.pumpAndSettle();

      expect(capturedOrgId, 'acme-fashion');
      expect(find.text('about-app:acme-fashion'), findsOneWidget);
    });

    testWidgets('resolves CatalogHomeRoute parameters for the catalog home', (
      tester,
    ) async {
      String? capturedOrgId;
      String? capturedCompanyId;
      final appRouter = _buildRouter(
        catalogHomePageBuilder: (context, orgId, companyId) {
          capturedOrgId = orgId;
          capturedCompanyId = companyId;
          return Scaffold(
            body: Text('catalog-home:$orgId:${companyId ?? 'all'}'),
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CatalogHomeRoute(
          orgId: 'acme-fashion',
          companyId: 'company-1',
        ).location,
      );
      await tester.pumpAndSettle();

      expect(capturedOrgId, 'acme-fashion');
      expect(capturedCompanyId, 'company-1');
      expect(find.text('catalog-home:acme-fashion:company-1'), findsOneWidget);
    });

    testWidgets('allows navigation by default (stub guards)', (tester) async {
      final appRouter = _buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('about-app:acme'), findsOneWidget);
      expect(find.text('Sem permissão'), findsNothing);
    });

    testWidgets('policy guard blocks app routes and preserves returnTo', (
      tester,
    ) async {
      String? capturedReturnTo;
      final appRouter = _buildRouter(
        policyAcceptanceGuard: const _RequirePolicyAcceptanceGuard(),
        policyAcceptancePageBuilder: (context, returnTo) {
          capturedReturnTo = returnTo;
          return const Scaffold(body: Text('policy-acceptance'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      const destination = AboutAppRoute(orgId: 'acme');
      appRouter.router.go(destination.location);
      await tester.pumpAndSettle();

      expect(find.text('policy-acceptance'), findsOneWidget);
      expect(find.text('about-app:acme'), findsNothing);
      expect(capturedReturnTo, destination.location);
    });

    testWidgets('renders the injected login page at LoginRoute (TASK-034)', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        loginPageBuilder: (context) => const Scaffold(body: Text('login-page')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const LoginRoute().location);
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });

    testWidgets('extracts the token path parameter for InviteAcceptanceRoute '
        '(TASK-040)', (tester) async {
      String? capturedToken;
      final appRouter = _buildRouter(
        acceptInvitePageBuilder: (context, token) {
          capturedToken = token;
          return Scaffold(body: Text('accept-invite:$token'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const InviteAcceptanceRoute(token: 'abc-123').location,
      );
      await tester.pumpAndSettle();

      expect(capturedToken, 'abc-123');
      expect(find.text('accept-invite:abc-123'), findsOneWidget);
    });

    testWidgets('extracts the token path parameter for CatalogSharePublicRoute '
        '(TASK-081)', (tester) async {
      String? capturedToken;
      final appRouter = _buildRouter(
        catalogSharePublicPageBuilder: (context, token) {
          capturedToken = token;
          return Scaffold(body: Text('catalog-share-public:$token'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CatalogSharePublicRoute(token: 'share-token-1').location,
      );
      await tester.pumpAndSettle();

      expect(capturedToken, 'share-token-1');
      expect(find.text('catalog-share-public:share-token-1'), findsOneWidget);
    });

    testWidgets('protects AuditLogRoute with audit.log.view', (tester) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyAuditLogGuard(),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AuditLogRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('Sem permissão'), findsOneWidget);
      expect(find.text('audit-log:acme'), findsNothing);
    });

    testWidgets('protects VestiProAdminPortalRoute with internal guard', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        vestiProOperatorGuard: const _DenyVestiProOperatorGuard(),
        vestiProAdminPortalPageBuilder: (context) =>
            const Scaffold(body: Text('vestipro-admin')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const VestiProAdminPortalRoute().location);
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(find.text('vestipro-admin'), findsNothing);
    });

    testWidgets('resolves VestiProAdminPortalRoute outside org scope', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        organizationGuard: const _DenyEveryOrganizationGuard(),
        vestiProAdminPortalPageBuilder: (context) =>
            const Scaffold(body: Text('vestipro-admin')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const VestiProAdminPortalRoute().location);
      await tester.pumpAndSettle();

      expect(find.text('vestipro-admin'), findsOneWidget);
    });

    testWidgets('resolves UserManagementRoute for role management', (
      tester,
    ) async {
      String? capturedOrgId;
      final appRouter = _buildRouter(
        userManagementPageBuilder: (context, orgId) {
          capturedOrgId = orgId;
          return Scaffold(body: Text('user-management:$orgId'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const UserManagementRoute(orgId: 'acme-fashion').location,
      );
      await tester.pumpAndSettle();

      expect(capturedOrgId, 'acme-fashion');
      expect(find.text('user-management:acme-fashion'), findsOneWidget);
    });

    testWidgets('protects UserManagementRoute with user.changeRole', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyUserChangeRoleGuard(),
        userManagementPageBuilder: (context, orgId) =>
            Scaffold(body: Text('user-management:$orgId')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const UserManagementRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(find.text('user-management:acme'), findsNothing);
    });

    testWidgets('protects CustomerFormRoute with customer.create', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyCustomerCreateGuard(),
        customerFormPageBuilder: (context, orgId, companyId) =>
            Scaffold(body: Text('customer-form:$orgId:$companyId')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CustomerFormRoute(orgId: 'acme', companyId: 'company-1').location,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem permissão'), findsOneWidget);
      expect(find.text('customer-form:acme:company-1'), findsNothing);
    });

    testWidgets(
      'passes ProductFormRoute path parameters to the injected page',
      (tester) async {
        String? capturedOrgId;
        String? capturedCompanyId;
        final appRouter = _buildRouter(
          productFormPageBuilder: (context, orgId, companyId) {
            capturedOrgId = orgId;
            capturedCompanyId = companyId;
            return Scaffold(body: Text('product-form:$orgId:$companyId'));
          },
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(
          const ProductFormRoute(
            orgId: 'acme',
            companyId: 'company-1',
          ).location,
        );
        await tester.pumpAndSettle();

        expect(capturedOrgId, 'acme');
        expect(capturedCompanyId, 'company-1');
        expect(find.text('product-form:acme:company-1'), findsOneWidget);
      },
    );

    testWidgets('protects ProductFormRoute with catalog.manage', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyCatalogManageGuard(),
        productFormPageBuilder: (context, orgId, companyId) =>
            Scaffold(body: Text('product-form:$orgId:$companyId')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const ProductFormRoute(orgId: 'acme', companyId: 'company-1').location,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(find.text('product-form:acme:company-1'), findsNothing);
    });

    testWidgets(
      'passes ProductRecognitionRoute path parameters to the injected page '
      'with no Capability gate (TASK-191)',
      (tester) async {
        String? capturedOrgId;
        String? capturedCompanyId;
        final appRouter = _buildRouter(
          // Never protected by any Capability — an active member always
          // needs to reach this route (`AppRouter.productRecognitionPageBuilder`'s
          // own doc comment); a hostile "deny everything" guard here proves
          // the route itself carries no `redirect:`, unlike
          // `ProductFormRoute`/`CustomerDetailRoute` above.
          authorizationGuard: const _DenyEverythingAuthorizationGuard(),
          productRecognitionPageBuilder: (context, orgId, companyId) {
            capturedOrgId = orgId;
            capturedCompanyId = companyId;
            return Scaffold(
              body: Text('product-recognition:$orgId:$companyId'),
            );
          },
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(
          const ProductRecognitionRoute(
            orgId: 'acme',
            companyId: 'company-1',
          ).location,
        );
        await tester.pumpAndSettle();

        expect(capturedOrgId, 'acme');
        expect(capturedCompanyId, 'company-1');
        expect(find.text('product-recognition:acme:company-1'), findsOneWidget);
      },
    );

    testWidgets('passes CustomerPortfolioRoute query parameters to the '
        'injected page', (tester) async {
      Map<String, String>? capturedQuery;
      final appRouter = _buildRouter(
        customerPortfolioPageBuilder:
            (context, orgId, companyId, queryParameters) {
              capturedQuery = queryParameters;
              return Scaffold(
                body: Text(
                  'customer-portfolio:$orgId:$companyId:${queryParameters['q']}',
                ),
              );
            },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CustomerPortfolioRoute(
          orgId: 'acme',
          companyId: 'company-1',
          queryParameters: <String, String>{'q': 'alfa', 'uf': 'SP'},
        ).location,
      );
      await tester.pumpAndSettle();

      expect(capturedQuery, <String, String>{'q': 'alfa', 'uf': 'SP'});
      expect(
        find.text('customer-portfolio:acme:company-1:alfa'),
        findsOneWidget,
      );
    });

    testWidgets(
      'passes CatalogBrowseRoute query parameters to the injected page '
      '(TASK-082)',
      (tester) async {
        Map<String, String>? capturedQuery;
        final appRouter = _buildRouter(
          catalogBrowsePageBuilder: (context, orgId, queryParameters) {
            capturedQuery = queryParameters;
            return Scaffold(
              body: Text('catalog-browse:$orgId:${queryParameters['mode']}'),
            );
          },
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(
          const CatalogBrowseRoute(
            orgId: 'acme',
            queryParameters: <String, String>{
              'mode': 'list',
              'collectionId': 'col-1',
            },
          ).location,
        );
        await tester.pumpAndSettle();

        expect(capturedQuery, <String, String>{
          'mode': 'list',
          'collectionId': 'col-1',
        });
        expect(find.text('catalog-browse:acme:list'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to the not found page when no catalogBrowsePageBuilder '
      'is wired',
      (tester) async {
        final appRouter = _buildRouter();

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(const CatalogBrowseRoute(orgId: 'acme').location);
        await tester.pumpAndSettle();

        expect(find.text('Página não encontrada'), findsOneWidget);
      },
    );

    testWidgets('protects CustomerPortfolioRoute with customer.view', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyCustomerViewGuard(),
        customerPortfolioPageBuilder:
            (context, orgId, companyId, queryParameters) =>
                Scaffold(body: Text('customer-portfolio:$orgId:$companyId')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CustomerPortfolioRoute(
          orgId: 'acme',
          companyId: 'company-1',
        ).location,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(find.text('customer-portfolio:acme:company-1'), findsNothing);
    });

    testWidgets('passes CustomerDetailRoute path parameters to the injected '
        'page', (tester) async {
      String? capturedOrgId;
      String? capturedCustomerId;
      final appRouter = _buildRouter(
        customerDetailPageBuilder: (context, orgId, customerId) {
          capturedOrgId = orgId;
          capturedCustomerId = customerId;
          return Scaffold(body: Text('customer-detail:$orgId:$customerId'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CustomerDetailRoute(
          orgId: 'acme',
          customerId: 'customer-123',
        ).location,
      );
      await tester.pumpAndSettle();

      expect(capturedOrgId, 'acme');
      expect(capturedCustomerId, 'customer-123');
      expect(find.text('customer-detail:acme:customer-123'), findsOneWidget);
    });

    testWidgets('protects CustomerDetailRoute with customer.view', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        authorizationGuard: const _DenyCustomerViewGuard(),
        customerDetailPageBuilder: (context, orgId, customerId) =>
            Scaffold(body: Text('customer-detail:$orgId:$customerId')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(
        const CustomerDetailRoute(
          orgId: 'acme',
          customerId: 'customer-123',
        ).location,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(find.text('customer-detail:acme:customer-123'), findsNothing);
    });
  });
}

AppRouter _buildRouter({
  AuthGuard? authGuard,
  ActiveOrganizationGuard? organizationGuard,
  AuthorizationGuard? authorizationGuard,
  VestiProOperatorGuard? vestiProOperatorGuard,
  PolicyAcceptanceGuard? policyAcceptanceGuard,
  Widget Function(BuildContext context, String orgId)? aboutAppPageBuilder,
  Widget Function(BuildContext context, String orgId, String? companyId)?
  catalogHomePageBuilder,
  Widget Function(BuildContext context, String orgId)? auditLogPageBuilder,
  WidgetBuilder? vestiProAdminPortalPageBuilder,
  Widget Function(BuildContext context, String orgId)?
  userManagementPageBuilder,
  Widget Function(BuildContext context, String orgId, String companyId)?
  customerFormPageBuilder,
  Widget Function(BuildContext context, String orgId, String companyId)?
  productFormPageBuilder,
  Widget Function(BuildContext context, String orgId, String companyId)?
  productRecognitionPageBuilder,
  Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  customerPortfolioPageBuilder,
  Widget Function(BuildContext context, String orgId, String customerId)?
  customerDetailPageBuilder,
  Widget Function(
    BuildContext context,
    String orgId,
    Map<String, String> queryParameters,
  )?
  catalogBrowsePageBuilder,
  WidgetBuilder? loginPageBuilder,
  Widget Function(BuildContext context, String? returnTo)?
  policyAcceptancePageBuilder,
  Widget Function(BuildContext context, String token)? acceptInvitePageBuilder,
  Widget Function(BuildContext context, String token)?
  catalogSharePublicPageBuilder,
}) {
  return AppRouter(
    authGuard: authGuard,
    organizationGuard: organizationGuard,
    authorizationGuard: authorizationGuard,
    vestiProOperatorGuard: vestiProOperatorGuard,
    policyAcceptanceGuard: policyAcceptanceGuard,
    policyAcceptancePageBuilder: policyAcceptancePageBuilder,
    aboutAppPageBuilder:
        aboutAppPageBuilder ??
        (context, orgId) => Scaffold(body: Text('about-app:$orgId')),
    catalogHomePageBuilder:
        catalogHomePageBuilder ??
        (context, orgId, companyId) =>
            Scaffold(body: Text('catalog-home:$orgId:${companyId ?? 'all'}')),
    auditLogPageBuilder:
        auditLogPageBuilder ??
        (context, orgId) => Scaffold(body: Text('audit-log:$orgId')),
    vestiProAdminPortalPageBuilder: vestiProAdminPortalPageBuilder,
    userManagementPageBuilder:
        userManagementPageBuilder ??
        (context, orgId) => Scaffold(body: Text('user-management:$orgId')),
    customerFormPageBuilder: customerFormPageBuilder,
    productFormPageBuilder: productFormPageBuilder,
    productRecognitionPageBuilder: productRecognitionPageBuilder,
    customerPortfolioPageBuilder: customerPortfolioPageBuilder,
    customerDetailPageBuilder: customerDetailPageBuilder,
    catalogBrowsePageBuilder: catalogBrowsePageBuilder,
    loginPageBuilder:
        loginPageBuilder ?? (context) => const Scaffold(body: Text('login')),
    signUpPageBuilder: (context) => const Scaffold(body: Text('sign-up')),
    forgotPasswordPageBuilder: (context) =>
        const Scaffold(body: Text('forgot-password')),
    onboardingWizardPageBuilder: (context) =>
        const Scaffold(body: Text('onboarding-wizard')),
    acceptInvitePageBuilder:
        acceptInvitePageBuilder ??
        (context, token) => Scaffold(body: Text('accept-invite:$token')),
    catalogSharePublicPageBuilder:
        catalogSharePublicPageBuilder ??
        (context, token) => Scaffold(body: Text('catalog-share-public:$token')),
  );
}

final class _RequirePolicyAcceptanceGuard implements PolicyAcceptanceGuard {
  const _RequirePolicyAcceptanceGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (state.uri.path == PolicyAcceptanceRoute.pathPattern) return null;
    if (state.uri.path.startsWith('/org/')) {
      return PolicyAcceptanceRoute(returnTo: state.uri.toString()).location;
    }
    return null;
  }
}

final class _DenyOrgRoutesGuard implements AuthGuard {
  const _DenyOrgRoutesGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (state.uri.path.startsWith('/org/')) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

final class _DenyAuditLogGuard implements AuthorizationGuard {
  const _DenyAuditLogGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    if (requiredCapability == Capability.auditLogView) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

final class _DenyVestiProOperatorGuard implements VestiProOperatorGuard {
  const _DenyVestiProOperatorGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    return const ForbiddenRoute().location;
  }
}

final class _DenyEveryOrganizationGuard implements ActiveOrganizationGuard {
  const _DenyEveryOrganizationGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (state.pathParameters.containsKey('orgId')) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

final class _DenyUserChangeRoleGuard implements AuthorizationGuard {
  const _DenyUserChangeRoleGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    if (requiredCapability == Capability.userChangeRole) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

final class _DenyCustomerCreateGuard implements AuthorizationGuard {
  const _DenyCustomerCreateGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    if (requiredCapability == Capability.customerCreate) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

/// Denies every possible [Capability] — used to prove a route (e.g.
/// [ProductRecognitionRoute]) is reachable regardless of what any
/// [AuthorizationGuard] would decide, because that `GoRoute` carries no
/// `redirect:` clause at all (unlike [ProductFormRoute]/[CustomerDetailRoute],
/// whose own tests use a narrower single-capability deny guard instead).
final class _DenyEverythingAuthorizationGuard implements AuthorizationGuard {
  const _DenyEverythingAuthorizationGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    return const ForbiddenRoute().location;
  }
}

final class _DenyCatalogManageGuard implements AuthorizationGuard {
  const _DenyCatalogManageGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    if (requiredCapability == Capability.catalogManage) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

final class _DenyCustomerViewGuard implements AuthorizationGuard {
  const _DenyCustomerViewGuard();

  @override
  String? redirect(
    BuildContext context,
    GoRouterState state, {
    required Capability requiredCapability,
  }) {
    if (requiredCapability == Capability.customerView) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}

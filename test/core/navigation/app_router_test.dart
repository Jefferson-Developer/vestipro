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
  Widget Function(BuildContext context, String orgId)? aboutAppPageBuilder,
  Widget Function(BuildContext context, String orgId, String? companyId)?
  catalogHomePageBuilder,
  Widget Function(BuildContext context, String orgId)? auditLogPageBuilder,
  Widget Function(BuildContext context, String orgId)?
  userManagementPageBuilder,
  Widget Function(BuildContext context, String orgId, String companyId)?
  customerFormPageBuilder,
  Widget Function(BuildContext context, String orgId, String companyId)?
  productFormPageBuilder,
  Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  customerPortfolioPageBuilder,
  Widget Function(BuildContext context, String orgId, String customerId)?
  customerDetailPageBuilder,
  WidgetBuilder? loginPageBuilder,
  Widget Function(BuildContext context, String token)? acceptInvitePageBuilder,
}) {
  return AppRouter(
    authGuard: authGuard,
    organizationGuard: organizationGuard,
    authorizationGuard: authorizationGuard,
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
    userManagementPageBuilder:
        userManagementPageBuilder ??
        (context, orgId) => Scaffold(body: Text('user-management:$orgId')),
    customerFormPageBuilder: customerFormPageBuilder,
    productFormPageBuilder: productFormPageBuilder,
    customerPortfolioPageBuilder: customerPortfolioPageBuilder,
    customerDetailPageBuilder: customerDetailPageBuilder,
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
  );
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

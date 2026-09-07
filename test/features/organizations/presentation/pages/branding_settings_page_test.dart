import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockMembershipRepository membershipRepository;
  late _MockAnalyticsService analyticsService;
  late PermissionService permissionService;

  const baseSettings = OrganizationSettings(
    currency: 'BRL',
    country: 'BR',
    defaultLanguage: 'pt-BR',
  );

  Organization buildOrganization(OrganizationSettings settings) {
    return Organization(
      id: 'org-1',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto',
      settings: settings,
      status: OrganizationStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );
  }

  Membership buildMembership(String roleName) {
    return Membership(
      id: 'user-2',
      organizationId: 'org-1',
      userId: 'user-2',
      roleId: roleName,
      roleName: roleName,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-2',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-2',
    );
  }

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    membershipRepository = _MockMembershipRepository();
    analyticsService = _MockAnalyticsService();
    permissionService = PermissionService(membershipRepository);
    registerFallbackValue(baseSettings);
    when(
      () => analyticsService.logEvent(
        any(),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> enterFieldText(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find
        .byWidgetPredicate(
          (widget) => widget is AppTextField && widget.label == label,
        )
        .last;
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    await tester.ensureVisible(field);
    await tester.enterText(editable.first, value);
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BrandingSettingsPage(
          organizationId: 'org-1',
          userId: 'user-2',
          permissionService: permissionService,
          createCubit: () => BrandingSettingsCubit(
            GetOrganizationUseCase(organizationRepository),
            UpdateOrganizationSettingsUseCase(organizationRepository),
            analyticsService,
          ),
        ),
      ),
    );
  }

  testWidgets('shows a forbidden page when the user lacks the capability', (
    tester,
  ) async {
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'user-2',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(BrandingSettingsPage), findsOneWidget);
    expect(find.text('Marca do catálogo (white-label)'), findsNothing);
  });

  group('granted (OWNER)', () {
    setUp(() {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-2',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('OWNER')),
      );
    });

    testWidgets('loads and renders the current branding config', (
      tester,
    ) async {
      when(() => organizationRepository.getById('org-1')).thenAnswer(
        (_) async => AppSuccess<Organization>(
          buildOrganization(
            baseSettings.copyWith(brandingPrimaryColorHex: '#1F5364'),
          ),
        ),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Marca do catálogo (white-label)'), findsOneWidget);
      // The live preview reuses the exact same catalog grid component,
      // already themed with the color loaded from the organization.
      expect(find.byType(AppProductGrid), findsOneWidget);
      final previewTheme = Theme.of(
        tester.element(find.byType(AppProductGrid)),
      );
      expect(previewTheme.colorScheme.primary, const Color(0xFF1F5364));
    });

    testWidgets(
      'updates the live preview theme as the organization types a color',
      (tester) async {
        when(() => organizationRepository.getById('org-1')).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(buildOrganization(baseSettings)),
        );

        await pumpPage(tester);
        await tester.pumpAndSettle();

        await enterFieldText(tester, 'Cor principal (opcional)', '#0A1F33');

        final previewTheme = Theme.of(
          tester.element(find.byType(AppProductGrid)),
        );
        expect(previewTheme.colorScheme.primary, const Color(0xFF0A1F33));
      },
    );

    testWidgets(
      'shows the accessibility fallback notice for a low-contrast color',
      (tester) async {
        when(() => organizationRepository.getById('org-1')).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(buildOrganization(baseSettings)),
        );

        await pumpPage(tester);
        await tester.pumpAndSettle();

        await enterFieldText(tester, 'Cor principal (opcional)', '#FFEB3B');

        expect(
          find.textContaining('não atinge o contraste mínimo'),
          findsOneWidget,
        );
      },
    );

    testWidgets('saves the branding config and shows a success snackbar', (
      tester,
    ) async {
      when(() => organizationRepository.getById('org-1')).thenAnswer(
        (_) async => AppSuccess<Organization>(buildOrganization(baseSettings)),
      );
      when(
        () => organizationRepository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Organization>(
          buildOrganization(
            baseSettings.copyWith(brandingPrimaryColorHex: '#0A1F33'),
          ),
        ),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await enterFieldText(tester, 'Cor principal (opcional)', '#0A1F33');

      final saveButton = find.widgetWithText(AppButton, 'Salvar marca');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Marca do catálogo salva com sucesso.'), findsOneWidget);
      verify(
        () => organizationRepository.updateSettings(
          id: 'org-1',
          settings: baseSettings.copyWith(brandingPrimaryColorHex: '#0A1F33'),
          updatedBy: 'user-2',
        ),
      ).called(1);
    });
  });
}

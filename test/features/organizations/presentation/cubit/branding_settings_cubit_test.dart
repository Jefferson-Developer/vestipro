import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('BrandingSettingsCubit', () {
    late _MockOrganizationRepository repository;
    late _MockAnalyticsService analyticsService;
    late BrandingSettingsCubit cubit;

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

    setUp(() {
      repository = _MockOrganizationRepository();
      analyticsService = _MockAnalyticsService();
      cubit = BrandingSettingsCubit(
        GetOrganizationUseCase(repository),
        UpdateOrganizationSettingsUseCase(repository),
        analyticsService,
      );
      registerFallbackValue(baseSettings);
      when(
        () => analyticsService.logEvent(
          any(),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'load populates draft fields from the organization settings',
      () async {
        when(() => repository.getById('org-1')).thenAnswer(
          (_) async => AppSuccess<Organization>(
            buildOrganization(
              baseSettings.copyWith(
                brandingLogoUrl: 'https://cdn.example.com/logo.png',
                brandingPrimaryColorHex: '#1F5364',
              ),
            ),
          ),
        );

        await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

        expect(cubit.state.loadStatus, BrandingSettingsLoadStatus.ready);
        expect(cubit.state.logoUrlInput, 'https://cdn.example.com/logo.png');
        expect(cubit.state.primaryColorHexInput, '#1F5364');
        expect(cubit.state.usesContrastFallback, isFalse);
      },
    );

    test(
      'load leaves draft fields empty when nothing is configured yet',
      () async {
        when(() => repository.getById('org-1')).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(buildOrganization(baseSettings)),
        );

        await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

        expect(cubit.state.logoUrlInput, isEmpty);
        expect(cubit.state.primaryColorHexInput, isEmpty);
      },
    );

    test('load emits failure when the organization cannot be read', () async {
      when(() => repository.getById('org-1')).thenAnswer(
        (_) async =>
            AppFailure<Organization>(const ConnectivityFailure('Offline.')),
      );

      await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

      expect(cubit.state.loadStatus, BrandingSettingsLoadStatus.failure);
      expect(cubit.state.failureMessage, 'Offline.');
    });

    test(
      'updateDraft flags usesContrastFallback live for a bright custom color',
      () async {
        when(() => repository.getById('org-1')).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(buildOrganization(baseSettings)),
        );
        await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

        cubit.updateDraft(primaryColorHexInput: '#FFEB3B');

        expect(cubit.state.usesContrastFallback, isTrue);

        cubit.updateDraft(primaryColorHexInput: '#0A1F33');

        expect(cubit.state.usesContrastFallback, isFalse);
      },
    );

    test(
      'submit resends every existing setting alongside the edited branding',
      () async {
        final settingsWithPositivacao = baseSettings.copyWith(
          positivacaoPeriodGranularity: 'quarterly',
          positivacaoEligibleOrderStatuses: const <String>['invoiced'],
        );
        when(() => repository.getById('org-1')).thenAnswer(
          (_) async => AppSuccess<Organization>(
            buildOrganization(settingsWithPositivacao),
          ),
        );
        await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

        cubit.updateDraft(
          logoUrlInput: 'https://cdn.example.com/logo.png',
          primaryColorHexInput: '#1F5364',
        );

        final expectedSettings = settingsWithPositivacao.copyWith(
          brandingLogoUrl: 'https://cdn.example.com/logo.png',
          brandingPrimaryColorHex: '#1F5364',
        );
        when(
          () => repository.updateSettings(
            id: any(named: 'id'),
            settings: any(named: 'settings'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(buildOrganization(expectedSettings)),
        );

        await cubit.submit();

        expect(cubit.state.saveStatus, BrandingSettingsSaveStatus.success);
        verify(
          () => repository.updateSettings(
            id: 'org-1',
            settings: expectedSettings,
            updatedBy: 'user-2',
          ),
        ).called(1);
        verify(
          () => analyticsService.logEvent(
            AnalyticsEvents.catalogBrandingUpdated,
            parameters: any(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    test('submit clears branding when both fields are blanked out', () async {
      when(() => repository.getById('org-1')).thenAnswer(
        (_) async => AppSuccess<Organization>(
          buildOrganization(
            baseSettings.copyWith(
              brandingLogoUrl: 'https://cdn.example.com/logo.png',
              brandingPrimaryColorHex: '#1F5364',
            ),
          ),
        ),
      );
      await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');

      cubit.updateDraft(logoUrlInput: '   ', primaryColorHexInput: '  ');

      when(
        () => repository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Organization>(buildOrganization(baseSettings)),
      );

      await cubit.submit();

      verify(
        () => repository.updateSettings(
          id: 'org-1',
          settings: baseSettings,
          updatedBy: 'user-2',
        ),
      ).called(1);
    });

    test('submit surfaces a field-level error for a malformed color', () async {
      when(() => repository.getById('org-1')).thenAnswer(
        (_) async => AppSuccess<Organization>(buildOrganization(baseSettings)),
      );
      await cubit.load(organizationId: 'org-1', updatedBy: 'user-2');
      cubit.updateDraft(primaryColorHexInput: 'not-a-color');

      await cubit.submit();

      expect(cubit.state.saveStatus, BrandingSettingsSaveStatus.failure);
      expect(cubit.state.fieldErrors['brandingPrimaryColorHex'], isNotNull);
      verifyNever(
        () => repository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
      verifyNever(
        () => analyticsService.logEvent(
          any(),
          parameters: any(named: 'parameters'),
        ),
      );
    });
  });
}

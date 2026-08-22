import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('UpdateOrganizationSettingsUseCase', () {
    late _MockOrganizationRepository repository;
    late UpdateOrganizationSettingsUseCase useCase;

    const newSettings = OrganizationSettings(
      currency: 'USD',
      country: 'US',
      defaultLanguage: 'en-US',
    );

    final updatedOrganization = Organization(
      id: 'org-1',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto',
      settings: newSettings,
      status: OrganizationStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    setUp(() {
      repository = _MockOrganizationRepository();
      useCase = UpdateOrganizationSettingsUseCase(repository);
    });

    setUpAll(() {
      registerFallbackValue(newSettings);
    });

    test(
      'delegates to the repository and never asks it to change the id',
      () async {
        when(
          () => repository.updateSettings(
            id: any(named: 'id'),
            settings: any(named: 'settings'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Organization>(updatedOrganization),
        );

        final result = await useCase.call(
          id: 'org-1',
          currency: 'USD',
          country: 'US',
          defaultLanguage: 'en-US',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Organization>>());
        expect(
          (result as AppSuccess<Organization>).value.id,
          'org-1',
          reason: 'The use case has no parameter to change the id.',
        );
        verify(
          () => repository.updateSettings(
            id: 'org-1',
            settings: newSettings,
            updatedBy: 'user-2',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository for a '
        'blank id or updatedBy', () async {
      final result = await useCase.call(
        id: '  ',
        currency: 'USD',
        country: 'US',
        defaultLanguage: 'en-US',
        updatedBy: '',
      );

      expect(result, isA<AppFailure<Organization>>());
      final failure = (result as AppFailure<Organization>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['id', 'updatedBy']),
      );
      verifyNever(
        () => repository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });

    test('returns a ValidationFailure without calling the repository for '
        'invalid settings', () async {
      final result = await useCase.call(
        id: 'org-1',
        currency: '',
        country: '',
        defaultLanguage: '',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => repository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });

    test('propagates a conflict failure from the repository', () async {
      when(
        () => repository.updateSettings(
          id: any(named: 'id'),
          settings: any(named: 'settings'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<Organization>(
          const ConflictFailure('Conflict saving settings.'),
        ),
      );

      final result = await useCase.call(
        id: 'org-1',
        currency: 'USD',
        country: 'US',
        defaultLanguage: 'en-US',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ConflictFailure>(),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/organization_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_dto.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_settings_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/organization_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/organization_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationDataSource extends Mock
    implements OrganizationDataSource {}

void main() {
  group('OrganizationRepositoryImpl', () {
    late _MockOrganizationDataSource dataSource;
    late OrganizationRepositoryImpl repository;

    const settings = OrganizationSettings(
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
    );

    final createdDto = OrganizationDto(
      id: 'org-1',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto',
      settings: const OrganizationSettingsDto(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      ),
      status: 'active',
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUpAll(() {
      registerFallbackValue(
        OrganizationDto(
          id: 'fallback',
          name: 'fallback',
          slug: 'fallback',
          settings: const OrganizationSettingsDto(
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
          ),
          status: 'active',
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
        ),
      );
      registerFallbackValue(
        const OrganizationSettingsDto(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
      );
    });

    setUp(() {
      dataSource = _MockOrganizationDataSource();
      repository = OrganizationRepositoryImpl(
        dataSource: dataSource,
        mapper: const OrganizationMapper(),
      );
    });

    group('create', () {
      test(
        'returns a success mapping the DTO created by the datasource',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenAnswer((_) async => createdDto);

          final result = await repository.create(
            id: 'org-1',
            name: 'Grupo Fashion XPTO',
            slug: 'grupo-fashion-xpto',
            settings: settings,
            createdBy: 'user-1',
          );

          expect(result, isA<AppSuccess<Organization>>());
          final entity = (result as AppSuccess<Organization>).value;
          expect(entity.id, 'org-1');
          expect(entity.status, OrganizationStatus.active);
        },
      );

      test('is idempotent from the caller perspective: retrying create with '
          'the same id both times yields the same Organization, without the '
          'repository altering what the (already-idempotent) datasource '
          'returns', () async {
        when(
          () => dataSource.create(any()),
        ).thenAnswer((_) async => createdDto);

        final firstAttempt = await repository.create(
          id: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          settings: settings,
          createdBy: 'user-1',
        );
        final retryAfterNetworkFailure = await repository.create(
          id: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          settings: settings,
          createdBy: 'user-1',
        );

        expect(firstAttempt, isA<AppSuccess<Organization>>());
        expect(retryAfterNetworkFailure, isA<AppSuccess<Organization>>());
        expect(
          (firstAttempt as AppSuccess<Organization>).value,
          (retryAfterNetworkFailure as AppSuccess<Organization>).value,
        );

        final captured = verify(() => dataSource.create(captureAny())).captured;
        expect(captured, hasLength(2));
        expect((captured[0] as OrganizationDto).id, 'org-1');
        expect((captured[1] as OrganizationDto).id, 'org-1');
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenThrow(const ConflictException('Organization already exists.'));

          final result = await repository.create(
            id: 'org-1',
            name: 'Grupo Fashion XPTO',
            slug: 'grupo-fashion-xpto',
            settings: settings,
            createdBy: 'user-1',
          );

          expect(result, isA<AppFailure<Organization>>());
          expect(
            (result as AppFailure<Organization>).failure,
            isA<ConflictFailure>(),
          );
        },
      );

      test('maps a generic exception thrown by the datasource to an '
          'UnexpectedFailure', () async {
        when(() => dataSource.create(any())).thenThrow(StateError('boom'));

        final result = await repository.create(
          id: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          settings: settings,
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Organization>>());
        expect(
          (result as AppFailure<Organization>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('getById', () {
      test(
        'returns a success mapping the DTO found by the datasource',
        () async {
          when(
            () => dataSource.getById('org-1'),
          ).thenAnswer((_) async => createdDto);

          final result = await repository.getById('org-1');

          expect(result, isA<AppSuccess<Organization>>());
          expect((result as AppSuccess<Organization>).value.id, 'org-1');
        },
      );

      test(
        'returns a NotFoundFailure when the datasource finds nothing',
        () async {
          when(
            () => dataSource.getById('missing'),
          ).thenAnswer((_) async => null);

          final result = await repository.getById('missing');

          expect(result, isA<AppFailure<Organization>>());
          expect(
            (result as AppFailure<Organization>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.getById('org-1'),
          ).thenThrow(const ForbiddenException('Not allowed.'));

          final result = await repository.getById('org-1');

          expect(result, isA<AppFailure<Organization>>());
          expect(
            (result as AppFailure<Organization>).failure,
            isA<PermissionFailure>(),
          );
        },
      );
    });

    group('updateSettings', () {
      const newSettings = OrganizationSettings(
        currency: 'USD',
        country: 'US',
        defaultLanguage: 'en-US',
      );

      test('returns a success mapping the DTO updated by the datasource, and '
          'never asks it to change the id', () async {
        final updatedDto = OrganizationDto(
          id: 'org-1',
          name: createdDto.name,
          slug: createdDto.slug,
          settings: const OrganizationSettingsDto(
            currency: 'USD',
            country: 'US',
            defaultLanguage: 'en-US',
          ),
          status: 'active',
          createdAt: createdDto.createdAt,
          createdBy: createdDto.createdBy,
          updatedAt: DateTime.utc(2026, 1, 2),
          updatedBy: 'user-2',
        );

        when(
          () => dataSource.updateSettings(
            id: any(named: 'id'),
            settings: any(named: 'settings'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => updatedDto);

        final result = await repository.updateSettings(
          id: 'org-1',
          settings: newSettings,
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Organization>>());
        final entity = (result as AppSuccess<Organization>).value;
        expect(entity.id, 'org-1');
        expect(entity.settings, newSettings);

        final captured = verify(
          () => dataSource.updateSettings(
            id: captureAny(named: 'id'),
            settings: captureAny(named: 'settings'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: captureAny(named: 'updatedBy'),
          ),
        ).captured;
        expect(captured[0], 'org-1');
        expect((captured[1] as OrganizationSettingsDto).currency, 'USD');
        expect(captured[2], 'user-2');
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.updateSettings(
              id: any(named: 'id'),
              settings: any(named: 'settings'),
              updatedAt: any(named: 'updatedAt'),
              updatedBy: any(named: 'updatedBy'),
            ),
          ).thenThrow(const NotFoundException('Organization not found.'));

          final result = await repository.updateSettings(
            id: 'org-1',
            settings: newSettings,
            updatedBy: 'user-2',
          );

          expect(result, isA<AppFailure<Organization>>());
          expect(
            (result as AppFailure<Organization>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });
  });
}

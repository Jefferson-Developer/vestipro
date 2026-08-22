import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/company_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/company_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/company_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/company_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockCompanyDataSource extends Mock implements CompanyDataSource {}

void main() {
  group('CompanyRepositoryImpl', () {
    late _MockCompanyDataSource dataSource;
    late CompanyRepositoryImpl repository;

    CompanyDto buildDto({
      String id = 'company-1',
      String organizationId = 'org-1',
      String name = 'Marca A',
    }) {
      return CompanyDto(
        id: id,
        organizationId: organizationId,
        name: name,
        status: 'active',
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUpAll(() {
      registerFallbackValue(buildDto());
    });

    setUp(() {
      dataSource = _MockCompanyDataSource();
      repository = CompanyRepositoryImpl(
        dataSource: dataSource,
        mapper: const CompanyMapper(),
      );
    });

    group('create', () {
      test(
        'returns a success mapping the DTO created by the datasource',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenAnswer((_) async => buildDto());

          final result = await repository.create(
            id: 'company-1',
            organizationId: 'org-1',
            name: 'Marca A',
            createdBy: 'user-1',
          );

          expect(result, isA<AppSuccess<Company>>());
          final entity = (result as AppSuccess<Company>).value;
          expect(entity.id, 'company-1');
          expect(entity.organizationId, 'org-1');
          expect(entity.status, CompanyStatus.active);
          expect(entity.version, 1);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenThrow(const ConflictException('Company already exists.'));

          final result = await repository.create(
            id: 'company-1',
            organizationId: 'org-1',
            name: 'Marca A',
            createdBy: 'user-1',
          );

          expect(result, isA<AppFailure<Company>>());
          expect(
            (result as AppFailure<Company>).failure,
            isA<ConflictFailure>(),
          );
        },
      );

      test('maps a generic exception thrown by the datasource to an '
          'UnexpectedFailure', () async {
        when(() => dataSource.create(any())).thenThrow(StateError('boom'));

        final result = await repository.create(
          id: 'company-1',
          organizationId: 'org-1',
          name: 'Marca A',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Company>>());
        expect(
          (result as AppFailure<Company>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('listByOrganization', () {
      test('delegates to the datasource with the given organizationId and '
          'never mixes in a company from another organization', () async {
        final companiesOrg1 = <CompanyDto>[
          buildDto(id: 'company-1', organizationId: 'org-1'),
          buildDto(id: 'company-2', organizationId: 'org-1'),
        ];

        when(
          () => dataSource.listByOrganization('org-1'),
        ).thenAnswer((_) async => companiesOrg1);
        when(() => dataSource.listByOrganization('org-2')).thenAnswer(
          (_) async => <CompanyDto>[
            buildDto(id: 'company-3', organizationId: 'org-2'),
          ],
        );

        final result = await repository.listByOrganization('org-1');

        expect(result, isA<AppSuccess<List<Company>>>());
        final companies = (result as AppSuccess<List<Company>>).value;
        expect(companies, hasLength(2));
        expect(
          companies.every((company) => company.organizationId == 'org-1'),
          isTrue,
        );
        verify(() => dataSource.listByOrganization('org-1')).called(1);
        verifyNever(() => dataSource.listByOrganization('org-2'));
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.listByOrganization('org-1'),
          ).thenThrow(const ForbiddenException('Not allowed.'));

          final result = await repository.listByOrganization('org-1');

          expect(result, isA<AppFailure<List<Company>>>());
          expect(
            (result as AppFailure<List<Company>>).failure,
            isA<PermissionFailure>(),
          );
        },
      );
    });

    group('getById', () {
      test(
        'returns a success mapping the DTO found by the datasource',
        () async {
          when(
            () => dataSource.getById(organizationId: 'org-1', id: 'company-1'),
          ).thenAnswer((_) async => buildDto());

          final result = await repository.getById(
            organizationId: 'org-1',
            id: 'company-1',
          );

          expect(result, isA<AppSuccess<Company>>());
          expect((result as AppSuccess<Company>).value.id, 'company-1');
        },
      );

      test(
        'returns a NotFoundFailure when the datasource finds nothing',
        () async {
          when(
            () => dataSource.getById(organizationId: 'org-1', id: 'missing'),
          ).thenAnswer((_) async => null);

          final result = await repository.getById(
            organizationId: 'org-1',
            id: 'missing',
          );

          expect(result, isA<AppFailure<Company>>());
          expect(
            (result as AppFailure<Company>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });

    group('update', () {
      test('returns a success mapping the DTO updated by the datasource, '
          'and never asks it to change organizationId — the repository '
          'contract has no parameter for it', () async {
        final updatedDto = buildDto(name: 'Marca A Renomeada');

        when(
          () => dataSource.update(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            name: any(named: 'name'),
            legalName: any(named: 'legalName'),
            taxId: any(named: 'taxId'),
            status: any(named: 'status'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => updatedDto);

        final result = await repository.update(
          organizationId: 'org-1',
          id: 'company-1',
          name: 'Marca A Renomeada',
          status: CompanyStatus.active,
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Company>>());
        final entity = (result as AppSuccess<Company>).value;
        expect(entity.organizationId, 'org-1');
        expect(entity.name, 'Marca A Renomeada');

        final captured = verify(
          () => dataSource.update(
            organizationId: captureAny(named: 'organizationId'),
            id: captureAny(named: 'id'),
            name: captureAny(named: 'name'),
            legalName: any(named: 'legalName'),
            taxId: any(named: 'taxId'),
            status: any(named: 'status'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: captureAny(named: 'updatedBy'),
          ),
        ).captured;
        expect(captured[0], 'org-1');
        expect(captured[1], 'company-1');
        expect(captured[2], 'Marca A Renomeada');
        expect(captured[3], 'user-2');
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.update(
              organizationId: any(named: 'organizationId'),
              id: any(named: 'id'),
              name: any(named: 'name'),
              legalName: any(named: 'legalName'),
              taxId: any(named: 'taxId'),
              status: any(named: 'status'),
              updatedAt: any(named: 'updatedAt'),
              updatedBy: any(named: 'updatedBy'),
            ),
          ).thenThrow(const NotFoundException('Company not found.'));

          final result = await repository.update(
            organizationId: 'org-1',
            id: 'missing',
            name: 'Marca A',
            status: CompanyStatus.active,
            updatedBy: 'user-2',
          );

          expect(result, isA<AppFailure<Company>>());
          expect(
            (result as AppFailure<Company>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });
  });
}

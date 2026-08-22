import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/branch_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/branch_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/branch_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/branch_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockBranchDataSource extends Mock implements BranchDataSource {}

void main() {
  group('BranchRepositoryImpl', () {
    late _MockBranchDataSource dataSource;
    late BranchRepositoryImpl repository;

    BranchDto buildDto({
      String id = 'branch-1',
      String organizationId = 'org-1',
      String companyId = 'company-1',
      String name = 'Loja Blumenau',
    }) {
      return BranchDto(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: name,
        type: 'store',
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
      dataSource = _MockBranchDataSource();
      repository = BranchRepositoryImpl(
        dataSource: dataSource,
        mapper: const BranchMapper(),
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
            id: 'branch-1',
            organizationId: 'org-1',
            companyId: 'company-1',
            name: 'Loja Blumenau',
            type: BranchType.store,
            createdBy: 'user-1',
          );

          expect(result, isA<AppSuccess<Branch>>());
          final entity = (result as AppSuccess<Branch>).value;
          expect(entity.id, 'branch-1');
          expect(entity.organizationId, 'org-1');
          expect(entity.companyId, 'company-1');
          expect(entity.status, BranchStatus.active);
          expect(entity.version, 1);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenThrow(const ConflictException('Branch already exists.'));

          final result = await repository.create(
            id: 'branch-1',
            organizationId: 'org-1',
            companyId: 'company-1',
            name: 'Loja Blumenau',
            type: BranchType.store,
            createdBy: 'user-1',
          );

          expect(result, isA<AppFailure<Branch>>());
          expect(
            (result as AppFailure<Branch>).failure,
            isA<ConflictFailure>(),
          );
        },
      );
    });

    group('listByCompany', () {
      test(
        'delegates to the datasource with the given organizationId/'
        'companyId and never mixes in a branch from another company',
        () async {
          final branchesCompany1 = <BranchDto>[
            buildDto(id: 'branch-1', companyId: 'company-1'),
            buildDto(id: 'branch-2', companyId: 'company-1'),
          ];

          when(
            () => dataSource.listByCompany(
              organizationId: 'org-1',
              companyId: 'company-1',
            ),
          ).thenAnswer((_) async => branchesCompany1);
          when(
            () => dataSource.listByCompany(
              organizationId: 'org-1',
              companyId: 'company-2',
            ),
          ).thenAnswer(
            (_) async => <BranchDto>[
              buildDto(id: 'branch-3', companyId: 'company-2'),
            ],
          );

          final result = await repository.listByCompany(
            organizationId: 'org-1',
            companyId: 'company-1',
          );

          expect(result, isA<AppSuccess<List<Branch>>>());
          final branches = (result as AppSuccess<List<Branch>>).value;
          expect(branches, hasLength(2));
          expect(
            branches.every((branch) => branch.companyId == 'company-1'),
            isTrue,
          );
          verify(
            () => dataSource.listByCompany(
              organizationId: 'org-1',
              companyId: 'company-1',
            ),
          ).called(1);
          verifyNever(
            () => dataSource.listByCompany(
              organizationId: 'org-1',
              companyId: 'company-2',
            ),
          );
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.listByCompany(
              organizationId: 'org-1',
              companyId: 'company-1',
            ),
          ).thenThrow(const ForbiddenException('Not allowed.'));

          final result = await repository.listByCompany(
            organizationId: 'org-1',
            companyId: 'company-1',
          );

          expect(result, isA<AppFailure<List<Branch>>>());
          expect(
            (result as AppFailure<List<Branch>>).failure,
            isA<PermissionFailure>(),
          );
        },
      );
    });

    group('getById', () {
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

          expect(result, isA<AppFailure<Branch>>());
          expect(
            (result as AppFailure<Branch>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });

    group('update', () {
      test('returns a success mapping the DTO updated by the datasource, '
          'and never asks it to change organizationId/companyId — the '
          'repository contract has no parameter for either', () async {
        final updatedDto = buildDto(name: 'Loja Blumenau Centro');

        when(
          () => dataSource.update(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            name: any(named: 'name'),
            type: any(named: 'type'),
            address: any(named: 'address'),
            status: any(named: 'status'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => updatedDto);

        final result = await repository.update(
          organizationId: 'org-1',
          id: 'branch-1',
          name: 'Loja Blumenau Centro',
          type: BranchType.store,
          status: BranchStatus.active,
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Branch>>());
        final entity = (result as AppSuccess<Branch>).value;
        expect(entity.organizationId, 'org-1');
        expect(entity.companyId, 'company-1');
        expect(entity.name, 'Loja Blumenau Centro');
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.update(
              organizationId: any(named: 'organizationId'),
              id: any(named: 'id'),
              name: any(named: 'name'),
              type: any(named: 'type'),
              address: any(named: 'address'),
              status: any(named: 'status'),
              updatedAt: any(named: 'updatedAt'),
              updatedBy: any(named: 'updatedBy'),
            ),
          ).thenThrow(const NotFoundException('Branch not found.'));

          final result = await repository.update(
            organizationId: 'org-1',
            id: 'missing',
            name: 'Loja Blumenau',
            type: BranchType.store,
            status: BranchStatus.active,
            updatedBy: 'user-2',
          );

          expect(result, isA<AppFailure<Branch>>());
          expect(
            (result as AppFailure<Branch>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });
  });
}

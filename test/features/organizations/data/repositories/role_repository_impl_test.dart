import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/role_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/role_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/role_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/role_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockRoleDataSource extends Mock implements RoleDataSource {}

void main() {
  group('RoleRepositoryImpl', () {
    late _MockRoleDataSource dataSource;
    late RoleRepositoryImpl repository;

    RoleDto buildDto({
      String id = 'OWNER',
      String organizationId = 'org-1',
      bool isSystemRole = true,
    }) {
      return RoleDto(
        id: id,
        organizationId: organizationId,
        name: id,
        isSystemRole: isSystemRole,
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
      dataSource = _MockRoleDataSource();
      repository = RoleRepositoryImpl(
        dataSource: dataSource,
        mapper: const RoleMapper(),
      );
    });

    group('create', () {
      test('returns a success mapping the DTO created by the datasource, '
          'marked isSystemRole', () async {
        when(
          () => dataSource.create(any()),
        ).thenAnswer((_) async => buildDto());

        final result = await repository.create(
          id: 'OWNER',
          organizationId: 'org-1',
          name: 'OWNER',
          isSystemRole: true,
          createdBy: 'user-1',
        );

        expect(result, isA<AppSuccess<Role>>());
        final entity = (result as AppSuccess<Role>).value;
        expect(entity.id, 'OWNER');
        expect(entity.isSystemRole, isTrue);
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.create(any()),
          ).thenThrow(const ConflictException('Role already exists.'));

          final result = await repository.create(
            id: 'OWNER',
            organizationId: 'org-1',
            name: 'OWNER',
            isSystemRole: true,
            createdBy: 'user-1',
          );

          expect(result, isA<AppFailure<Role>>());
          expect((result as AppFailure<Role>).failure, isA<ConflictFailure>());
        },
      );
    });

    group('listByOrganization', () {
      test('delegates to the datasource with the given organizationId and '
          'never mixes in a role from another organization', () async {
        final rolesOrg1 = <RoleDto>[
          buildDto(id: 'OWNER', organizationId: 'org-1'),
          buildDto(id: 'ADMIN', organizationId: 'org-1'),
        ];

        when(
          () => dataSource.listByOrganization('org-1'),
        ).thenAnswer((_) async => rolesOrg1);
        when(() => dataSource.listByOrganization('org-2')).thenAnswer(
          (_) async => <RoleDto>[
            buildDto(id: 'OWNER', organizationId: 'org-2'),
          ],
        );

        final result = await repository.listByOrganization('org-1');

        expect(result, isA<AppSuccess<List<Role>>>());
        final roles = (result as AppSuccess<List<Role>>).value;
        expect(roles, hasLength(2));
        expect(roles.every((role) => role.organizationId == 'org-1'), isTrue);
        verify(() => dataSource.listByOrganization('org-1')).called(1);
        verifyNever(() => dataSource.listByOrganization('org-2'));
      });
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

          expect(result, isA<AppFailure<Role>>());
          expect((result as AppFailure<Role>).failure, isA<NotFoundFailure>());
        },
      );
    });
  });
}

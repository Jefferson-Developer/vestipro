import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/membership_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/membership_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/membership_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/membership_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipDataSource extends Mock implements MembershipDataSource {}

void main() {
  group('MembershipRepositoryImpl', () {
    late _MockMembershipDataSource dataSource;
    late MembershipRepositoryImpl repository;

    MembershipDto buildDto({
      String id = 'user-1',
      String organizationId = 'org-1',
      String userId = 'user-1',
      String roleId = 'SALES_REP',
      String status = 'active',
    }) {
      return MembershipDto(
        id: id,
        organizationId: organizationId,
        userId: userId,
        roleId: roleId,
        roleName: roleId,
        status: status,
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
      dataSource = _MockMembershipDataSource();
      repository = MembershipRepositoryImpl(
        dataSource: dataSource,
        mapper: const MembershipMapper(),
      );
    });

    group('create', () {
      test('creates an active Membership whose id mirrors userId', () async {
        when(
          () => dataSource.create(any()),
        ).thenAnswer((_) async => buildDto());

        final result = await repository.create(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          createdBy: 'user-owner',
        );

        expect(result, isA<AppSuccess<Membership>>());
        final entity = (result as AppSuccess<Membership>).value;
        expect(entity.id, entity.userId);
        expect(entity.status, MembershipStatus.active);
      });
    });

    group('listByOrganization', () {
      test('delegates to the datasource with the given organizationId and '
          'never mixes in a membership from another organization', () async {
        final membershipsOrg1 = <MembershipDto>[
          buildDto(id: 'user-1', organizationId: 'org-1', userId: 'user-1'),
          buildDto(id: 'user-2', organizationId: 'org-1', userId: 'user-2'),
        ];

        when(
          () => dataSource.listByOrganization('org-1'),
        ).thenAnswer((_) async => membershipsOrg1);
        when(() => dataSource.listByOrganization('org-2')).thenAnswer(
          (_) async => <MembershipDto>[
            buildDto(id: 'user-3', organizationId: 'org-2', userId: 'user-3'),
          ],
        );

        final result = await repository.listByOrganization('org-1');

        expect(result, isA<AppSuccess<List<Membership>>>());
        final memberships = (result as AppSuccess<List<Membership>>).value;
        expect(memberships, hasLength(2));
        expect(
          memberships.every(
            (membership) => membership.organizationId == 'org-1',
          ),
          isTrue,
        );
        verifyNever(() => dataSource.listByOrganization('org-2'));
      });
    });

    group('getByUser', () {
      test(
        'returns a NotFoundFailure when the user has no membership',
        () async {
          when(
            () => dataSource.getByUser(
              organizationId: 'org-1',
              userId: 'missing-user',
            ),
          ).thenAnswer((_) async => null);

          final result = await repository.getByUser(
            organizationId: 'org-1',
            userId: 'missing-user',
          );

          expect(result, isA<AppFailure<Membership>>());
          expect(
            (result as AppFailure<Membership>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );
    });

    group('update', () {
      test('returns a success mapping the DTO updated by the datasource, '
          'and never asks it to change organizationId/userId — the '
          'repository contract has no parameter for it', () async {
        when(
          () => dataSource.update(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
            roleId: any(named: 'roleId'),
            roleName: any(named: 'roleName'),
            teamIds: any(named: 'teamIds'),
            status: any(named: 'status'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => buildDto(roleId: 'SALES_MANAGER'));

        final result = await repository.update(
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'SALES_MANAGER',
          roleName: 'SALES_MANAGER',
          teamIds: const <String>[],
          status: MembershipStatus.active,
          updatedBy: 'user-owner',
        );

        expect(result, isA<AppSuccess<Membership>>());
        final entity = (result as AppSuccess<Membership>).value;
        expect(entity.organizationId, 'org-1');
        expect(entity.userId, 'user-1');
        expect(entity.roleId, 'SALES_MANAGER');
      });
    });
  });
}

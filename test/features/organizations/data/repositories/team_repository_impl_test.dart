import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/data/datasources/team_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/team_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/team_mapper.dart';
import 'package:vestipro/features/organizations/data/repositories/team_repository_impl.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamDataSource extends Mock implements TeamDataSource {}

void main() {
  group('TeamRepositoryImpl', () {
    late _MockTeamDataSource dataSource;
    late TeamRepositoryImpl repository;

    TeamDto buildDto({
      String id = 'team-1',
      String organizationId = 'org-1',
      String managerUserId = 'manager-1',
      List<String> memberIds = const <String>[],
    }) {
      return TeamDto(
        id: id,
        organizationId: organizationId,
        name: 'Equipe Blumenau',
        managerUserId: managerUserId,
        memberIds: memberIds,
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
      dataSource = _MockTeamDataSource();
      repository = TeamRepositoryImpl(
        dataSource: dataSource,
        mapper: const TeamMapper(),
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
            id: 'team-1',
            organizationId: 'org-1',
            name: 'Equipe Blumenau',
            managerUserId: 'manager-1',
            createdBy: 'user-1',
          );

          expect(result, isA<AppSuccess<Team>>());
          expect((result as AppSuccess<Team>).value.id, 'team-1');
        },
      );
    });

    group('listByOrganization', () {
      test('delegates to the datasource with the given organizationId and '
          'never mixes in a team from another organization', () async {
        final teamsOrg1 = <TeamDto>[
          buildDto(id: 'team-1', organizationId: 'org-1'),
          buildDto(id: 'team-2', organizationId: 'org-1'),
        ];

        when(
          () => dataSource.listByOrganization('org-1'),
        ).thenAnswer((_) async => teamsOrg1);
        when(() => dataSource.listByOrganization('org-2')).thenAnswer(
          (_) async => <TeamDto>[
            buildDto(id: 'team-3', organizationId: 'org-2'),
          ],
        );

        final result = await repository.listByOrganization('org-1');

        expect(result, isA<AppSuccess<List<Team>>>());
        final teams = (result as AppSuccess<List<Team>>).value;
        expect(teams, hasLength(2));
        expect(teams.every((team) => team.organizationId == 'org-1'), isTrue);
        verifyNever(() => dataSource.listByOrganization('org-2'));
      });
    });

    group('addMember', () {
      test(
        'returns a success mapping the DTO updated by the datasource',
        () async {
          when(
            () => dataSource.addMember(
              organizationId: any(named: 'organizationId'),
              id: any(named: 'id'),
              userId: any(named: 'userId'),
              updatedAt: any(named: 'updatedAt'),
              updatedBy: any(named: 'updatedBy'),
            ),
          ).thenAnswer(
            (_) async => buildDto(memberIds: const <String>['user-1']),
          );

          final result = await repository.addMember(
            organizationId: 'org-1',
            id: 'team-1',
            userId: 'user-1',
            updatedBy: 'user-2',
          );

          expect(result, isA<AppSuccess<Team>>());
          expect((result as AppSuccess<Team>).value.memberIds, <String>[
            'user-1',
          ]);
        },
      );

      test('maps a NotFoundException thrown by the datasource to a Failure '
          'when the team does not exist', () async {
        when(
          () => dataSource.addMember(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            userId: any(named: 'userId'),
            updatedAt: any(named: 'updatedAt'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenThrow(const NotFoundException('Team not found.'));

        final result = await repository.addMember(
          organizationId: 'org-1',
          id: 'missing-team',
          userId: 'user-1',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppFailure<Team>>());
        expect((result as AppFailure<Team>).failure, isA<NotFoundFailure>());
      });
    });
  });
}

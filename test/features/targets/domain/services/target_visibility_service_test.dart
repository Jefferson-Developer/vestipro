import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('TargetVisibilityService', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late TargetVisibilityService service;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      service = TargetVisibilityService(
        PortfolioVisibilityService(membershipRepository, teamRepository),
        teamRepository,
      );
    });

    Membership buildMembership(
      String roleName, {
      List<String> teamIds = const <String>[],
    }) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: roleName,
        roleName: roleName,
        teamIds: teamIds,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    test(
      'OWNER/ADMIN resolve to allOrganization: can view any dimension',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('OWNER')),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'user-1',
        );

        final filter = (result as AppSuccess<TargetVisibilityFilter>).value;
        expect(filter.mode, TargetVisibilityMode.allOrganization);
        expect(
          filter.canView(
            dimensionType: TargetDimensionType.salesRep,
            dimensionId: 'someone-else',
          ),
          isTrue,
        );
        expect(
          filter.canView(
            dimensionType: TargetDimensionType.company,
            dimensionId: 'company-1',
          ),
          isTrue,
        );
      },
    );

    test('SALES_REP resolves to ownOnly: never sees another vendedor\'s '
        'meta, and never a team/company one either', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      final filter = (result as AppSuccess<TargetVisibilityFilter>).value;
      expect(filter.mode, TargetVisibilityMode.ownOnly);
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.salesRep,
          dimensionId: 'user-1',
        ),
        isTrue,
        reason: 'a SALES_REP must always see their own meta.',
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.salesRep,
          dimensionId: 'other-rep',
        ),
        isFalse,
        reason: 'a SALES_REP must never see another vendedor\'s meta.',
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.team,
          dimensionId: 'team-a',
        ),
        isFalse,
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.company,
          dimensionId: 'company-1',
        ),
        isFalse,
      );
    });

    test('SALES_MANAGER resolves to teams: sees their own meta, their '
        "teams' and their teammates', but never a stranger's", () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership('SALES_MANAGER', teamIds: ['team-a']),
        ),
      );
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Team>>(<Team>[
          Team(
            id: 'team-a',
            organizationId: 'org-1',
            name: 'Equipe A',
            managerUserId: 'user-1',
            memberIds: const <String>['rep-1', 'rep-2'],
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
          Team(
            id: 'team-b',
            organizationId: 'org-1',
            name: 'Equipe B',
            managerUserId: 'other-manager',
            memberIds: const <String>['rep-3'],
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ]),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      final filter = (result as AppSuccess<TargetVisibilityFilter>).value;
      expect(filter.mode, TargetVisibilityMode.teams);
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.salesRep,
          dimensionId: 'user-1',
        ),
        isTrue,
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.salesRep,
          dimensionId: 'rep-1',
        ),
        isTrue,
        reason: 'rep-1 belongs to the manager\'s own team-a.',
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.salesRep,
          dimensionId: 'rep-3',
        ),
        isFalse,
        reason: 'rep-3 belongs to team-b, not managed by this caller.',
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.team,
          dimensionId: 'team-a',
        ),
        isTrue,
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.team,
          dimensionId: 'team-b',
        ),
        isFalse,
      );
      expect(
        filter.canView(
          dimensionType: TargetDimensionType.company,
          dimensionId: 'company-1',
        ),
        isTrue,
      );
    });

    test(
      'a role with no Membership resolves to none: cannot view anything',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'stranger',
          ),
        ).thenAnswer(
          (_) async => const AppFailure<Membership>(
            NotFoundFailure('Membership not found.'),
          ),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'stranger',
        );

        final filter = (result as AppSuccess<TargetVisibilityFilter>).value;
        expect(filter.mode, TargetVisibilityMode.none);
        expect(filter.canViewAny, isFalse);
        expect(
          filter.canView(
            dimensionType: TargetDimensionType.salesRep,
            dimensionId: 'stranger',
          ),
          isFalse,
        );
      },
    );
  });
}

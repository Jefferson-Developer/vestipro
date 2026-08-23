import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('PortfolioVisibilityService', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late PortfolioVisibilityService service;

    Membership membership({
      required String userId,
      required String roleName,
      List<String> teamIds = const <String>[],
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        teamIds: teamIds,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    Team team({
      required String id,
      required String managerUserId,
      List<String> memberIds = const <String>[],
    }) {
      return Team(
        id: id,
        organizationId: 'org-1',
        name: 'Equipe $id',
        managerUserId: managerUserId,
        memberIds: memberIds,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      service = PortfolioVisibilityService(
        membershipRepository,
        teamRepository,
      );
    });

    test('resolves SALES_REP to own customer filter', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'rep-1', roleName: 'SALES_REP'),
        ),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
      );

      expect(result, isA<AppSuccess<CustomerVisibilityFilter>>());
      final filter = (result as AppSuccess<CustomerVisibilityFilter>).value;
      expect(filter.mode, CustomerVisibilityMode.ownCustomers);
      expect(filter.requiresPrimarySalesRepFilter, isTrue);
      verifyNever(() => teamRepository.listByOrganization(any()));
    });

    test(
      'resolves SALES_MANAGER to teams managed or linked to membership',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            membership(
              userId: 'manager-1',
              roleName: 'SALES_MANAGER',
              teamIds: const <String>['team-membership'],
            ),
          ),
        );
        when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Team>>([
            team(id: 'team-managed', managerUserId: 'manager-1'),
            team(id: 'team-other', managerUserId: 'manager-2'),
          ]),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
        );

        expect(result, isA<AppSuccess<CustomerVisibilityFilter>>());
        final filter = (result as AppSuccess<CustomerVisibilityFilter>).value;
        expect(filter.mode, CustomerVisibilityMode.teams);
        expect(filter.teamIds, <String>{'team-membership', 'team-managed'});
        expect(filter.requiresTeamFilter, isTrue);
      },
    );

    test('resolves ADMIN and OWNER to all organization filter', () async {
      for (final roleName in <String>['ADMIN', 'OWNER']) {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: roleName.toLowerCase(),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            membership(userId: roleName.toLowerCase(), roleName: roleName),
          ),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: roleName.toLowerCase(),
        );

        expect(result, isA<AppSuccess<CustomerVisibilityFilter>>());
        expect(
          (result as AppSuccess<CustomerVisibilityFilter>).value.mode,
          CustomerVisibilityMode.allOrganization,
        );
      }
    });

    test('fails closed for inactive membership', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(
            userId: 'rep-1',
            roleName: 'SALES_REP',
            status: MembershipStatus.inactive,
          ),
        ),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
      );

      expect(result, isA<AppSuccess<CustomerVisibilityFilter>>());
      expect(
        (result as AppSuccess<CustomerVisibilityFilter>).value.mode,
        CustomerVisibilityMode.none,
      );
    });

    test('validates required tenant fields', () async {
      final result = await service.resolve(
        organizationId: ' ',
        companyId: '',
        userId: '',
      );

      expect(result, isA<AppFailure<CustomerVisibilityFilter>>());
      final failure = (result as AppFailure<CustomerVisibilityFilter>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'companyId', 'userId']),
      );
    });
  });
}

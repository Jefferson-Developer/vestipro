import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('OrderVisibilityService', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late OrderVisibilityService service;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      service = OrderVisibilityService(
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

    test('OWNER/ADMIN resolve to allCompany, no seller restriction', () async {
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

      final filter = (result as AppSuccess<OrderVisibilityFilter>).value;
      expect(filter.mode, OrderVisibilityMode.allCompany);
      expect(filter.sellerIds, isEmpty);
      expect(filter.canReadAny, isTrue);
    });

    test('SALES_REP resolves to ownOnly, restricted to their own id', () async {
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

      final filter = (result as AppSuccess<OrderVisibilityFilter>).value;
      expect(filter.mode, OrderVisibilityMode.ownOnly);
      expect(filter.sellerIds, <String>{'user-1'});
    });

    test('SALES_MANAGER resolves to sellerSubset from their teams\' '
        'memberIds — never via a bulk members list query', () async {
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

      final filter = (result as AppSuccess<OrderVisibilityFilter>).value;
      expect(filter.mode, OrderVisibilityMode.sellerSubset);
      expect(filter.sellerIds, <String>{'rep-1', 'rep-2'});
      verifyNever(() => membershipRepository.listByOrganization(any()));
    });

    test('a role with no Membership resolves to none', () async {
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

      final filter = (result as AppSuccess<OrderVisibilityFilter>).value;
      expect(filter.mode, OrderVisibilityMode.none);
      expect(filter.canReadAny, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MembershipRepository extends Mock implements MembershipRepository {}

class _TeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MembershipRepository memberships;
  late _TeamRepository teams;
  late RepresentativeDashboardVisibilityService service;

  setUp(() {
    memberships = _MembershipRepository();
    teams = _TeamRepository();
    service = RepresentativeDashboardVisibilityService(memberships, teams);
  });

  Membership member(
    String userId,
    String role, {
    List<String> teamIds = const [],
  }) {
    return Membership(
      id: userId,
      organizationId: 'org-1',
      userId: userId,
      roleId: role,
      roleName: role,
      teamIds: teamIds,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026),
      createdBy: 'owner',
      updatedAt: DateTime.utc(2026),
      updatedBy: 'owner',
    );
  }

  test('representative can view their own dashboard', () async {
    when(
      () => memberships.getByUser(organizationId: 'org-1', userId: 'rep-1'),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(member('rep-1', 'SALES_REP')),
    );

    final result = await service.canView(
      organizationId: 'org-1',
      requesterUserId: 'rep-1',
      sellerId: 'rep-1',
    );
    expect((result as AppSuccess<bool>).value, isTrue);
  });

  test('representative cannot view another seller', () async {
    when(
      () => memberships.getByUser(organizationId: 'org-1', userId: 'rep-1'),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(member('rep-1', 'SALES_REP')),
    );

    final result = await service.canView(
      organizationId: 'org-1',
      requesterUserId: 'rep-1',
      sellerId: 'rep-2',
    );
    expect((result as AppSuccess<bool>).value, isFalse);
  });

  test('manager can only view a seller from a managed team', () async {
    when(
      () => memberships.getByUser(
        organizationId: 'org-1',
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#userId] as String;
      if (id == 'manager-1') {
        return AppSuccess<Membership>(
          member('manager-1', 'SALES_MANAGER', teamIds: ['team-a']),
        );
      }
      return AppSuccess<Membership>(
        member(
          id,
          'SALES_REP',
          teamIds: id == 'rep-a' ? ['team-a'] : ['team-b'],
        ),
      );
    });
    when(
      () => teams.listByOrganization('org-1'),
    ).thenAnswer((_) async => const AppSuccess<List<Team>>(<Team>[]));

    final allowed = await service.canView(
      organizationId: 'org-1',
      requesterUserId: 'manager-1',
      sellerId: 'rep-a',
    );
    final denied = await service.canView(
      organizationId: 'org-1',
      requesterUserId: 'manager-1',
      sellerId: 'rep-b',
    );
    expect((allowed as AppSuccess<bool>).value, isTrue);
    expect((denied as AppSuccess<bool>).value, isFalse);
  });
}

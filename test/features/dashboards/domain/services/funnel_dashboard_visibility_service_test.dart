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
  late FunnelDashboardVisibilityService service;

  setUp(() {
    memberships = _MembershipRepository();
    teams = _TeamRepository();
    service = FunnelDashboardVisibilityService(memberships, teams);
  });

  test('representative scope contains only their own seller id', () async {
    when(
      () => memberships.getByUser(organizationId: 'org-1', userId: 'rep-1'),
    ).thenAnswer((_) async => AppSuccess(_member('rep-1', 'SALES_REP')));
    final result = await service.resolve(
      organizationId: 'org-1',
      userId: 'rep-1',
    );
    final scope = (result as AppSuccess<FunnelDashboardVisibility>).value;
    expect(scope.mode, FunnelDashboardVisibilityMode.own);
    expect(scope.allowedSellerIds, <String>{'rep-1'});
    expect(scope.allowsSeller('rep-2'), isFalse);
  });

  test('manager scope contains members only from managed teams', () async {
    when(
      () => memberships.getByUser(organizationId: 'org-1', userId: 'manager-1'),
    ).thenAnswer(
      (_) async => AppSuccess(
        _member('manager-1', 'SALES_MANAGER', teamIds: <String>['team-a']),
      ),
    );
    when(() => teams.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess(<Team>[
        _team('team-a', 'manager-1', <String>['rep-a']),
        _team('team-b', 'manager-2', <String>['rep-b']),
      ]),
    );
    final result = await service.resolve(
      organizationId: 'org-1',
      userId: 'manager-1',
    );
    final scope = (result as AppSuccess<FunnelDashboardVisibility>).value;
    expect(scope.allowedSellerIds, <String>{'manager-1', 'rep-a'});
    expect(scope.allowsSeller('rep-b'), isFalse);
  });
}

Membership _member(
  String id,
  String role, {
  List<String> teamIds = const <String>[],
}) => Membership(
  id: id,
  organizationId: 'org-1',
  userId: id,
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

Team _team(String id, String manager, List<String> members) => Team(
  id: id,
  organizationId: 'org-1',
  name: id,
  managerUserId: manager,
  memberIds: members,
  version: 1,
  createdAt: DateTime.utc(2026),
  createdBy: 'owner',
  updatedAt: DateTime.utc(2026),
  updatedBy: 'owner',
);

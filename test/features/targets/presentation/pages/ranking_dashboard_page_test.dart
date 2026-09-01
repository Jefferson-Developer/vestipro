import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late TargetVisibilityService visibilityService;
  late _MockTeamRepository teamRepository;
  late _MockOrganizationRepository organizationRepository;
  late _InMemoryTargetRepository targetRepository;
  late _FakeTargetAchievementRepository achievementRepository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    permissionService = PermissionService(membershipRepository);
    visibilityService = TargetVisibilityService(
      PortfolioVisibilityService(membershipRepository, teamRepository),
      teamRepository,
    );
    organizationRepository = _MockOrganizationRepository();
    targetRepository = _InMemoryTargetRepository();
    achievementRepository = _FakeTargetAchievementRepository();
  });

  void stubMembership(
    String userId,
    String roleName, {
    List<String> teamIds = const <String>[],
  }) {
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: userId,
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: userId,
          organizationId: 'org-1',
          userId: userId,
          roleId: roleName,
          roleName: roleName,
          teamIds: teamIds,
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
    );
  }

  void stubOrganizationRoster(List<(String, String)> idsAndNames) {
    when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess<List<Membership>>(<Membership>[
        for (final (id, name) in idsAndNames)
          Membership(
            id: id,
            organizationId: 'org-1',
            userId: id,
            roleId: 'SALES_REP',
            roleName: 'SALES_REP',
            status: MembershipStatus.active,
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
            name: name,
          ),
      ]),
    );
  }

  void stubTeamOf(String teamId, List<String> memberIds) {
    when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess<List<Team>>(<Team>[
        Team(
          id: teamId,
          organizationId: 'org-1',
          name: 'Equipe $teamId',
          managerUserId: 'manager-1',
          memberIds: memberIds,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ]),
    );
  }

  void stubOrganization({
    String rankingVisibilityMode = defaultRankingVisibilityMode,
  }) {
    when(() => organizationRepository.getById('org-1')).thenAnswer(
      (_) async => AppSuccess<Organization>(
        _organization(rankingVisibilityMode: rankingVisibilityMode),
      ),
    );
  }

  Widget buildPage({String userId = 'rep-1'}) {
    return RankingDashboardPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: userId,
      permissionService: permissionService,
      createCubit: () => RankingDashboardCubit(
        visibilityService,
        RankingPeerResolverService(membershipRepository, teamRepository),
        GetOrganizationUseCase(organizationRepository),
        targetRepository,
        achievementRepository,
        membershipRepository,
        teamRepository,
        const RankingCalculationService(),
        FakeAnalyticsService(),
      ),
    );
  }

  testWidgets('shows a loading indicator while resolving visibility/peers', (
    tester,
  ) async {
    stubMembership('rep-1', 'SALES_REP', teamIds: <String>['team-a']);
    stubTeamOf('team-a', <String>['rep-1']);
    stubOrganization();

    await pumpApp(tester, buildPage());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('ranking carregado: shows every peer ranked by atingimento %, '
      'highlighting the current user\'s row and position', (tester) async {
    stubMembership('rep-1', 'SALES_REP', teamIds: <String>['team-a']);
    stubTeamOf('team-a', <String>['rep-1', 'rep-2', 'rep-3']);
    stubOrganizationRoster(<(String, String)>[
      ('rep-1', 'Ana'),
      ('rep-2', 'Bruno'),
      ('rep-3', 'Carla'),
    ]);
    stubOrganization();

    targetRepository.items.addAll(<Target>[
      _target(id: 'target-1', dimensionId: 'rep-1', targetValue: 100),
      _target(id: 'target-2', dimensionId: 'rep-2', targetValue: 100),
      _target(id: 'target-3', dimensionId: 'rep-3', targetValue: 100),
    ]);
    achievementRepository.seed(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 90,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );
    achievementRepository.seed(
      'target-2',
      TargetAchievementSnapshot(
        targetId: 'target-2',
        realizedValue: 50,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );
    achievementRepository.seed(
      'target-3',
      TargetAchievementSnapshot(
        targetId: 'target-3',
        realizedValue: 20,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    // rep-1 (Ana, 90%) is #1 of 3 — the caller's own position highlight.
    expect(find.widgetWithText(AppKpiCard, 'Sua posição'), findsOneWidget);
    expect(find.textContaining('1º de 3'), findsOneWidget);

    // Every peer's name and % are visible (full ranking, default org
    // setting), the caller's row carries a "Você" badge.
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('Você'), findsWidgets);
  });

  testWidgets('RBAC: a SALES_REP under an organization configured for '
      'relative_position_only never sees a peer\'s name or value', (
    tester,
  ) async {
    stubMembership('rep-1', 'SALES_REP', teamIds: <String>['team-a']);
    stubTeamOf('team-a', <String>['rep-1', 'rep-2', 'rep-3']);
    stubOrganizationRoster(<(String, String)>[
      ('rep-1', 'Ana'),
      ('rep-2', 'Bruno'),
      ('rep-3', 'Carla'),
    ]);
    stubOrganization(rankingVisibilityMode: 'relative_position_only');

    targetRepository.items.addAll(<Target>[
      _target(id: 'target-1', dimensionId: 'rep-1', targetValue: 100),
      _target(id: 'target-2', dimensionId: 'rep-2', targetValue: 100),
      _target(id: 'target-3', dimensionId: 'rep-3', targetValue: 100),
    ]);
    achievementRepository.seed(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 20,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );
    achievementRepository.seed(
      'target-2',
      TargetAchievementSnapshot(
        targetId: 'target-2',
        realizedValue: 90,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );
    achievementRepository.seed(
      'target-3',
      TargetAchievementSnapshot(
        targetId: 'target-3',
        realizedValue: 50,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    // The caller (rep-1, Ana, 20%) is #3 of 3 — their own rank/total is
    // still shown...
    expect(find.textContaining('3º de 3'), findsOneWidget);
    // ...but no other peer's name ever renders anywhere on the page.
    expect(find.text('Bruno'), findsNothing);
    expect(find.text('Carla'), findsNothing);
    expect(find.text('Ranking nominal restrito'), findsOneWidget);
  });

  testWidgets(
    'estado vazio: no Target exists for any peer in this dimension/metric',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP', teamIds: <String>['team-a']);
      stubTeamOf('team-a', <String>['rep-1']);
      stubOrganization();

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma meta cadastrada para este período'),
        findsOneWidget,
      );
    },
  );

  testWidgets('erro ao carregar: a failure resolving the organization shows '
      'the error state', (tester) async {
    stubMembership('rep-1', 'SALES_REP', teamIds: <String>['team-a']);
    stubTeamOf('team-a', <String>['rep-1']);
    when(() => organizationRepository.getById('org-1')).thenAnswer(
      (_) async =>
          const AppFailure<Organization>(ConnectivityFailure('offline')),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o ranking'), findsOneWidget);
  });

  testWidgets(
    'a SALES_MANAGER/ADMIN always sees the full ranking regardless of the '
    'organization setting',
    (tester) async {
      stubMembership('manager-1', 'SALES_MANAGER', teamIds: <String>['team-a']);
      stubTeamOf('team-a', <String>['rep-1', 'rep-2']);
      stubOrganizationRoster(<(String, String)>[
        ('rep-1', 'Ana'),
        ('rep-2', 'Bruno'),
      ]);
      stubOrganization(rankingVisibilityMode: 'relative_position_only');

      targetRepository.items.addAll(<Target>[
        _target(id: 'target-1', dimensionId: 'rep-1', targetValue: 100),
        _target(id: 'target-2', dimensionId: 'rep-2', targetValue: 100),
      ]);
      achievementRepository.seed(
        'target-1',
        TargetAchievementSnapshot(
          targetId: 'target-1',
          realizedValue: 90,
          calculatedAt: DateTime.utc(2026, 1, 16),
        ),
      );
      achievementRepository.seed(
        'target-2',
        TargetAchievementSnapshot(
          targetId: 'target-2',
          realizedValue: 50,
          calculatedAt: DateTime.utc(2026, 1, 16),
        ),
      );

      await pumpApp(tester, buildPage(userId: 'manager-1'));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Ranking nominal restrito'), findsNothing);
    },
  );
}

Organization _organization({
  String rankingVisibilityMode = defaultRankingVisibilityMode,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Organization(
    id: 'org-1',
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: OrganizationSettings(
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
      rankingVisibilityMode: rankingVisibilityMode,
    ),
    status: OrganizationStatus.active,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

Target _target({
  required String id,
  required String dimensionId,
  double targetValue = 100000,
  TargetDimensionType dimensionType = TargetDimensionType.salesRep,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: dimensionType,
    dimensionId: dimensionId,
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: DateTime.utc(2026, 1, 1),
    endDate: DateTime.utc(2026, 2, 1),
    metricType: TargetMetricType.revenue,
    targetValue: targetValue,
    currency: 'BRL',
    status: TargetStatus.active,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
}

final class _InMemoryTargetRepository implements TargetRepository {
  final List<Target> items = <Target>[];

  @override
  Future<AppResult<Target>> create({required Target target}) async {
    items.add(target);
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> update({required Target target}) async {
    final index = items.indexWhere((item) => item.id == target.id);
    if (index >= 0) items[index] = target;
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final item in items) {
      if (item.id == id) return AppSuccess<Target>(item);
    }
    return const AppFailure<Target>(
      NotFoundFailure('Target not found.', code: 'target_not_found'),
    );
  }

  @override
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    return AppSuccess<List<Target>>(
      items
          .where(
            (item) =>
                item.dimensionType == dimensionType &&
                item.dimensionId == dimensionId &&
                (metricType == null || item.metricType == metricType),
          )
          .toList(),
    );
  }
}

/// In-memory fake of [TargetAchievementRepository] — same precedent as
/// `target_dashboard_page_test.dart`'s own fake. `RankingDashboardCubit`
/// only ever calls [getForTarget] (a one-shot read per peer, never a
/// long-lived subscription per peer), but the interface still requires
/// [watchForTarget] to compile.
final class _FakeTargetAchievementRepository
    implements TargetAchievementRepository {
  final Map<String, TargetAchievementSnapshot> _current =
      <String, TargetAchievementSnapshot>{};
  final Set<String> _failing = <String>{};

  void seed(String targetId, TargetAchievementSnapshot snapshot) {
    _current[targetId] = snapshot;
  }

  void failFor(String targetId) {
    _failing.add(targetId);
  }

  @override
  Future<AppResult<TargetAchievementSnapshot>> getForTarget({
    required String organizationId,
    required String targetId,
  }) async {
    if (_failing.contains(targetId)) {
      return AppFailure<TargetAchievementSnapshot>(
        const UnexpectedFailure('boom'),
      );
    }
    return AppSuccess<TargetAchievementSnapshot>(
      _current[targetId] ?? TargetAchievementSnapshot(targetId: targetId),
    );
  }

  @override
  Stream<TargetAchievementSnapshot> watchForTarget({
    required String organizationId,
    required String targetId,
  }) async* {
    yield _current[targetId] ?? TargetAchievementSnapshot(targetId: targetId);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late TargetVisibilityService visibilityService;
  late _MockTeamRepository teamRepository;
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

  Widget buildPage({String userId = 'rep-1'}) {
    return TargetDashboardPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: userId,
      permissionService: permissionService,
      createCubit: () => TargetDashboardCubit(
        visibilityService,
        targetRepository,
        achievementRepository,
        FakeAnalyticsService(),
        const ClosingProjectionService(),
        ProcessTargetAlertUseCase(
          _FakeTargetAlertSettingsRepository(),
          _FakeTargetAlertDispatchRepository(),
          _FakeNotificationInboxRepository(),
          FakeAnalyticsService(),
        ),
      ),
    );
  }

  void useDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'shows a loading indicator while resolving visibility/loading the meta',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      targetRepository.items.add(_target(id: 'target-1', dimensionId: 'rep-1'));

      await pumpApp(tester, buildPage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    },
  );

  testWidgets('a SALES_REP sees their own meta with KPI cards once it loads', (
    tester,
  ) async {
    stubMembership('rep-1', 'SALES_REP');
    targetRepository.items.add(
      _target(id: 'target-1', dimensionId: 'rep-1', targetValue: 100000),
    );
    achievementRepository.seed(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 40000,
        calculatedAt: DateTime.utc(2026, 1, 16),
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppKpiCard, 'Realizado'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Gap para a meta'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Atingimento'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(AppKpiCard, 'Atingimento'),
        matching: find.textContaining('40.0%'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows a persistent visual alert banner when the target is off pace',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      targetRepository.items.add(
        _target(
          id: 'target-1',
          dimensionId: 'rep-1',
          targetValue: 100000,
          startDate: DateTime.utc(2026, 8, 1),
          endDate: DateTime.utc(2026, 10, 1),
        ),
      );
      achievementRepository.seed(
        'target-1',
        TargetAchievementSnapshot(
          targetId: 'target-1',
          realizedValue: 10000,
          calculatedAt: DateTime.utc(2026, 9, 1),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Meta em risco alto'), findsOneWidget);
      expect(find.widgetWithText(AppStatusBadge, 'Risco alto'), findsOneWidget);
    },
  );

  testWidgets(
    'a SALES_REP with no meta cadastrada for the period sees the empty '
    'state, never a forbidden/error one',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma meta cadastrada para este período'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a failure resolving the achievement snapshot shows the error state',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      targetRepository.items.add(_target(id: 'target-1', dimensionId: 'rep-1'));
      achievementRepository.failFor('target-1');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar o atingimento'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a SALES_REP never sees the dimension picker — they can only ever see '
    'their own meta',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      useDesktopViewport(tester);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Dimensão'), findsNothing);
    },
  );

  testWidgets(
    'a SALES_MANAGER trying to view a vendedor outside their team sees the '
    "forbidden state, never that vendedor's data",
    (tester) async {
      stubMembership('manager-1', 'SALES_MANAGER', teamIds: ['team-a']);
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Team>>(<Team>[
          Team(
            id: 'team-a',
            organizationId: 'org-1',
            name: 'Equipe A',
            managerUserId: 'manager-1',
            memberIds: const <String>['rep-1'],
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ]),
      );
      targetRepository.items.add(
        _target(id: 'target-outsider', dimensionId: 'stranger-rep'),
      );
      useDesktopViewport(tester);

      await pumpApp(tester, buildPage(userId: 'manager-1'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Id do vendedor'),
          matching: find.byType(EditableText),
        ),
        'stranger-rep',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver atingimento'));
      await tester.pumpAndSettle();

      expect(find.text('Sem acesso a esta meta'), findsOneWidget);
    },
  );

  testWidgets('the dashboard reflects a fresh achievement snapshot after it is '
      'synced, without needing to reload the page', (tester) async {
    stubMembership('rep-1', 'SALES_REP');
    targetRepository.items.add(
      _target(id: 'target-1', dimensionId: 'rep-1', targetValue: 100000),
    );
    achievementRepository.seed(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 10000,
        calculatedAt: DateTime.utc(2026, 1, 5),
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.widgetWithText(AppKpiCard, 'Atingimento'),
        matching: find.textContaining('10.0%'),
      ),
      findsOneWidget,
    );

    achievementRepository.emit(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 90000,
        calculatedAt: DateTime.utc(2026, 1, 30),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.widgetWithText(AppKpiCard, 'Atingimento'),
        matching: find.textContaining('90.0%'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'the closing projection (TASK-119) is always labeled as an estimate, '
    'distinct from the realizado KPI card',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      final now = DateTime.now().toUtc();
      targetRepository.items.add(
        _target(
          id: 'target-1',
          dimensionId: 'rep-1',
          targetValue: 100000,
          startDate: now.subtract(const Duration(days: 15)),
          endDate: now.add(const Duration(days: 15)),
        ),
      );
      achievementRepository.seed(
        'target-1',
        TargetAchievementSnapshot(
          targetId: 'target-1',
          realizedValue: 40000,
          calculatedAt: now,
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Projeção de fechamento (estimativa)'), findsOneWidget);
      expect(find.textContaining('Estimativa:'), findsOneWidget);
      expect(find.widgetWithText(AppKpiCard, 'Realizado'), findsOneWidget);
      // The estimate is never the same text node as the realized KPI value.
      expect(
        find.descendant(
          of: find.widgetWithText(AppKpiCard, 'Realizado'),
          matching: find.textContaining('Estimativa:'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('a period with fewer than 10% of its days elapsed shows the low-'
      'confidence flag next to the projection', (tester) async {
    stubMembership('rep-1', 'SALES_REP');
    final now = DateTime.now().toUtc();
    targetRepository.items.add(
      _target(
        id: 'target-1',
        dimensionId: 'rep-1',
        targetValue: 100000,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(days: 365)),
      ),
    );
    achievementRepository.seed(
      'target-1',
      TargetAchievementSnapshot(
        targetId: 'target-1',
        realizedValue: 500,
        calculatedAt: now,
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AppStatusBadge, 'Baixa confiabilidade'),
      findsOneWidget,
    );
  });

  testWidgets(
    'an already-ended period shows the projection as the final result, not '
    'a low-confidence estimate',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      final now = DateTime.now().toUtc();
      targetRepository.items.add(
        _target(
          id: 'target-1',
          dimensionId: 'rep-1',
          targetValue: 100000,
          startDate: now.subtract(const Duration(days: 60)),
          endDate: now.subtract(const Duration(days: 30)),
        ),
      );
      achievementRepository.seed(
        'target-1',
        TargetAchievementSnapshot(
          targetId: 'target-1',
          realizedValue: 130000,
          calculatedAt: now.subtract(const Duration(days: 30)),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppStatusBadge, 'Período encerrado'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(AppStatusBadge, 'Baixa confiabilidade'),
        findsNothing,
      );
    },
  );
}

Target _target({
  required String id,
  required String dimensionId,
  double targetValue = 100000,
  TargetDimensionType dimensionType = TargetDimensionType.salesRep,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: dimensionType,
    dimensionId: dimensionId,
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: startDate ?? DateTime.utc(2026, 1, 1),
    endDate: endDate ?? DateTime.utc(2026, 2, 1),
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

/// In-memory fake of [TargetAchievementRepository]: [watchForTarget] emits
/// whatever was last [seed]ed/[emit]ted for a `targetId` immediately upon
/// subscription (mirroring `DriftTargetAchievementRepository`'s own
/// `watchSingleOrNull`-backed "current value first" behavior), then every
/// later [emit] call — exactly the "novo pedido sincronizado" scenario
/// TASK-116's integration test requires.
final class _FakeTargetAchievementRepository
    implements TargetAchievementRepository {
  final Map<String, TargetAchievementSnapshot> _current =
      <String, TargetAchievementSnapshot>{};
  final Map<String, StreamController<TargetAchievementSnapshot>> _controllers =
      <String, StreamController<TargetAchievementSnapshot>>{};
  final Set<String> _failing = <String>{};

  void seed(String targetId, TargetAchievementSnapshot snapshot) {
    _current[targetId] = snapshot;
  }

  void failFor(String targetId) {
    _failing.add(targetId);
  }

  void emit(String targetId, TargetAchievementSnapshot snapshot) {
    _current[targetId] = snapshot;
    _controllerFor(targetId).add(snapshot);
  }

  StreamController<TargetAchievementSnapshot> _controllerFor(String targetId) {
    return _controllers.putIfAbsent(
      targetId,
      () => StreamController<TargetAchievementSnapshot>.broadcast(),
    );
  }

  @override
  Future<AppResult<TargetAchievementSnapshot>> getForTarget({
    required String organizationId,
    required String targetId,
  }) async {
    return AppSuccess<TargetAchievementSnapshot>(
      _current[targetId] ?? TargetAchievementSnapshot(targetId: targetId),
    );
  }

  @override
  Stream<TargetAchievementSnapshot> watchForTarget({
    required String organizationId,
    required String targetId,
  }) async* {
    if (_failing.contains(targetId)) {
      throw Exception('boom');
    }
    yield _current[targetId] ?? TargetAchievementSnapshot(targetId: targetId);
    yield* _controllerFor(targetId).stream;
  }
}

final class _FakeTargetAlertSettingsRepository
    implements TargetAlertSettingsRepository {
  @override
  Future<AppResult<TargetAlertSettings>> getForOrganization({
    required String organizationId,
  }) async => const AppSuccess<TargetAlertSettings>(
    TargetAlertSettings(
      highRiskPaceRatioThreshold: 0.6,
      moderateRiskPaceRatioThreshold: 0.9,
    ),
  );

  @override
  Future<AppResult<TargetAlertSettings>> saveForOrganization({
    required String organizationId,
    required TargetAlertSettings settings,
  }) async => AppSuccess<TargetAlertSettings>(settings);
}

final class _FakeTargetAlertDispatchRepository
    implements TargetAlertDispatchRepository {
  final Map<String, DateTime> _records = <String, DateTime>{};

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
  }) async => AppSuccess<DateTime?>(
    _records['$organizationId::$targetId::${classification.name}'],
  );

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
    required DateTime dispatchedAt,
  }) async {
    _records['$organizationId::$targetId::${classification.name}'] =
        dispatchedAt;
    return AppSuccess<DateTime>(dispatchedAt);
  }
}

final class _FakeNotificationInboxRepository
    implements NotificationInboxRepository {
  @override
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  }) async => AppSuccess<AppNotification>(notification);

  @override
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  }) async => const AppSuccess<List<AppNotification>>(<AppNotification>[]);
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

/// The dashboard resolves "the current period" from `DateTime.now()`
/// (`PositivacaoDashboardCubit.selectDimension`) — computing the exact same
/// window here (instead of hardcoding a date) keeps this test correct
/// regardless of which day it actually runs on.
final PositivacaoPeriod _currentPeriod = PositivacaoPeriod.current(
  granularity: TargetPeriodGranularity.monthly,
  now: DateTime.now(),
);

String _snapshotId(String dimensionId) {
  return 'org-1:salesRep:$dimensionId:'
      '${_currentPeriod.start.toUtc().toIso8601String()}';
}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late TargetVisibilityService visibilityService;
  late _MockTeamRepository teamRepository;
  late _MockOrganizationRepository organizationRepository;
  late _MockCustomerRepository customerRepository;
  late _FakePositivacaoRepository positivacaoRepository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    permissionService = PermissionService(membershipRepository);
    visibilityService = TargetVisibilityService(
      PortfolioVisibilityService(membershipRepository, teamRepository),
      teamRepository,
    );
    organizationRepository = _MockOrganizationRepository();
    customerRepository = _MockCustomerRepository();
    positivacaoRepository = _FakePositivacaoRepository();

    when(
      () => organizationRepository.getById('org-1'),
    ).thenAnswer((_) async => AppSuccess<Organization>(_organization()));
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
    return PositivacaoDashboardPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: userId,
      permissionService: permissionService,
      createCubit: () => PositivacaoDashboardCubit(
        visibilityService,
        GetOrganizationUseCase(organizationRepository),
        positivacaoRepository,
        GetCustomerByIdUseCase(customerRepository),
        FakeAnalyticsService(),
      ),
    );
  }

  void useDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows a loading indicator while resolving visibility', (
    tester,
  ) async {
    stubMembership('rep-1', 'SALES_REP');

    await pumpApp(tester, buildPage());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets(
    'a SALES_REP sees a not-calculated message while no aggregation ran yet',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cálculo da positivação ainda não disponível'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a SALES_REP sees KPI cards and the pending customer list once '
      'calculated', (tester) async {
    stubMembership('rep-1', 'SALES_REP');
    when(
      () =>
          customerRepository.getById(organizationId: 'org-1', id: 'customer-2'),
    ).thenAnswer(
      (_) async => AppSuccess<Customer>(
        _buildCustomer(id: 'customer-2', tradeName: 'Loja Bella Moda'),
      ),
    );
    positivacaoRepository.seed(
      _snapshotId('rep-1'),
      PositivacaoSnapshot(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'rep-1',
        periodStart: _currentPeriod.start,
        periodEnd: _currentPeriod.end,
        totalPortfolio: 4,
        positivatedCount: 3,
        nonPositivatedCustomerIds: const <String>['customer-2'],
        calculatedAt: DateTime.now().toUtc(),
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppKpiCard, 'Carteira total'), findsOneWidget);
    expect(
      find.widgetWithText(AppKpiCard, 'Clientes positivados'),
      findsOneWidget,
    );
    expect(find.textContaining('75.0%'), findsOneWidget);
    expect(find.text('Loja Bella Moda'), findsOneWidget);
  });

  testWidgets(
    'a calculated snapshot with zero customers shows the empty carteira '
    'state, never a forbidden/error one',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');
      positivacaoRepository.seed(
        _snapshotId('rep-1'),
        PositivacaoSnapshot(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionType: PositivacaoDimensionType.salesRep,
          dimensionId: 'rep-1',
          periodStart: _currentPeriod.start,
          periodEnd: _currentPeriod.end,
          totalPortfolio: 0,
          positivatedCount: 0,
          calculatedAt: DateTime.now().toUtc(),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Carteira sem clientes'), findsOneWidget);
    },
  );

  testWidgets('a failure resolving the positivação snapshot shows the error '
      'state', (tester) async {
    stubMembership('rep-1', 'SALES_REP');
    positivacaoRepository.failFor(_snapshotId('rep-1'));

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar a positivação'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a SALES_REP never sees the dimension picker — they can only ever see '
    'their own carteira',
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
    "forbidden state, never that vendedor's positivação",
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
      await tester.tap(find.text('Ver positivação'));
      await tester.pumpAndSettle();

      expect(find.text('Sem acesso a esta carteira'), findsOneWidget);
    },
  );
}

Organization _organization() {
  final now = DateTime.utc(2026, 1, 1);
  return Organization(
    id: 'org-1',
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: const OrganizationSettings(
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
    ),
    status: OrganizationStatus.active,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

Customer _buildCustomer({required String id, required String tradeName}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: tradeName,
    tradeName: tradeName,
    status: CustomerStatus.active,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

/// In-memory fake of [PositivacaoRepository]: [watchForDimension] emits
/// whatever was last [seed]ed for the deterministic snapshot id immediately
/// upon subscription, mirroring `DriftPositivacaoRepository`'s own
/// `watchSingleOrNull`-backed "current value first" behavior, then stays
/// subscribed to a broadcast controller indefinitely — same precedent as
/// `_FakeTargetAchievementRepository` (TASK-116's own page test). Crucially
/// never a one-shot `async*` that completes right after its first `yield`:
/// `PositivacaoDashboardCubit.selectDimension` always `await`s
/// `_snapshotSubscription?.cancel()` before subscribing to a new dimension,
/// and cancelling a subscription to an already-completed stream races with
/// `pumpAndSettle` in a way a real, long-lived Firestore/Drift stream never
/// would — a live controller here keeps this fake honest about that.
final class _FakePositivacaoRepository implements PositivacaoRepository {
  final Map<String, PositivacaoSnapshot> _current =
      <String, PositivacaoSnapshot>{};
  final Map<String, StreamController<PositivacaoSnapshot>> _controllers =
      <String, StreamController<PositivacaoSnapshot>>{};
  final Set<String> _failing = <String>{};

  void seed(String id, PositivacaoSnapshot snapshot) {
    _current[id] = snapshot;
  }

  void failFor(String id) {
    _failing.add(id);
  }

  StreamController<PositivacaoSnapshot> _controllerFor(String id) {
    return _controllers.putIfAbsent(
      id,
      () => StreamController<PositivacaoSnapshot>.broadcast(),
    );
  }

  String _id({
    required String organizationId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
  }) {
    return '$organizationId:${dimensionType.name}:$dimensionId:'
        '${periodStart.toUtc().toIso8601String()}';
  }

  @override
  Future<AppResult<PositivacaoSnapshot>> getForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final id = _id(
      organizationId: organizationId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodStart: periodStart,
    );
    return AppSuccess<PositivacaoSnapshot>(
      _current[id] ??
          PositivacaoSnapshot.notCalculated(
            organizationId: organizationId,
            companyId: companyId,
            dimensionType: dimensionType,
            dimensionId: dimensionId,
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
    );
  }

  @override
  Stream<PositivacaoSnapshot> watchForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async* {
    final id = _id(
      organizationId: organizationId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodStart: periodStart,
    );
    if (_failing.contains(id)) {
      throw Exception('boom');
    }
    yield _current[id] ??
        PositivacaoSnapshot.notCalculated(
          organizationId: organizationId,
          companyId: companyId,
          dimensionType: dimensionType,
          dimensionId: dimensionId,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );
    yield* _controllerFor(id).stream;
  }
}

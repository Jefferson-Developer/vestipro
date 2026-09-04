import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_alert.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_alert_page.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_alert_transition_type.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_scope.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import 'package:vestipro/features/inventory/domain/entities/warehouse.dart';
import 'package:vestipro/features/inventory/domain/repositories/stock_alert_repository.dart';
import 'package:vestipro/features/inventory/domain/repositories/stock_turnover_repository.dart';
import 'package:vestipro/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import 'package:vestipro/features/inventory/domain/usecases/list_stock_alerts_use_case.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_alert_level.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_coverage_status.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_turnover_scope_type.dart';
import 'package:vestipro/features/inventory/domain/value_objects/warehouse_type.dart';
import 'package:vestipro/features/organizations/domain/entities/membership.dart';
import 'package:vestipro/features/organizations/domain/repositories/membership_repository.dart';
import 'package:vestipro/features/organizations/domain/value_objects/membership_status.dart';
import 'package:vestipro/features/organizations/domain/value_objects/system_role_name.dart';

void main() {
  const organizationId = 'org-1';
  const userId = 'user-1';
  const companyId = 'company-1';

  late _FakeStockTurnoverRepository stockTurnoverRepository;
  late _FakeStockAlertRepository stockAlertRepository;
  late LoadInventoryDashboardSnapshotUseCase useCase;

  final filters = InventoryDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  Warehouse buildWarehouse(String id) {
    return Warehouse(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      code: id,
      name: 'Depósito $id',
      type: WarehouseType.headquarters,
      isActive: true,
      priority: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'seed',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'seed',
      version: 1,
      syncStatus: 'synced',
    );
  }

  StockTurnoverMetricSnapshot buildSnapshot({
    required double coverageDays,
    required double sellThroughRate,
    required double turnoverRate,
    required double averageStockQuantity,
    required int soldQuantity,
    StockCoverageStatus coverageStatus = StockCoverageStatus.ready,
  }) {
    return StockTurnoverMetricSnapshot(
      organizationId: organizationId,
      scopeType: StockTurnoverScopeType.warehouse,
      scopeId: 'irrelevant',
      periodStart: filters.periodStart,
      periodEnd: filters.periodEnd,
      coveredDays: 30,
      sellThroughRate: sellThroughRate,
      stockCoverageDays: coverageDays,
      turnoverRate: turnoverRate,
      openingStockQuantity: 100,
      receivedQuantity: 0,
      soldQuantity: soldQuantity,
      closingStockQuantity: 100,
      averageStockQuantity: averageStockQuantity,
      averageDailySalesQuantity: 1,
      coverageStatus: coverageStatus,
      generatedAt: DateTime.utc(2026, 8, 1),
    );
  }

  StockAlert buildAlert(String id, StockAlertLevel level) {
    return StockAlert(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      productId: 'product-$id',
      variantId: 'variant-$id',
      warehouseId: 'wh-1',
      level: level,
      currentLevel: level,
      transitionType: StockAlertTransitionType.entered,
      sellableQuantity: 1,
      thresholdQuantity: 5,
      triggeredAt: DateTime.utc(2026, 8, 1),
      ruleId: 'rule-1',
      notificationEventId: 'notif-$id',
    );
  }

  setUp(() {
    stockTurnoverRepository = _FakeStockTurnoverRepository();
    stockAlertRepository = _FakeStockAlertRepository();
    useCase = LoadInventoryDashboardSnapshotUseCase(
      GetStockTurnoverMetricsUseCase(stockTurnoverRepository),
      ListStockAlertsUseCase(
        stockAlertRepository,
        PermissionService(
          _FakeMembershipRepository(
            Membership(
              id: userId,
              organizationId: organizationId,
              userId: userId,
              roleId: 'role-admin',
              roleName: SystemRoleName.admin.code,
              status: MembershipStatus.active,
              version: 1,
              createdAt: DateTime.utc(2026, 1, 1),
              createdBy: 'seed',
              updatedAt: DateTime.utc(2026, 1, 1),
              updatedBy: 'seed',
            ),
          ),
        ),
      ),
    );
  });

  test('retorna falha de validação para organizationId em branco', () async {
    final result = await useCase(
      organizationId: '',
      requestedByUserId: userId,
      filters: filters,
      activeWarehouses: const <Warehouse>[],
    );
    expect(result, isA<AppFailure<InventoryDashboardSnapshot>>());
  });

  test(
    'lê o escopo de um único depósito quando warehouseId é informado',
    () async {
      stockTurnoverRepository.snapshotByScopeId['wh-1'] = buildSnapshot(
        coverageDays: 45,
        sellThroughRate: 0.6,
        turnoverRate: 1.2,
        averageStockQuantity: 100,
        soldQuantity: 50,
      );

      final result = await useCase(
        organizationId: organizationId,
        requestedByUserId: userId,
        filters: filters.copyWith(warehouseId: 'wh-1'),
        activeWarehouses: <Warehouse>[buildWarehouse('wh-1')],
      );

      final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
      expect(snapshot.coverageDays.value, 45);
      expect(snapshot.sellThroughRate.value, 60);
      expect(snapshot.turnoverRate.value, 1.2);
      expect(snapshot.warehousesConsidered, 1);
    },
  );

  test('lê o escopo de uma coleção quando collectionId é informado, mesmo com '
      'warehouseId ausente', () async {
    stockTurnoverRepository.snapshotByScopeId['col-1'] = buildSnapshot(
      coverageDays: 20,
      sellThroughRate: 0.9,
      turnoverRate: 2.5,
      averageStockQuantity: 80,
      soldQuantity: 200,
    );

    final result = await useCase(
      organizationId: organizationId,
      requestedByUserId: userId,
      filters: filters.copyWith(collectionId: 'col-1'),
      activeWarehouses: const <Warehouse>[],
    );

    final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
    expect(snapshot.coverageDays.value, 20);
    expect(snapshot.warehousesConsidered, 0);
  });

  test(
    'prioriza warehouseId sobre collectionId quando ambos são informados',
    () async {
      stockTurnoverRepository.snapshotByScopeId['wh-1'] = buildSnapshot(
        coverageDays: 10,
        sellThroughRate: 0.5,
        turnoverRate: 1,
        averageStockQuantity: 50,
        soldQuantity: 10,
      );
      stockTurnoverRepository.snapshotByScopeId['col-1'] = buildSnapshot(
        coverageDays: 999,
        sellThroughRate: 0.99,
        turnoverRate: 9,
        averageStockQuantity: 999,
        soldQuantity: 999,
      );

      final result = await useCase(
        organizationId: organizationId,
        requestedByUserId: userId,
        filters: filters.copyWith(warehouseId: 'wh-1', collectionId: 'col-1'),
        activeWarehouses: <Warehouse>[buildWarehouse('wh-1')],
      );

      final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
      expect(snapshot.coverageDays.value, 10);
    },
  );

  test('sem depósito/coleção selecionado, agrega por média ponderada sobre '
      'todo depósito ativo', () async {
    // Depósito A: peso de estoque 100, peso de vendas 10.
    stockTurnoverRepository.snapshotByScopeId['wh-a'] = buildSnapshot(
      coverageDays: 10,
      sellThroughRate: 0.2,
      turnoverRate: 1,
      averageStockQuantity: 100,
      soldQuantity: 10,
    );
    // Depósito B: peso de estoque 300, peso de vendas 90 — deve puxar a
    // média ponderada muito mais para os seus próprios valores do que
    // uma média aritmética simples faria.
    stockTurnoverRepository.snapshotByScopeId['wh-b'] = buildSnapshot(
      coverageDays: 50,
      sellThroughRate: 0.8,
      turnoverRate: 3,
      averageStockQuantity: 300,
      soldQuantity: 90,
    );

    final result = await useCase(
      organizationId: organizationId,
      requestedByUserId: userId,
      filters: filters,
      activeWarehouses: <Warehouse>[
        buildWarehouse('wh-a'),
        buildWarehouse('wh-b'),
      ],
    );

    final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
    // coverageDays ponderado por averageStockQuantity: (10*100 + 50*300) /
    // 400 = 40.
    expect(snapshot.coverageDays.value, closeTo(40, 0.001));
    // turnoverRate/sellThrough ponderados por soldQuantity (10 + 90 = 100):
    // turnoverRate = (1*10 + 3*90) / 100 = 2.8.
    expect(snapshot.turnoverRate.value, closeTo(2.8, 0.001));
    // sellThroughRate = (0.2*10 + 0.8*90) / 100 = 0.74 -> 74%.
    expect(snapshot.sellThroughRate.value, closeTo(74, 0.001));
    expect(snapshot.warehousesConsidered, 2);
  });

  test('sem depósito ativo algum, KPIs ficam notCalculated (nunca zero '
      'fabricado)', () async {
    final result = await useCase(
      organizationId: organizationId,
      requestedByUserId: userId,
      filters: filters,
      activeWarehouses: const <Warehouse>[],
    );

    final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
    expect(
      snapshot.coverageDays.status,
      ExecutiveDashboardMetricStatus.notCalculated,
    );
    expect(snapshot.warehousesConsidered, 0);
  });

  test('propaga falha de leitura de alertas', () async {
    stockAlertRepository.failing = true;

    final result = await useCase(
      organizationId: organizationId,
      requestedByUserId: userId,
      filters: filters.copyWith(warehouseId: 'wh-1'),
      activeWarehouses: <Warehouse>[buildWarehouse('wh-1')],
    );

    expect(result, isA<AppFailure<InventoryDashboardSnapshot>>());
  });

  test(
    'consolida alertas ativos sem duplicar/reprocessar (TASK-093)',
    () async {
      stockAlertRepository.page = StockAlertPage(
        alerts: <StockAlert>[
          buildAlert('alert-1', StockAlertLevel.critical),
          buildAlert('alert-2', StockAlertLevel.low),
        ],
        hasMore: true,
      );

      final result = await useCase(
        organizationId: organizationId,
        requestedByUserId: userId,
        filters: filters.copyWith(warehouseId: 'wh-1'),
        activeWarehouses: <Warehouse>[buildWarehouse('wh-1')],
      );

      final snapshot = (result as AppSuccess<InventoryDashboardSnapshot>).value;
      expect(snapshot.activeAlertCount, 2);
      expect(snapshot.criticalAlertCount, 1);
      expect(snapshot.alertsHasMore, isTrue);
    },
  );
}

final class _FakeStockTurnoverRepository implements StockTurnoverRepository {
  final Map<String, StockTurnoverMetricSnapshot> snapshotByScopeId =
      <String, StockTurnoverMetricSnapshot>{};

  @override
  Future<AppResult<StockTurnoverMetricSnapshot?>> getByScopeAndPeriod({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    return AppSuccess<StockTurnoverMetricSnapshot?>(
      snapshotByScopeId[scope.id],
    );
  }
}

final class _FakeStockAlertRepository implements StockAlertRepository {
  StockAlertPage page = const StockAlertPage(
    alerts: <StockAlert>[],
    hasMore: false,
  );
  bool failing = false;

  @override
  Future<AppResult<StockAlertPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
  }) async {
    if (failing) {
      return const AppFailure<StockAlertPage>(
        ServerFailure('boom', code: 'boom'),
      );
    }
    return AppSuccess<StockAlertPage>(page);
  }
}

final class _FakeMembershipRepository implements MembershipRepository {
  const _FakeMembershipRepository(this.membership);

  final Membership membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    return AppSuccess<Membership>(membership);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) => throw UnimplementedError();

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    String? roleId,
    String? roleName,
    List<String>? teamIds,
    MembershipStatus? status,
    required String updatedBy,
  }) => throw UnimplementedError();
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/inventory.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _InMemoryStockAlertRepository repository;

  Membership membership(String roleName) {
    return Membership(
      id: 'current-user',
      organizationId: 'org-1',
      userId: 'current-user',
      roleId: roleName,
      roleName: roleName,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime(2026, 8, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime(2026, 8, 1),
      updatedBy: 'owner-1',
    );
  }

  Widget buildPage() {
    return StockAlertsPage(
      organizationId: 'org-1',
      userId: 'current-user',
      permissionService: permissionService,
      createBloc: () => StockAlertListBloc(
        listStockAlerts: ListStockAlertsUseCase(repository, permissionService),
      ),
    );
  }

  void setWidth(WidgetTester tester, double width) {
    final view = tester.view;
    view.physicalSize = Size(width, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  StockAlert alert({
    required String id,
    String productId = 'product-1',
    String variantId = 'variant-1',
    String warehouseId = 'warehouse-1',
    StockAlertLevel level = StockAlertLevel.low,
    StockAlertTransitionType transitionType = StockAlertTransitionType.entered,
    DateTime? triggeredAt,
  }) {
    return StockAlert(
      id: id,
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: productId,
      variantId: variantId,
      warehouseId: warehouseId,
      level: level,
      previousLevel: transitionType == StockAlertTransitionType.entered
          ? null
          : StockAlertLevel.low,
      currentLevel: transitionType == StockAlertTransitionType.recovered
          ? null
          : level,
      transitionType: transitionType,
      sellableQuantity: 3,
      thresholdQuantity: 5,
      triggeredAt: triggeredAt ?? DateTime(2026, 8, 28, 10),
      ruleId: 'rule-1',
      notificationEventId: 'event-1',
    );
  }

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _InMemoryStockAlertRepository(<StockAlert>[
      alert(id: 'alert-1'),
    ]);
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'current-user',
      ),
    ).thenAnswer((_) async => AppSuccess<Membership>(membership('OWNER')));
  });

  group('StockAlertsPage', () {
    testWidgets('renders the stock alert table on desktop', (tester) async {
      setWidth(tester, 1300);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Alertas de ruptura'), findsOneWidget);
      expect(find.text('Severidade'), findsWidgets);
      expect(find.text('Produto'), findsWidgets);
      expect(find.text('Variante'), findsOneWidget);
      expect(find.text('Unidade'), findsWidgets);
      expect(find.text('Baixo'), findsOneWidget);
      expect(find.byKey(const ValueKey<Object>('alert-1')), findsOneWidget);
    });

    testWidgets('filters by severity, product and unit', (tester) async {
      setWidth(tester, 1300);
      repository = _InMemoryStockAlertRepository(<StockAlert>[
        alert(
          id: 'critical-target',
          productId: 'product-target',
          warehouseId: 'warehouse-target',
          level: StockAlertLevel.critical,
        ),
        alert(id: 'other-product', productId: 'other-product'),
        alert(
          id: 'other-level',
          productId: 'product-target',
          warehouseId: 'warehouse-target',
          level: StockAlertLevel.low,
        ),
      ]);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crítico'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('stock_alert_product_filter')),
          matching: find.byType(EditableText),
        ),
        'product-target',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('stock_alert_warehouse_filter')),
          matching: find.byType(EditableText),
        ),
        'warehouse-target',
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<Object>('critical-target')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<Object>('other-product')), findsNothing);
      expect(find.byKey(const ValueKey<Object>('other-level')), findsNothing);

      final request = repository.requests.last;
      expect(request.level, StockAlertLevel.critical);
      expect(request.productId, 'product-target');
      expect(request.warehouseId, 'warehouse-target');
    });

    testWidgets('shows the empty state', (tester) async {
      setWidth(tester, 1300);
      repository = _InMemoryStockAlertRepository(const <StockAlert>[]);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhum alerta de ruptura encontrado'), findsOneWidget);
    });

    testWidgets('hides the page for roles without stock alert access', (
      tester,
    ) async {
      setWidth(tester, 1300);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(membership('SALES_REP')),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Você não tem permissão para acessar esta página.'),
        findsOneWidget,
      );
      expect(find.text('Alertas de ruptura'), findsNothing);
      expect(repository.requests, isEmpty);
    });
  });
}

final class _StockAlertListRequest {
  const _StockAlertListRequest({
    required this.organizationId,
    required this.limit,
    this.before,
    this.level,
    this.productId,
    this.warehouseId,
  });

  final String organizationId;
  final int limit;
  final DateTime? before;
  final StockAlertLevel? level;
  final String? productId;
  final String? warehouseId;
}

final class _InMemoryStockAlertRepository implements StockAlertRepository {
  _InMemoryStockAlertRepository(List<StockAlert> alerts)
    : _alerts = [...alerts]
        ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));

  final List<StockAlert> _alerts;
  final List<_StockAlertListRequest> requests = <_StockAlertListRequest>[];

  @override
  Future<AppResult<StockAlertPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
  }) async {
    requests.add(
      _StockAlertListRequest(
        organizationId: organizationId,
        limit: limit,
        before: before,
        level: level,
        productId: productId,
        warehouseId: warehouseId,
      ),
    );

    final filtered = _alerts
        .where((alert) {
          final matchesOrganization = alert.organizationId == organizationId;
          final matchesLevel = level == null || alert.level == level;
          final matchesProduct =
              productId == null ||
              productId.isEmpty ||
              alert.productId == productId;
          final matchesWarehouse =
              warehouseId == null ||
              warehouseId.isEmpty ||
              alert.warehouseId == warehouseId;
          final matchesBefore =
              before == null || alert.triggeredAt.isBefore(before);
          return matchesOrganization &&
              matchesLevel &&
              matchesProduct &&
              matchesWarehouse &&
              matchesBefore;
        })
        .toList(growable: false);

    final pageAlerts = filtered.take(limit).toList(growable: false);
    return AppSuccess<StockAlertPage>(
      StockAlertPage(
        alerts: pageAlerts,
        hasMore: filtered.length > limit,
        nextCursor: filtered.length > limit && pageAlerts.isNotEmpty
            ? pageAlerts.last.triggeredAt
            : null,
      ),
    );
  }
}

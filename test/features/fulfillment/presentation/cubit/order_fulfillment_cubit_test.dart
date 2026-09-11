import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';

final class _FakeFulfillmentRepository implements FulfillmentRepository {
  final _shipmentsController =
      StreamController<AppResult<List<Shipment>>>.broadcast();
  final _trackingEventsController =
      StreamController<AppResult<List<TrackingEvent>>>.broadcast();
  final _logisticsIssuesController =
      StreamController<AppResult<List<LogisticsIssue>>>.broadcast();

  final List<String> registeredShipmentIds = [];
  final List<String> resolvedIssueIds = [];
  AppResult<void> registerResult = const AppSuccess<void>(null);
  AppResult<void> resolveResult = const AppSuccess<void>(null);

  @override
  Stream<AppResult<List<Shipment>>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  }) => _shipmentsController.stream;

  @override
  Stream<AppResult<List<TrackingEvent>>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  }) => _trackingEventsController.stream;

  @override
  Stream<AppResult<List<LogisticsIssue>>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  }) => _logisticsIssuesController.stream;

  @override
  Future<AppResult<void>> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) async {
    registeredShipmentIds.add(shipmentId);
    return registerResult;
  }

  @override
  Future<AppResult<void>> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required bool resolved,
    String? resolutionNote,
  }) async {
    resolvedIssueIds.add(logisticsIssueId);
    return resolveResult;
  }

  Future<void> dispose() async {
    await _shipmentsController.close();
    await _trackingEventsController.close();
    await _logisticsIssuesController.close();
  }
}

Shipment _buildShipment(String id) => Shipment(
  id: id,
  organizationId: 'org-1',
  companyId: 'company-1',
  orderId: 'order-1',
  customerId: 'customer-1',
  sellerId: 'seller-1',
  status: ShipmentStatus.shipped,
  hasOpenIssue: false,
  packages: const <ShipmentPackage>[
    ShipmentPackage(
      packageNumber: 1,
      items: <ShipmentPackageItem>[
        ShipmentPackageItem(
          orderItemId: 'item-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 10,
        ),
      ],
    ),
  ],
  deliveredQuantities: const <String, int>{},
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late _FakeFulfillmentRepository repository;
  late FakeAnalyticsService analyticsService;
  late OrderFulfillmentCubit cubit;

  setUp(() {
    repository = _FakeFulfillmentRepository();
    analyticsService = FakeAnalyticsService();
    cubit = OrderFulfillmentCubit(
      WatchShipmentsForOrderUseCase(repository),
      WatchTrackingEventsUseCase(repository),
      WatchLogisticsIssuesUseCase(repository),
      RegisterLogisticsIssueUseCase(repository),
      ResolveLogisticsIssueUseCase(repository),
      analyticsService,
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test(
    'emits ready with an empty shipment list when the order has none',
    () async {
      await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
      repository._shipmentsController.add(const AppSuccess<List<Shipment>>([]));
      await pumpEventQueue();

      expect(cubit.state.status, OrderFulfillmentStatus.ready);
      expect(cubit.state.selectedShipment, isNull);
    },
  );

  test(
    'selects the most recently created shipment and watches its detail',
    () async {
      await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
      final shipments = [
        _buildShipment('shipment-1'),
        _buildShipment('shipment-2'),
      ];
      repository._shipmentsController.add(
        AppSuccess<List<Shipment>>(shipments),
      );
      await pumpEventQueue();

      expect(cubit.state.selectedShipment?.id, 'shipment-2');
      expect(cubit.state.hasEarlierShipments, isTrue);
    },
  );

  test('emits failure when the shipments stream fails', () async {
    await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
    repository._shipmentsController.add(
      AppFailure<List<Shipment>>(
        UnexpectedFailure('boom', code: 'test_failure'),
      ),
    );
    await pumpEventQueue();

    expect(cubit.state.status, OrderFulfillmentStatus.failure);
    expect(cubit.state.failureMessage, 'boom');
  });

  test('reportIssue is a no-op without a selected shipment', () async {
    await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
    repository._shipmentsController.add(const AppSuccess<List<Shipment>>([]));
    await pumpEventQueue();

    await cubit.reportIssue(
      companyId: 'company-1',
      type: LogisticsIssueType.delay,
      description: 'atraso',
      responsibleUserId: 'seller-1',
      nextAction: 'ligar para o cliente',
    );

    expect(repository.registeredShipmentIds, isEmpty);
  });

  test(
    'reportIssue calls the repository and logs analytics on success',
    () async {
      await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
      repository._shipmentsController.add(
        AppSuccess<List<Shipment>>([_buildShipment('shipment-1')]),
      );
      await pumpEventQueue();

      await cubit.reportIssue(
        companyId: 'company-1',
        type: LogisticsIssueType.damage,
        description: 'volume avariado',
        responsibleUserId: 'seller-1',
        nextAction: 'abrir chamado com a transportadora',
      );

      expect(repository.registeredShipmentIds, ['shipment-1']);
      expect(cubit.state.isSubmittingIssue, isFalse);
      expect(cubit.state.lastRegisteredIssueId, isNotNull);
      expect(
        analyticsService.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.logisticsIssueRegistered),
      );
    },
  );

  test(
    'reportIssue surfaces a failure message without logging analytics',
    () async {
      repository.registerResult = const AppFailure<void>(
        UnexpectedFailure('falhou', code: 'test_failure'),
      );
      await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
      repository._shipmentsController.add(
        AppSuccess<List<Shipment>>([_buildShipment('shipment-1')]),
      );
      await pumpEventQueue();

      await cubit.reportIssue(
        companyId: 'company-1',
        type: LogisticsIssueType.delay,
        description: 'atraso',
        responsibleUserId: 'seller-1',
        nextAction: 'ligar para o cliente',
      );

      expect(cubit.state.issueFailureMessage, 'falhou');
      expect(analyticsService.loggedEvents, isEmpty);
    },
  );

  test(
    'resolveIssue calls the repository and logs analytics on success',
    () async {
      await cubit.watch(organizationId: 'org-1', orderId: 'order-1');
      repository._shipmentsController.add(
        AppSuccess<List<Shipment>>([_buildShipment('shipment-1')]),
      );
      await pumpEventQueue();

      await cubit.resolveIssue(
        logisticsIssueId: 'issue-1',
        type: LogisticsIssueType.delay,
        resolutionNote: 'entregue com atraso, cliente avisado',
      );

      expect(repository.resolvedIssueIds, ['issue-1']);
      expect(cubit.state.lastResolvedIssueId, 'issue-1');
      expect(
        analyticsService.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.logisticsIssueResolved),
      );
    },
  );
}

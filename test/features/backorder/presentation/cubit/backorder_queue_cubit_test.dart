import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/backorder/backorder.dart';

final class _FakeBackorderRepository implements BackorderRepository {
  final _queueController =
      StreamController<AppResult<List<BackorderRequest>>>.broadcast();
  final _awaitingApprovalController =
      StreamController<AppResult<List<BackorderRequest>>>.broadcast();

  final List<String> decidedIds = [];
  final List<String> cancelledIds = [];
  final List<String> convertedIds = [];
  AppResult<void> decideResult = const AppSuccess<void>(null);
  AppResult<void> cancelResult = const AppSuccess<void>(null);
  AppResult<void> convertResult = const AppSuccess<void>(null);

  @override
  Stream<AppResult<List<BackorderRequest>>> watchQueue({
    required String organizationId,
  }) => _queueController.stream;

  @override
  Stream<AppResult<List<BackorderRequest>>> watchAwaitingApproval({
    required String organizationId,
  }) => _awaitingApprovalController.stream;

  @override
  Stream<AppResult<List<BackorderRequest>>> watchForCustomer({
    required String organizationId,
    required String customerId,
  }) => const Stream<AppResult<List<BackorderRequest>>>.empty();

  @override
  Future<AppResult<void>> createBackorderRequest({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required BackorderOrigin origin,
    BackorderPriority priority = BackorderPriority.normal,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    DateTime? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  }) async {
    decidedIds.add(backorderId);
    return decideResult;
  }

  @override
  Future<AppResult<void>> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  }) async {
    cancelledIds.add(backorderId);
    return cancelResult;
  }

  @override
  Future<AppResult<void>> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  }) async {
    convertedIds.add(backorderId);
    return convertResult;
  }

  Future<void> dispose() async {
    await _queueController.close();
    await _awaitingApprovalController.close();
  }
}

BackorderRequest _build({
  String id = 'backorder-1',
  BackorderStatus status = BackorderStatus.queued,
}) {
  return BackorderRequest(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    productId: 'product-1',
    variantId: 'variant-1',
    quantity: 10,
    fulfilledQuantity: 0,
    quantityAtRequest: 2,
    origin: BackorderOrigin.catalog,
    priority: BackorderPriority.normal,
    sellerId: 'seller-1',
    status: status,
    requestedBy: 'seller-1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  late _FakeBackorderRepository repository;
  late FakeAnalyticsService analyticsService;
  late BackorderQueueCubit cubit;

  setUp(() {
    repository = _FakeBackorderRepository();
    analyticsService = FakeAnalyticsService();
    cubit = BackorderQueueCubit(
      WatchBackorderQueueUseCase(repository),
      WatchBackordersAwaitingApprovalUseCase(repository),
      DecideBackorderApprovalUseCase(repository),
      CancelBackorderRequestUseCase(repository),
      ConvertBackorderToOrderUseCase(repository),
      analyticsService,
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('emits ready with the queue once the stream resolves', () async {
    await cubit.watch(organizationId: 'org-1');
    repository._queueController.add(
      AppSuccess<List<BackorderRequest>>([_build()]),
    );
    await pumpEventQueue();

    expect(cubit.state.status, BackorderQueueStatus.ready);
    expect(cubit.state.queue, hasLength(1));
  });

  test('emits failure when the queue stream fails', () async {
    await cubit.watch(organizationId: 'org-1');
    repository._queueController.add(
      AppFailure<List<BackorderRequest>>(
        UnexpectedFailure('boom', code: 'test_failure'),
      ),
    );
    await pumpEventQueue();

    expect(cubit.state.status, BackorderQueueStatus.failure);
    expect(cubit.state.failureMessage, 'boom');
  });

  test(
    'keeps the queue status independent from the awaitingApproval stream',
    () async {
      await cubit.watch(organizationId: 'org-1');
      repository._queueController.add(
        const AppSuccess<List<BackorderRequest>>([]),
      );
      repository._awaitingApprovalController.add(
        AppSuccess<List<BackorderRequest>>([
          _build(id: 'backorder-2', status: BackorderStatus.awaitingApproval),
        ]),
      );
      await pumpEventQueue();

      expect(cubit.state.status, BackorderQueueStatus.ready);
      expect(cubit.state.awaitingApproval, hasLength(1));
      expect(cubit.state.queue, isEmpty);
    },
  );

  test(
    'decide(approve: true) calls the repository and logs analytics',
    () async {
      await cubit.watch(organizationId: 'org-1');
      await cubit.decide(backorderId: 'backorder-1', approve: true);

      expect(repository.decidedIds, ['backorder-1']);
      expect(cubit.state.processingBackorderId, isNull);
      expect(cubit.state.lastActionBackorderId, 'backorder-1');
      expect(
        analyticsService.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.backorderApproved),
      );
    },
  );

  test('decide(approve: false) logs the rejected event', () async {
    await cubit.watch(organizationId: 'org-1');
    await cubit.decide(backorderId: 'backorder-1', approve: false);

    expect(
      analyticsService.loggedEvents.map((event) => event.name),
      contains(AnalyticsEvents.backorderRejected),
    );
  });

  test('decide surfaces a failure message without logging analytics', () async {
    repository.decideResult = const AppFailure<void>(
      UnexpectedFailure('falhou', code: 'test_failure'),
    );
    await cubit.watch(organizationId: 'org-1');
    await cubit.decide(backorderId: 'backorder-1', approve: true);

    expect(cubit.state.actionFailureMessage, 'falhou');
    expect(analyticsService.loggedEvents, isEmpty);
  });

  test('cancel calls the repository and logs analytics on success', () async {
    await cubit.watch(organizationId: 'org-1');
    await cubit.cancel(backorderId: 'backorder-1', reason: 'cliente desistiu');

    expect(repository.cancelledIds, ['backorder-1']);
    expect(
      analyticsService.loggedEvents.map((event) => event.name),
      contains(AnalyticsEvents.backorderCancelled),
    );
  });

  test(
    'convert calls the repository and logs analytics with the order id',
    () async {
      await cubit.watch(organizationId: 'org-1');
      await cubit.convert(backorderId: 'backorder-1', orderId: 'order-9');

      expect(repository.convertedIds, ['backorder-1']);
      final logged = analyticsService.loggedEvents.singleWhere(
        (event) => event.name == AnalyticsEvents.backorderConverted,
      );
      expect(logged.parameters?['order_id'], 'order-9');
    },
  );
}

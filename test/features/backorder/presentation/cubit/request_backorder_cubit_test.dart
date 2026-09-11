import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/backorder/backorder.dart';

final class _FakeBackorderRepository implements BackorderRepository {
  final List<Map<String, Object?>> createdRequests = [];
  AppResult<void> createResult = const AppSuccess<void>(null);

  @override
  Stream<AppResult<List<BackorderRequest>>> watchQueue({
    required String organizationId,
  }) => const Stream<AppResult<List<BackorderRequest>>>.empty();

  @override
  Stream<AppResult<List<BackorderRequest>>> watchAwaitingApproval({
    required String organizationId,
  }) => const Stream<AppResult<List<BackorderRequest>>>.empty();

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
  }) async {
    createdRequests.add(<String, Object?>{
      'quantity': quantity,
      'origin': origin,
      'priority': priority,
    });
    return createResult;
  }

  @override
  Future<AppResult<void>> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  }) async => const AppSuccess<void>(null);
}

void main() {
  late _FakeBackorderRepository repository;
  late FakeAnalyticsService analyticsService;
  late RequestBackorderCubit cubit;

  setUp(() {
    repository = _FakeBackorderRepository();
    analyticsService = FakeAnalyticsService();
    cubit = RequestBackorderCubit(
      CreateBackorderRequestUseCase(repository),
      analyticsService,
    );
  });

  test(
    'submit calls the repository and emits success with a backorderId',
    () async {
      await cubit.submit(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        productId: 'product-1',
        variantId: 'variant-1',
        quantity: 5,
        origin: BackorderOrigin.catalog,
      );

      expect(repository.createdRequests, hasLength(1));
      expect(repository.createdRequests.single['quantity'], 5);
      expect(cubit.state.status, RequestBackorderStatus.success);
      expect(cubit.state.lastBackorderId, isNotNull);
      expect(
        analyticsService.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.backorderRequested),
      );
    },
  );

  test('submit surfaces a failure message without logging analytics', () async {
    repository.createResult = const AppFailure<void>(
      UnexpectedFailure('falhou', code: 'test_failure'),
    );

    await cubit.submit(
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      productId: 'product-1',
      variantId: 'variant-1',
      quantity: 5,
      origin: BackorderOrigin.catalog,
    );

    expect(cubit.state.status, RequestBackorderStatus.failure);
    expect(cubit.state.failureMessage, 'falhou');
    expect(analyticsService.loggedEvents, isEmpty);
  });

  test('defaults priority to normal when not provided', () async {
    await cubit.submit(
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      productId: 'product-1',
      variantId: 'variant-1',
      quantity: 3,
      origin: BackorderOrigin.order,
    );

    expect(
      repository.createdRequests.single['priority'],
      BackorderPriority.normal,
    );
  });
}

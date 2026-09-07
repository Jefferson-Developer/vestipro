import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('CaptureOrderSignatureUseCase', () {
    test(
      'captures and persists a signature for a submitted order, stamping the '
      'exact content hash of that order',
      () async {
        final repository = _FakeOrderSignatureDraftRepository();
        final analytics = FakeAnalyticsService();
        final useCase = CaptureOrderSignatureUseCase(
          repository,
          const OrderContentHasher(),
          analytics,
        );
        final order = _order();

        final result = await useCase(
          id: 'signature-1',
          order: order,
          signerRole: OrderSignerRole.customer,
          signedByUserId: 'seller-1',
          signedByName: '  Maria Cliente  ',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
          now: DateTime.utc(2026, 6, 2),
        );

        expect(result, isA<AppSuccess<OrderSignature>>());
        final signature = (result as AppSuccess<OrderSignature>).value;
        expect(signature.orderId, order.id);
        expect(signature.signedByName, 'Maria Cliente');
        expect(signature.contentHash, const OrderContentHasher().hash(order));
        expect(signature.orderVersionAtSignature, order.version);
        expect(signature.syncStatus, OrderSignatureSyncStatus.pendingSync);
        expect(repository.saved.single.id, 'signature-1');
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.orderSignatureCaptured,
          ),
          isTrue,
        );
      },
    );

    test('rejects signing a draft order (not yet submitted)', () async {
      final repository = _FakeOrderSignatureDraftRepository();
      final useCase = CaptureOrderSignatureUseCase(
        repository,
        const OrderContentHasher(),
        FakeAnalyticsService(),
      );

      final result = await useCase(
        id: 'signature-1',
        order: _order(status: OrderStatus.draft),
        signerRole: OrderSignerRole.customer,
        signedByUserId: 'seller-1',
        signedByName: 'Maria Cliente',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(result, isA<AppFailure<OrderSignature>>());
      expect(
        (result as AppFailure<OrderSignature>).failure.code,
        'order_signature_not_signable_status',
      );
      expect(repository.saved, isEmpty);
    });

    test('rejects signing an order that already carries a valid signature — '
        '"assinatura nunca pode ser removida ou substituída"', () async {
      final order = _order();
      final repository = _FakeOrderSignatureDraftRepository(
        existing: _signature(order),
      );
      final useCase = CaptureOrderSignatureUseCase(
        repository,
        const OrderContentHasher(),
        FakeAnalyticsService(),
      );

      final result = await useCase(
        id: 'signature-2',
        order: order,
        signerRole: OrderSignerRole.seller,
        signedByUserId: 'seller-1',
        signedByName: 'Outro Nome',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(result, isA<AppFailure<OrderSignature>>());
      expect(
        (result as AppFailure<OrderSignature>).failure.code,
        'order_signature_already_signed',
      );
      expect(repository.saved, isEmpty);
    });

    test(
      'allows re-signing once the existing signature was invalidated',
      () async {
        final order = _order();
        final invalidated = _signature(
          order,
        ).copyWith(status: OrderSignatureStatus.invalidated);
        final repository = _FakeOrderSignatureDraftRepository(
          existing: invalidated,
        );
        final useCase = CaptureOrderSignatureUseCase(
          repository,
          const OrderContentHasher(),
          FakeAnalyticsService(),
        );

        final result = await useCase(
          id: 'signature-2',
          order: order,
          signerRole: OrderSignerRole.seller,
          signedByUserId: 'seller-1',
          signedByName: 'Outro Nome',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

        expect(result, isA<AppSuccess<OrderSignature>>());
        expect(repository.saved.single.id, 'signature-2');
      },
    );

    test('rejects an empty signature image', () async {
      final repository = _FakeOrderSignatureDraftRepository();
      final useCase = CaptureOrderSignatureUseCase(
        repository,
        const OrderContentHasher(),
        FakeAnalyticsService(),
      );

      final result = await useCase(
        id: 'signature-1',
        order: _order(),
        signerRole: OrderSignerRole.customer,
        signedByUserId: 'seller-1',
        signedByName: 'Maria Cliente',
        imageBytes: Uint8List(0),
      );

      expect(result, isA<AppFailure<OrderSignature>>());
      expect(repository.saved, isEmpty);
    });

    test('rejects a blank signedByName', () async {
      final repository = _FakeOrderSignatureDraftRepository();
      final useCase = CaptureOrderSignatureUseCase(
        repository,
        const OrderContentHasher(),
        FakeAnalyticsService(),
      );

      final result = await useCase(
        id: 'signature-1',
        order: _order(),
        signerRole: OrderSignerRole.customer,
        signedByUserId: 'seller-1',
        signedByName: '   ',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(result, isA<AppFailure<OrderSignature>>());
      expect(repository.saved, isEmpty);
    });
  });
}

Order _order({OrderStatus status = OrderStatus.submitted}) {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
    orderNumber: '000001',
    deliveryAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items: const <OrderItem>[
      OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
      ),
    ],
    status: status,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.synced,
  );
}

OrderSignature _signature(Order order) {
  final now = DateTime.utc(2026, 6, 1, 12);
  return OrderSignature(
    id: 'signature-existing',
    organizationId: order.organizationId,
    companyId: order.companyId,
    orderId: order.id,
    signerRole: OrderSignerRole.customer,
    signedByUserId: 'seller-1',
    signedByName: 'Maria Cliente',
    method: OrderSignatureMethod.canvasDrawn,
    imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
    contentHash: const OrderContentHasher().hash(order),
    orderVersionAtSignature: order.version,
    signedAt: now,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSignatureSyncStatus.synced,
  );
}

final class _FakeOrderSignatureDraftRepository
    implements OrderSignatureDraftRepository {
  _FakeOrderSignatureDraftRepository({this.existing});

  final OrderSignature? existing;
  final List<OrderSignature> saved = <OrderSignature>[];

  @override
  Future<AppResult<void>> saveLocal({required OrderSignature signature}) async {
    saved.add(signature);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<OrderSignature?>> getByOrderId({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) async {
    return AppSuccess<OrderSignature?>(existing);
  }

  @override
  Future<AppResult<List<OrderSignature>>> getPendingSync({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<OrderSignature>>(<OrderSignature>[]);
  }
}

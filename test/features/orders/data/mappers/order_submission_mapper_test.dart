import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderSubmissionMapper', () {
    test(
      'toEntity copies every field as-is and resolves status through OrderMapper',
      () {
        final mapper = OrderSubmissionMapper(const OrderMapper());
        final dto = OrderSubmissionResultDto(
          orderId: 'order-1',
          orderNumber: '000042',
          status: 'submitted',
          discountAmount: 10,
          surchargeAmount: 2,
          shippingAmount: 15,
          total: 207,
          submittedAt: DateTime.utc(2026, 6, 1, 12),
        );

        final entity = mapper.toEntity(dto);

        expect(entity.orderId, 'order-1');
        expect(entity.orderNumber, '000042');
        expect(entity.status, OrderStatus.submitted);
        expect(entity.discountAmount, 10);
        expect(entity.surchargeAmount, 2);
        expect(entity.shippingAmount, 15);
        expect(entity.total, 207);
        expect(entity.submittedAt, DateTime.utc(2026, 6, 1, 12));
      },
    );
  });

  group('OrderSubmissionResultDto.fromJson', () {
    test('parses a well-formed submitOrder response', () {
      final dto = OrderSubmissionResultDto.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'orderId': 'order-1',
        'orderNumber': '000001',
        'status': 'submitted',
        'discountAmount': 0,
        'surchargeAmount': 0,
        'shippingAmount': 0,
        'total': 200,
        'submittedAt': '2026-06-01T12:00:00.000Z',
        'items': <Map<String, dynamic>>[],
      });

      expect(dto.orderId, 'order-1');
      expect(dto.orderNumber, '000001');
      expect(dto.status, 'submitted');
      expect(dto.total, 200);
      expect(dto.submittedAt, DateTime.utc(2026, 6, 1, 12));
    });

    test('rejects a payload missing orderNumber', () {
      expect(
        () => OrderSubmissionResultDto.fromJson(<String, dynamic>{
          'orderId': 'order-1',
          'status': 'submitted',
          'discountAmount': 0,
          'surchargeAmount': 0,
          'shippingAmount': 0,
          'total': 200,
          'submittedAt': '2026-06-01T12:00:00.000Z',
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}

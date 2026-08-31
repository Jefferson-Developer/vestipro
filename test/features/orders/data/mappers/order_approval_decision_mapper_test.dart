import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderApprovalDecisionMapper', () {
    test(
      'toEntity copies every field as-is and resolves status through OrderMapper',
      () {
        final mapper = OrderApprovalDecisionMapper(const OrderMapper());
        final dto = OrderApprovalDecisionResultDto(
          orderId: 'order-1',
          status: 'approved',
          approverId: 'manager-1',
          decidedAt: DateTime.utc(2026, 6, 1, 12),
          reason: null,
        );

        final entity = mapper.toEntity(dto);

        expect(entity.orderId, 'order-1');
        expect(entity.status, OrderStatus.approved);
        expect(entity.approverId, 'manager-1');
        expect(entity.decidedAt, DateTime.utc(2026, 6, 1, 12));
        expect(entity.reason, isNull);
      },
    );

    test('copies a rejection reason as-is', () {
      final mapper = OrderApprovalDecisionMapper(const OrderMapper());
      final dto = OrderApprovalDecisionResultDto(
        orderId: 'order-1',
        status: 'rejected',
        approverId: 'manager-1',
        decidedAt: DateTime.utc(2026, 6, 1, 12),
        reason: 'Desconto fora da política.',
      );

      final entity = mapper.toEntity(dto);

      expect(entity.status, OrderStatus.rejected);
      expect(entity.reason, 'Desconto fora da política.');
    });
  });

  group('OrderApprovalDecisionResultDto.fromJson', () {
    test('parses a well-formed decideOrderApproval response', () {
      final dto = OrderApprovalDecisionResultDto.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'orderId': 'order-1',
        'status': 'approved',
        'approverId': 'manager-1',
        'decidedAt': '2026-06-01T12:00:00.000Z',
        'reason': null,
      });

      expect(dto.orderId, 'order-1');
      expect(dto.status, 'approved');
      expect(dto.approverId, 'manager-1');
      expect(dto.decidedAt, DateTime.utc(2026, 6, 1, 12));
      expect(dto.reason, isNull);
    });

    test('rejects a payload missing approverId', () {
      expect(
        () => OrderApprovalDecisionResultDto.fromJson(<String, dynamic>{
          'orderId': 'order-1',
          'status': 'approved',
          'decidedAt': '2026-06-01T12:00:00.000Z',
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}

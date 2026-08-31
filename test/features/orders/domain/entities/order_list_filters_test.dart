import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderListFilters', () {
    test('normalized trims/blanks empty ids and sellerIds', () {
      final filters = const OrderListFilters(
        customerId: '  ',
        orderNumber: ' 000123 ',
        sellerIds: <String>{' rep-1 ', ''},
      ).normalized();

      expect(filters.customerId, isNull);
      expect(filters.orderNumber, '000123');
      expect(filters.sellerIds, <String>{'rep-1'});
    });

    test('isEmpty is true only when every filter is unset', () {
      expect(OrderListFilters.empty.isEmpty, isTrue);
      expect(const OrderListFilters(customerId: 'customer-1').isEmpty, isFalse);
    });

    test('copyWith clearStatus/clearFrom/clearTo actually clear the field', () {
      final base = OrderListFilters(
        status: OrderStatus.submitted,
        from: DateTime.utc(2026, 1, 1),
        to: DateTime.utc(2026, 1, 31),
      );

      final cleared = base.copyWith(
        clearStatus: true,
        clearFrom: true,
        clearTo: true,
      );

      expect(cleared.status, isNull);
      expect(cleared.from, isNull);
      expect(cleared.to, isNull);
    });

    test('toQueryParameters/fromQueryParameters round-trip status/customer/'
        'period but never sellerIds', () {
      final filters = OrderListFilters(
        status: OrderStatus.approved,
        customerId: 'customer-1',
        sellerIds: const <String>{'rep-1'},
        from: DateTime.utc(2026, 1, 1),
        to: DateTime.utc(2026, 1, 31),
      );

      final query = filters.toQueryParameters(search: '000123');
      expect(query['q'], '000123');
      expect(query.containsKey('sellerIds'), isFalse);

      final restored = OrderListFilters.fromQueryParameters(query);
      expect(restored.status, OrderStatus.approved);
      expect(restored.customerId, 'customer-1');
      expect(restored.from, DateTime.utc(2026, 1, 1));
      expect(restored.to, DateTime.utc(2026, 1, 31));
      expect(restored.sellerIds, isEmpty);
    });

    test('fromQueryParameters ignores an invalid status code', () {
      final restored = OrderListFilters.fromQueryParameters(<String, String>{
        'status': 'not_a_real_status',
      });

      expect(restored.status, isNull);
    });
  });
}

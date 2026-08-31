import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  group('AppDatabase orders orderNumber column (TASK-102)', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    OrdersTableCompanion buildOrderRow({
      required String id,
      Value<String?> orderNumber = const Value.absent(),
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return OrdersTableCompanion.insert(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
        customerId: 'customer-1',
        sellerId: 'seller-1',
        orderNumber: orderNumber,
        deliveryAddressJson: '{}',
        billingAddressJson: '{}',
        priceListId: 'price-list-1',
        paymentTermId: 'payment-term-1',
        status: 'submitted',
        createdAt: now,
        createdBy: 'seller-1',
        updatedAt: now,
        updatedBy: 'seller-1',
        version: 1,
        syncStatus: 'synced',
      );
    }

    test('persists and reads back a confirmed order\'s orderNumber', () async {
      await database.upsertOrder(
        buildOrderRow(id: 'order-1', orderNumber: const Value('000123')),
      );

      final row = await database.getOrderById(
        organizationId: 'org-1',
        companyId: 'company-1',
        id: 'order-1',
      );

      expect(row?.order.orderNumber, '000123');
    });

    test('a pending/never-submitted order keeps a null orderNumber', () async {
      await database.upsertOrder(buildOrderRow(id: 'order-2'));

      final row = await database.getOrderById(
        organizationId: 'org-1',
        companyId: 'company-1',
        id: 'order-2',
      );

      expect(row?.order.orderNumber, isNull);
    });

    test(
      'getOrdersForCompany surfaces orderNumber for every local order',
      () async {
        await database.upsertOrder(
          buildOrderRow(id: 'order-3', orderNumber: const Value('000456')),
        );
        await database.upsertOrder(buildOrderRow(id: 'order-4'));

        final rows = await database.getOrdersForCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        final orderNumbers = <String, String?>{
          for (final row in rows) row.order.id: row.order.orderNumber,
        };
        expect(orderNumbers, <String, String?>{
          'order-3': '000456',
          'order-4': null,
        });
      },
    );
  });
}

import 'package:drift/drift.dart';

import 'orders_table.dart';

/// Local mirror of `Order.items` (EPIC-13, TASK-095), one row per
/// product-color-size line, scoped to the parent order row from
/// [OrdersTable].
///
/// `organizationId`/`companyId` are denormalized from the parent order so
/// scoped read/replace queries do not need a join to stay tenant-scoped,
/// same precedent `CustomerAddressesTable` already follows. [position]
/// preserves the original list order from the domain entity, since SQL row
/// order is not guaranteed otherwise.
@TableIndex(name: 'idx_order_items_order', columns: {#orderId})
@TableIndex(
  name: 'idx_order_items_org_company',
  columns: {#organizationId, #companyId},
)
class OrderItemsTable extends Table {
  @override
  String get tableName => 'order_items';

  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(OrdersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get surchargeAmount => real().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

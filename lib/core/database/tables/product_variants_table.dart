import 'package:drift/drift.dart';

import 'products_table.dart';

/// Local mirror of `ProductVariant` (EPIC-08, TASK-072) — the sellable
/// product+color+size SKU — used by the offline load of "variantes" from
/// `tasks.md` seção 5.1 (TASK-106), and the row `OrderItemsTable.variantId`
/// resolves against for offline grade comercial / order creation.
///
/// `ProductVariant` carries neither `companyId` nor `deletedAt`: variants are
/// organization-wide like their parent `Product`, and lifecycle is expressed
/// entirely through [status] (`ProductVariantStatus`), never a tombstone —
/// this table mirrors that shape exactly rather than forcing the generic
/// template's `companyId`/`deletedAt` columns where the domain has none.
///
/// [productId] references [ProductsTable] with `ON DELETE CASCADE`, mirroring
/// `OrderItemsTable.orderId` → `OrdersTable`: a full-reload replace of the
/// local product set (future sync engine, TASK-109) can delete stale product
/// rows without orphaning their variant rows.
@TableIndex(name: 'idx_product_variants_product', columns: {#productId})
@TableIndex(
  name: 'idx_product_variants_org_color',
  columns: {#organizationId, #colorId},
)
class ProductVariantsTable extends Table {
  @override
  String get tableName => 'product_variants';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get productId =>
      text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get colorId => text()();
  TextColumn get sizeGridTemplateId => text()();
  TextColumn get sizeId => text()();
  TextColumn get sku => text()();
  TextColumn get ean => text().nullable()();
  TextColumn get manualAvailabilityStatus => text().nullable()();
  IntColumn get manualAvailableQuantity => integer().nullable()();
  DateTimeColumn get manualFutureAvailableAt => dateTime().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  IntColumn get version => integer()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

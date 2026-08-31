import 'package:drift/drift.dart';

/// Local mirror of the `Order` aggregate (EPIC-13, TASK-095) used for the
/// offline load/cache of pedidos.
///
/// [deliveryAddressJson]/[billingAddressJson] encode an `OrderAddress` each;
/// [attachmentUrlsJson]/[statusHistoryJson] encode a list, same JSON-column
/// precedent as `CustomersTable.tagsJson`/`customFieldsJson` — there is
/// nothing that needs to query into those structures at the SQL level yet.
/// `OrderItemsTable` holds this order's items as child rows instead
/// (mirroring `CustomerAddressesTable`), since items are the one nested
/// structure later tasks (grade/catálogo screens) need to query directly.
///
/// `deletedAt` is a tombstone, never a physical row delete, same convention
/// every other offline-cached entity in this codebase already follows.
@TableIndex(
  name: 'idx_orders_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(name: 'idx_orders_customer', columns: {#customerId})
class OrdersTable extends Table {
  @override
  String get tableName => 'orders';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text()();
  TextColumn get sellerId => text()();
  // The definitive `orderNumber` `submitOrder` (TASK-101) generates
  // server-side — `null` for a local `draft`/`pendingSync` order that has
  // never reached the backend (TASK-102).
  TextColumn get orderNumber => text().nullable()();
  TextColumn get deliveryAddressJson => text()();
  TextColumn get billingAddressJson => text()();
  TextColumn get priceListId => text()();
  TextColumn get paymentTermId => text()();
  TextColumn get carrierId => text().nullable()();
  TextColumn get collectionId => text().nullable()();
  TextColumn get orderType => text().nullable()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get surchargeAmount => real().withDefault(const Constant(0))();
  RealColumn get shippingAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentUrlsJson => text().nullable()();
  TextColumn get status => text()();
  TextColumn get statusHistoryJson => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get rejectionReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

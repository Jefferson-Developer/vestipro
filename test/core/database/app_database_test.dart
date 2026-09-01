import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('creates the customer schema on a fresh database', () async {
      expect(database.schemaVersion, 18);

      // Exercises `onCreate`/`beforeOpen` by forcing the connection open.
      await database.customStatement('SELECT 1');

      final tableNames = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        tableNames,
        containsAll(<String>[
          'customers',
          'customer_addresses',
          'customer_contacts',
          'product_search_index',
          'favorites',
          'price_lists',
          'price_list_items',
          'payment_terms',
          'variant_stock_balances',
          'warehouses',
          'orders',
          'order_items',
        ]),
      );
    });

    test('cascades order deletion to its item rows, scoped to org/company '
        '(TASK-095)', () async {
      await database.replaceOrders(
        organizationId: 'org-1',
        companyId: 'company-1',
        orderRows: <OrdersTableCompanion>[_orderRow(id: 'order-1')],
        itemRows: <OrderItemsTableCompanion>[
          _orderItemRow(id: 'item-1', orderId: 'order-1'),
        ],
      );

      final beforeItems = await database.select(database.orderItemsTable).get();
      expect(beforeItems, hasLength(1));

      final loaded = await database.getOrdersForCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect(loaded, hasLength(1));
      expect(loaded.single.items, hasLength(1));

      // A second replace for the same org/company with an empty set must
      // remove the previous order row and, via `ON DELETE CASCADE`, its
      // item rows too.
      await database.replaceOrders(
        organizationId: 'org-1',
        companyId: 'company-1',
        orderRows: const <OrdersTableCompanion>[],
        itemRows: const <OrderItemsTableCompanion>[],
      );

      final afterOrders = await database.select(database.ordersTable).get();
      final afterItems = await database.select(database.orderItemsTable).get();
      expect(afterOrders, isEmpty);
      expect(afterItems, isEmpty);
    });

    test(
      'cascades customer deletion to its address and contact rows',
      () async {
        await database.replaceCustomers(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerRows: <CustomersTableCompanion>[
            _customerRow(id: 'customer-1'),
          ],
          addressRows: <CustomerAddressesTableCompanion>[
            _addressRow(id: 'address-1', customerId: 'customer-1'),
          ],
          contactRows: <CustomerContactsTableCompanion>[
            _contactRow(id: 'contact-1', customerId: 'customer-1'),
          ],
        );

        final beforeAddresses = await database
            .select(database.customerAddressesTable)
            .get();
        final beforeContacts = await database
            .select(database.customerContactsTable)
            .get();
        expect(beforeAddresses, hasLength(1));
        expect(beforeContacts, hasLength(1));

        // A second replace for the same org/company with an empty set must
        // remove the previous customer row and, via `ON DELETE CASCADE`,
        // its address/contact rows too.
        await database.replaceCustomers(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerRows: const <CustomersTableCompanion>[],
          addressRows: const <CustomerAddressesTableCompanion>[],
          contactRows: const <CustomerContactsTableCompanion>[],
        );

        final afterCustomers = await database
            .select(database.customersTable)
            .get();
        final afterAddresses = await database
            .select(database.customerAddressesTable)
            .get();
        final afterContacts = await database
            .select(database.customerContactsTable)
            .get();
        expect(afterCustomers, isEmpty);
        expect(afterAddresses, isEmpty);
        expect(afterContacts, isEmpty);
      },
    );

    test(
      'replaceCustomers only touches rows scoped to the given organization/company',
      () async {
        await database.replaceCustomers(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerRows: <CustomersTableCompanion>[
            _customerRow(id: 'customer-1'),
          ],
          addressRows: const <CustomerAddressesTableCompanion>[],
          contactRows: const <CustomerContactsTableCompanion>[],
        );
        await database.replaceCustomers(
          organizationId: 'org-2',
          companyId: 'company-2',
          customerRows: <CustomersTableCompanion>[
            _customerRow(
              id: 'customer-2',
              organizationId: 'org-2',
              companyId: 'company-2',
            ),
          ],
          addressRows: const <CustomerAddressesTableCompanion>[],
          contactRows: const <CustomerContactsTableCompanion>[],
        );

        // Re-running the initial load for org-1 must not remove org-2 data.
        await database.replaceCustomers(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerRows: const <CustomersTableCompanion>[],
          addressRows: const <CustomerAddressesTableCompanion>[],
          contactRows: const <CustomerContactsTableCompanion>[],
        );

        final org1Count = await database.countCustomersForCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        final org2Count = await database.countCustomersForCompany(
          organizationId: 'org-2',
          companyId: 'company-2',
        );
        expect(org1Count, 0);
        expect(org2Count, 1);
      },
    );

    test('getCustomersForCompany orders relations by position', () async {
      await database.replaceCustomers(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerRows: <CustomersTableCompanion>[_customerRow(id: 'customer-1')],
        addressRows: <CustomerAddressesTableCompanion>[
          _addressRow(id: 'address-b', customerId: 'customer-1', position: 1),
          _addressRow(id: 'address-a', customerId: 'customer-1', position: 0),
        ],
        contactRows: const <CustomerContactsTableCompanion>[],
      );

      final rows = await database.getCustomersForCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(rows, hasLength(1));
      expect(rows.single.addresses.map((address) => address.id), <String>[
        'address-a',
        'address-b',
      ]);
    });
  });
}

CustomersTableCompanion _customerRow({
  required String id,
  String organizationId = 'org-1',
  String companyId = 'company-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return CustomersTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    type: 'legalEntity',
    document: '04252011000110',
    status: 'active',
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: 'pending',
  );
}

CustomerAddressesTableCompanion _addressRow({
  required String id,
  required String customerId,
  String organizationId = 'org-1',
  String companyId = 'company-1',
  int position = 0,
}) {
  return CustomerAddressesTableCompanion.insert(
    id: id,
    customerId: customerId,
    organizationId: organizationId,
    companyId: companyId,
    typeCode: 'shipping',
    typeLabel: 'Entrega',
    street: 'Rua das Colecoes',
    city: 'Blumenau',
    state: 'SC',
    zipCode: '89010100',
    country: 'BR',
    position: Value(position),
  );
}

CustomerContactsTableCompanion _contactRow({
  required String id,
  required String customerId,
  String organizationId = 'org-1',
  String companyId = 'company-1',
}) {
  return CustomerContactsTableCompanion.insert(
    id: id,
    customerId: customerId,
    organizationId: organizationId,
    companyId: companyId,
    typeCode: 'commercial',
    typeLabel: 'Comercial',
    name: 'Contato',
    phone: const Value('47999999999'),
  );
}

OrdersTableCompanion _orderRow({
  required String id,
  String organizationId = 'org-1',
  String companyId = 'company-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  const addressJson =
      '{"street":"Rua das Colecoes","city":"Blumenau",'
      '"state":"SC","zipCode":"89010100","country":"BR"}';
  return OrdersTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
    deliveryAddressJson: addressJson,
    billingAddressJson: addressJson,
    priceListId: 'price-list-1',
    paymentTermId: 'payment-term-1',
    status: 'draft',
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: 'pending',
  );
}

OrderItemsTableCompanion _orderItemRow({
  required String id,
  required String orderId,
  String organizationId = 'org-1',
  String companyId = 'company-1',
  int position = 0,
}) {
  return OrderItemsTableCompanion.insert(
    id: id,
    orderId: orderId,
    organizationId: organizationId,
    companyId: companyId,
    variantId: 'variant-1',
    productId: 'product-1',
    quantity: 2,
    unitPrice: 100,
    subtotal: 200,
    position: Value(position),
  );
}

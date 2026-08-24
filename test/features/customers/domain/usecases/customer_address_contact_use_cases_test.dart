import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('Customer address use cases', () {
    late _InMemoryCustomerRepository repository;

    setUp(() {
      repository = _InMemoryCustomerRepository()..seed(_customer());
    });

    test('adds the first address as primary', () async {
      final result = await AddCustomerAddressUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        updatedBy: 'user-2',
        addressId: 'address-1',
        type: CustomerAddressType.shipping,
        street: 'Rua das Colecoes',
        number: '120',
        city: 'Blumenau',
        state: 'SC',
        zipCode: '89010-100',
      );

      expect(result, isA<AppSuccess<Customer>>());
      final customer = (result as AppSuccess<Customer>).value;
      expect(customer.addresses, hasLength(1));
      expect(customer.addresses.single.isPrimary, isTrue);
      expect(customer.addresses.single.zipCode, Cep.parse('89010-100'));
      expect(customer.syncStatus, CustomerSyncStatus.pending);
    });

    test('sets a secondary address as primary', () async {
      repository.seed(
        _customer(
          addresses: <CustomerAddress>[
            _address(id: 'shipping', isPrimary: true),
            _address(id: 'billing', type: CustomerAddressType.billing),
          ],
        ),
      );

      final result = await SetPrimaryCustomerAddressUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        addressId: 'billing',
        updatedBy: 'user-2',
      );

      final customer = (result as AppSuccess<Customer>).value;
      expect(
        customer.addresses
            .singleWhere((item) => item.id == 'billing')
            .isPrimary,
        isTrue,
      );
      expect(customer.addresses.where((item) => item.isPrimary), hasLength(1));
    });

    test('fills city and state from a locally known CEP', () async {
      repository.seed(
        _customer(
          addresses: <CustomerAddress>[_address(id: 'known', isPrimary: true)],
        ),
      );

      final result = await AddCustomerAddressUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        updatedBy: 'user-2',
        addressId: 'address-2',
        type: CustomerAddressType.billing,
        street: 'Rua do Financeiro',
        city: '',
        state: '',
        zipCode: '89010-100',
      );

      final customer = (result as AppSuccess<Customer>).value;
      final added = customer.addresses.singleWhere(
        (address) => address.id == 'address-2',
      );
      expect(added.city, 'Blumenau');
      expect(added.state, 'SC');
    });

    test('removes the primary address and promotes the next item', () async {
      repository.seed(
        _customer(
          addresses: <CustomerAddress>[
            _address(id: 'shipping', isPrimary: true),
            _address(id: 'billing', type: CustomerAddressType.billing),
          ],
        ),
      );

      final result = await RemoveCustomerAddressUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        addressId: 'shipping',
        updatedBy: 'user-2',
      );

      final customer = (result as AppSuccess<Customer>).value;
      expect(customer.addresses, hasLength(1));
      expect(customer.addresses.single.id, 'billing');
      expect(customer.addresses.single.isPrimary, isTrue);
    });
  });

  group('Customer contact use cases', () {
    late _InMemoryCustomerRepository repository;

    setUp(() {
      repository = _InMemoryCustomerRepository()..seed(_customer());
    });

    test('adds the first contact as primary', () async {
      final result = await AddCustomerContactUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        updatedBy: 'user-2',
        contactId: 'contact-1',
        type: CustomerContactType.buyer,
        name: 'Ana Compras',
        phone: '+55 47 99999-0000',
        email: 'ana@cliente.test',
      );

      final customer = (result as AppSuccess<Customer>).value;
      expect(customer.contacts.single.isPrimary, isTrue);
      expect(customer.primaryEmail, 'ana@cliente.test');
      expect(customer.primaryPhone, '+55 47 99999-0000');
    });

    test('removes the primary contact and promotes the next item', () async {
      repository.seed(
        _customer(
          contacts: <CustomerContact>[
            _contact(id: 'buyer', isPrimary: true, phone: '+55 47 99999-0000'),
            _contact(
              id: 'financial',
              type: CustomerContactType.financial,
              email: 'financeiro@cliente.test',
            ),
          ],
        ),
      );

      final result = await RemoveCustomerContactUseCase(repository).call(
        organizationId: 'org-1',
        customerId: 'customer-1',
        contactId: 'buyer',
        updatedBy: 'user-2',
      );

      final customer = (result as AppSuccess<Customer>).value;
      expect(customer.contacts, hasLength(1));
      expect(customer.contacts.single.id, 'financial');
      expect(customer.contacts.single.isPrimary, isTrue);
      expect(customer.primaryEmail, 'financeiro@cliente.test');
    });
  });
}

Customer _customer({
  List<CustomerAddress> addresses = const <CustomerAddress>[],
  List<CustomerContact> contacts = const <CustomerContact>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Moda Sul Confeccoes Ltda',
    status: CustomerStatus.prospect,
    registeredAt: now,
    addresses: addresses,
    contacts: contacts,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.synced,
  );
}

CustomerAddress _address({
  required String id,
  CustomerAddressType type = CustomerAddressType.shipping,
  bool isPrimary = false,
}) {
  return CustomerAddress(
    id: id,
    type: type,
    street: 'Rua das Colecoes',
    number: '120',
    city: 'Blumenau',
    state: 'SC',
    zipCode: Cep.parse('89010-100'),
    isPrimary: isPrimary,
  );
}

CustomerContact _contact({
  required String id,
  CustomerContactType type = CustomerContactType.buyer,
  String? phone,
  String? email,
  bool isPrimary = false,
}) {
  return CustomerContact(
    id: id,
    type: type,
    name: 'Contato $id',
    phone: phone,
    email: email,
    isPrimary: isPrimary,
  );
}

final class _InMemoryCustomerRepository implements CustomerRepository {
  Customer? customer;

  void seed(Customer value) {
    customer = value;
  }

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) async {
    return const AppSuccess<bool>(false);
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) async {
    this.customer = customer;
    return AppSuccess<Customer>(customer);
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) async {
    this.customer = customer;
    return AppSuccess<Customer>(customer);
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    return const AppFailure<Customer>(
      NotFoundFailure('Customer not found.', code: 'customer_not_found'),
    );
  }

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    final current = customer;
    if (current == null ||
        current.organizationId != organizationId ||
        current.id != id) {
      return const AppFailure<Customer>(
        NotFoundFailure('Customer not found.', code: 'customer_not_found'),
      );
    }
    return AppSuccess<Customer>(current);
  }
}

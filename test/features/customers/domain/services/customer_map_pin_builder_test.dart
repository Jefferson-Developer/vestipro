import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerMapPinBuilder (TASK-176)', () {
    const builder = CustomerMapPinBuilder();

    test('builds one pin per customer with a geocoded primary address', () {
      final customers = <Customer>[
        _customer(
          id: 'customer-1',
          addresses: <CustomerAddress>[_geocodedAddress(isPrimary: true)],
        ),
        _customer(
          id: 'customer-2',
          addresses: <CustomerAddress>[_geocodedAddress(isPrimary: true)],
        ),
      ];

      final pins = builder.build(customers);

      expect(pins, hasLength(2));
      expect(pins.map((pin) => pin.customerId), <String>[
        'customer-1',
        'customer-2',
      ]);
      expect(builder.customersWithoutLocationCount(customers), 0);
    });

    test('skips a customer without any geocoded address, but counts it', () {
      final customers = <Customer>[
        _customer(id: 'customer-1', addresses: const <CustomerAddress>[]),
        _customer(
          id: 'customer-2',
          addresses: <CustomerAddress>[
            _address(status: CustomerGeocodingStatus.unavailable),
          ],
        ),
        _customer(
          id: 'customer-3',
          addresses: <CustomerAddress>[_geocodedAddress(isPrimary: true)],
        ),
      ];

      final pins = builder.build(customers);

      expect(pins, hasLength(1));
      expect(pins.single.customerId, 'customer-3');
      expect(builder.customersWithoutLocationCount(customers), 2);
    });

    test('prefers the primary geocoded address over a secondary one', () {
      final primary = _geocodedAddress(
        id: 'address-primary',
        isPrimary: true,
        latitude: -1,
        longitude: -1,
      );
      final secondary = _geocodedAddress(
        id: 'address-secondary',
        latitude: -2,
        longitude: -2,
      );
      final customer = _customer(
        id: 'customer-1',
        addresses: <CustomerAddress>[secondary, primary],
      );

      final pin = builder.build(<Customer>[customer]).single;

      expect(pin.coordinates.latitude, -1);
      expect(pin.coordinates.longitude, -1);
    });

    test('falls back to any other geocoded address when the primary one has '
        'no coordinates', () {
      final ungeocodedPrimary = _address(isPrimary: true);
      final geocodedSecondary = _geocodedAddress(latitude: -3, longitude: -3);
      final customer = _customer(
        id: 'customer-1',
        addresses: <CustomerAddress>[ungeocodedPrimary, geocodedSecondary],
      );

      final pin = builder.build(<Customer>[customer]).single;

      expect(pin.coordinates.latitude, -3);
      expect(pin.coordinates.longitude, -3);
    });
  });
}

Customer _customer({
  required String id,
  required List<CustomerAddress> addresses,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Cliente Teste',
    status: CustomerStatus.active,
    addresses: addresses,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.synced,
  );
}

CustomerAddress _address({
  String id = 'address-1',
  bool isPrimary = false,
  CustomerGeocodingStatus status = CustomerGeocodingStatus.pending,
}) {
  return CustomerAddress(
    id: id,
    type: CustomerAddressType.shipping,
    street: 'Rua das Colecoes',
    city: 'Blumenau',
    state: 'SC',
    zipCode: Cep.parse('89010-100'),
    isPrimary: isPrimary,
    geocodingStatus: status,
  );
}

CustomerAddress _geocodedAddress({
  String id = 'address-1',
  bool isPrimary = false,
  double latitude = -26.9194,
  double longitude = -49.0661,
}) {
  return CustomerAddress(
    id: id,
    type: CustomerAddressType.shipping,
    street: 'Rua das Colecoes',
    city: 'Blumenau',
    state: 'SC',
    zipCode: Cep.parse('89010-100'),
    isPrimary: isPrimary,
    coordinates: GeoCoordinates.validated(
      latitude: latitude,
      longitude: longitude,
    ),
    geocodingStatus: CustomerGeocodingStatus.geocoded,
    geocodedAt: DateTime.utc(2026, 1, 2),
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerMapClusterer (TASK-176)', () {
    const clusterer = CustomerMapClusterer();

    test('returns no clusters for an empty pin list', () {
      expect(
        clusterer.cluster(pins: const <CustomerMapPin>[], zoom: 10),
        isEmpty,
      );
    });

    test('groups a high-density set of nearby pins into a single cluster at a '
        'low (zoomed-out) zoom level', () {
      // 200 pins scattered within ~1km of each other (a dense
      // neighborhood) — simulates a crowded region of the carteira.
      final pins = List<CustomerMapPin>.generate(
        200,
        (index) => _pin(
          id: 'customer-$index',
          latitude: -26.9194 + (index % 20) * 0.0005,
          longitude: -49.0661 + (index % 20) * 0.0005,
        ),
      );

      final clusters = clusterer.cluster(pins: pins, zoom: 4);

      expect(clusters, hasLength(1));
      expect(clusters.single.isCluster, isTrue);
      expect(clusters.single.pins, hasLength(200));
    });

    test('the same dense pin set separates back into individual markers at a '
        'high (zoomed-in) zoom level', () {
      final pins = <CustomerMapPin>[
        _pin(id: 'customer-1', latitude: -26.90, longitude: -49.00),
        _pin(id: 'customer-2', latitude: -25.50, longitude: -48.00),
        _pin(id: 'customer-3', latitude: -23.00, longitude: -46.50),
      ];

      final clusters = clusterer.cluster(pins: pins, zoom: 18);

      expect(clusters, hasLength(3));
      expect(clusters.every((cluster) => !cluster.isCluster), isTrue);
    });

    test('a lone pin is never wrapped in a cluster, at any zoom', () {
      final pins = <CustomerMapPin>[
        _pin(id: 'customer-1', latitude: -26.90, longitude: -49.00),
      ];

      final clusters = clusterer.cluster(pins: pins, zoom: 4);

      expect(clusters, hasLength(1));
      expect(clusters.single.isCluster, isFalse);
      expect(clusters.single.singlePin.customerId, 'customer-1');
    });

    test('clamps an out-of-range zoom instead of throwing', () {
      final pins = <CustomerMapPin>[
        _pin(id: 'customer-1', latitude: -26.90, longitude: -49.00),
        _pin(id: 'customer-2', latitude: -26.9001, longitude: -49.0001),
      ];

      expect(() => clusterer.cluster(pins: pins, zoom: -5), returnsNormally);
      expect(() => clusterer.cluster(pins: pins, zoom: 999), returnsNormally);
    });
  });
}

CustomerMapPin _pin({
  required String id,
  required double latitude,
  required double longitude,
}) {
  return CustomerMapPin(
    customerId: id,
    displayName: 'Cliente $id',
    status: CustomerStatus.active,
    potential: 'Alto',
    lastPurchaseAt: null,
    coordinates: GeoCoordinates.validated(
      latitude: latitude,
      longitude: longitude,
    ),
  );
}

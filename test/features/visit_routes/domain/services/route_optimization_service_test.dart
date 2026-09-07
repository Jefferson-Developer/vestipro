import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('RouteOptimizationService (TASK-177)', () {
    const service = RouteOptimizationService();

    CustomerMapPin pin(String id, double latitude, double longitude) {
      return CustomerMapPin(
        customerId: id,
        displayName: 'Cliente $id',
        status: CustomerStatus.active,
        potential: null,
        lastPurchaseAt: null,
        coordinates: GeoCoordinates.validated(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    test('orders stops by nearest-neighbor distance from the given origin', () {
      // Laid out along a single meridian so distance is monotonic with
      // latitude, making the expected nearest-neighbor order unambiguous:
      // origin -> A (closest) -> C (next closest to A) -> B (farthest).
      final origin = GeoCoordinates.validated(latitude: 0, longitude: 0);
      final pinA = pin('A', 1, 0);
      final pinC = pin('C', 2, 0);
      final pinB = pin('B', 3, 0);

      final result = service.optimize(
        selectedPins: <CustomerMapPin>[pinB, pinA, pinC],
        origin: origin,
      );

      final stops = (result as AppSuccess<List<VisitRouteStop>>).value;
      expect(stops.map((stop) => stop.customerId), <String>['A', 'C', 'B']);
      expect(stops.map((stop) => stop.sequence), <int>[0, 1, 2]);
      // First stop's distance is measured from the origin, not null.
      expect(stops[0].distanceFromPreviousKm, isNotNull);
      expect(stops[0].etaMinutesFromPrevious, isNotNull);
    });

    test('without an origin, starts from the first selected pin and still '
        'chains nearest-neighbor from there', () {
      final pinA = pin('A', 1, 0);
      final pinC = pin('C', 2, 0);
      final pinB = pin('B', 3, 0);

      final result = service.optimize(
        selectedPins: <CustomerMapPin>[pinA, pinB, pinC],
      );

      final stops = (result as AppSuccess<List<VisitRouteStop>>).value;
      expect(stops.map((stop) => stop.customerId), <String>['A', 'C', 'B']);
      // No origin to measure the first stop's distance from.
      expect(stops[0].distanceFromPreviousKm, isNull);
      expect(stops[0].etaMinutesFromPrevious, isNull);
      expect(stops[1].distanceFromPreviousKm, isNotNull);
    });

    test('fails validation when no customer is selected', () {
      final result = service.optimize(selectedPins: const <CustomerMapPin>[]);

      expect(result, isA<AppFailure<List<VisitRouteStop>>>());
      final failure = (result as AppFailure<List<VisitRouteStop>>).failure;
      expect(failure.code, 'visit_route_empty_selection');
    });

    test('fails validation when the selection exceeds the max stops limit', () {
      const limitedService = RouteOptimizationService(maxStops: 2);
      final pins = <CustomerMapPin>[
        pin('A', 1, 0),
        pin('B', 2, 0),
        pin('C', 3, 0),
      ];

      final result = limitedService.optimize(selectedPins: pins);

      expect(result, isA<AppFailure<List<VisitRouteStop>>>());
      final failure = (result as AppFailure<List<VisitRouteStop>>).failure;
      expect(failure.code, 'visit_route_too_many_stops');
    });
  });
}

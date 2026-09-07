import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

/// TASK-177: "Falha do serviço de roteirização não pode impedir o vendedor
/// de abrir a navegação básica para um cliente individual".
///
/// [NavigationLinkBuilder] takes a single [GeoCoordinates] destination and
/// has no dependency on [RouteOptimizationService] whatsoever — opening
/// navigation to one customer never goes through route optimization at
/// all. This test documents that decoupling explicitly: even when
/// [RouteOptimizationService] fails outright (e.g. too many stops selected,
/// or none at all), building a navigation link for a single, already-known
/// destination still succeeds.
void main() {
  test('a single-destination navigation link still builds even when route '
      'optimization fails for the batch selection', () {
    const optimizationService = RouteOptimizationService(maxStops: 1);
    const navigationLinkBuilder = NavigationLinkBuilder();

    CustomerMapPin pin(String id, double latitude) {
      return CustomerMapPin(
        customerId: id,
        displayName: 'Cliente $id',
        status: CustomerStatus.active,
        potential: null,
        lastPurchaseAt: null,
        coordinates: GeoCoordinates.validated(latitude: latitude, longitude: 0),
      );
    }

    final oversizedSelection = <CustomerMapPin>[pin('A', 1), pin('B', 2)];

    final routeResult = optimizationService.optimize(
      selectedPins: oversizedSelection,
    );
    expect(routeResult, isA<AppFailure<List<VisitRouteStop>>>());

    // The seller still has a single destination in mind (e.g. tapped
    // "Navegar" on one customer's card) — this never depends on the
    // batch route above having succeeded.
    final singleDestination = oversizedSelection.first.coordinates;
    final uri = navigationLinkBuilder.build(
      provider: NavigationProvider.googleMaps,
      destination: singleDestination,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
  });
}

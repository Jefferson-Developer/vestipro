import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('NavigationLinkBuilder (TASK-177)', () {
    const builder = NavigationLinkBuilder();
    final destination = GeoCoordinates.validated(
      latitude: -26.9194,
      longitude: -49.0661,
    );

    test('builds a well-formed Google Maps universal link', () {
      final uri = builder.build(
        provider: NavigationProvider.googleMaps,
        destination: destination,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['destination'], '-26.9194,-49.0661');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('builds a well-formed Waze universal link', () {
      final uri = builder.build(
        provider: NavigationProvider.waze,
        destination: destination,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'waze.com');
      expect(uri.queryParameters['ll'], '-26.9194,-49.0661');
      expect(uri.queryParameters['navigate'], 'yes');
    });

    test('builds a well-formed Apple Maps universal link', () {
      final uri = builder.build(
        provider: NavigationProvider.appleMaps,
        destination: destination,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['daddr'], '-26.9194,-49.0661');
    });

    test('only ever accepts a validated GeoCoordinates value — there is no '
        'overload/parameter that forwards a raw/arbitrary URL or string', () {
      // GeoCoordinates.validated is the only way to construct a
      // GeoCoordinates, and it always rejects out-of-range values — so any
      // value reaching `build` is guaranteed well-formed. This test
      // documents that structural guarantee: an out-of-range coordinate
      // can never reach `build` in the first place.
      expect(
        () => GeoCoordinates.validated(latitude: 999, longitude: 0),
        throwsA(anything),
      );

      // Boundary-valid coordinates still produce a well-formed https link.
      final boundary = GeoCoordinates.validated(latitude: 90, longitude: 180);
      final uri = builder.build(
        provider: NavigationProvider.googleMaps,
        destination: boundary,
      );
      expect(uri.scheme, 'https');
      expect(uri.queryParameters['destination'], '90.0,180.0');
    });
  });
}

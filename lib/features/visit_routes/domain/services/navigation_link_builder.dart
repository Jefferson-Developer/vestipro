import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../value_objects/navigation_provider.dart';

/// Builds the external navigation-app URL for a single destination
/// (TASK-177).
///
/// This is the entire security boundary the "abrir navegação externa"
/// requirement relies on: the only input this class accepts is a
/// [GeoCoordinates] value — which, by construction, can only ever come from
/// [GeoCoordinates.validated] — and a closed [NavigationProvider] enum.
/// There is no code path here (or anywhere upstream: see
/// `VisitRouteStop.coordinates`) that lets an arbitrary URL/string received
/// from outside the app (a deep link, a server payload, pasted text, ...)
/// be forwarded to an external navigation app. Callers must always source
/// [destination] from a stop that already belongs to the seller's own
/// active [VisitRoute] (see `VisitRouteBloc`), never from raw user input.
final class NavigationLinkBuilder {
  const NavigationLinkBuilder();

  Uri build({
    required NavigationProvider provider,
    required GeoCoordinates destination,
  }) {
    final latitude = destination.latitude;
    final longitude = destination.longitude;
    return switch (provider) {
      NavigationProvider.googleMaps => Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude&travelmode=driving',
      ),
      NavigationProvider.waze => Uri.parse(
        'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
      ),
      NavigationProvider.appleMaps => Uri.parse(
        'https://maps.apple.com/?daddr=$latitude,$longitude',
      ),
    };
  }
}

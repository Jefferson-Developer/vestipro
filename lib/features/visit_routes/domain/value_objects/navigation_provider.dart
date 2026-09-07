/// External map/navigation app a seller may open a [VisitRouteStop]'s
/// destination in (TASK-177). Kept as a closed set — never a raw string —
/// so `NavigationLinkBuilder` can only ever build one of these three known,
/// well-formed universal links, never an arbitrary URL.
enum NavigationProvider { googleMaps, waze, appleMaps }

extension NavigationProviderLabel on NavigationProvider {
  String get label {
    return switch (this) {
      NavigationProvider.googleMaps => 'Google Maps',
      NavigationProvider.waze => 'Waze',
      NavigationProvider.appleMaps => 'Apple Maps',
    };
  }
}

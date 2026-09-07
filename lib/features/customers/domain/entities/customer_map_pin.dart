import '../value_objects/customer_status.dart';
import '../value_objects/geo_coordinates.dart';

/// A single pin on the customer map (TASK-176): the minimal projection of a
/// [Customer] the map/clusterer/card actually need, so that presentation
/// code never has to reach back into the full [Customer] aggregate (and its
/// address list) just to render a marker.
final class CustomerMapPin {
  const CustomerMapPin({
    required this.customerId,
    required this.displayName,
    required this.status,
    required this.potential,
    required this.lastPurchaseAt,
    required this.coordinates,
  });

  final String customerId;
  final String displayName;
  final CustomerStatus status;
  final String? potential;
  final DateTime? lastPurchaseAt;
  final GeoCoordinates coordinates;

  @override
  bool operator ==(Object other) =>
      other is CustomerMapPin &&
      other.customerId == customerId &&
      other.displayName == displayName &&
      other.status == status &&
      other.potential == potential &&
      other.lastPurchaseAt == lastPurchaseAt &&
      other.coordinates == coordinates;

  @override
  int get hashCode => Object.hash(
    customerId,
    displayName,
    status,
    potential,
    lastPurchaseAt,
    coordinates,
  );
}

/// A group of one or more [CustomerMapPin]s rendered as a single marker at
/// zoom levels where they are too close together to tell apart
/// (`CustomerMapClusterer`, TASK-176).
final class MapCluster {
  const MapCluster({
    required this.latitude,
    required this.longitude,
    required this.pins,
  });

  final double latitude;
  final double longitude;
  final List<CustomerMapPin> pins;

  bool get isCluster => pins.length > 1;

  /// Only safe to call when [isCluster] is `false`.
  CustomerMapPin get singlePin => pins.single;
}

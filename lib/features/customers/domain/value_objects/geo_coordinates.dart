import 'dart:math' as math;

import '../../../../core/errors/errors.dart';

/// Geographic coordinates (WGS84) of a geocoded [CustomerAddress].
///
/// TASK-176: produced by geocoding a customer's address (client-side best
/// effort on creation/edition, or by the server backfill job for customers
/// registered before this feature existed). Never trusted as authoritative
/// business data — it only feeds the customer map visualization (TASK-176)
/// and route planning (TASK-177, [distanceToKm]).
final class GeoCoordinates {
  const GeoCoordinates._(this.latitude, this.longitude);

  factory GeoCoordinates.validated({
    required double latitude,
    required double longitude,
  }) {
    final fieldErrors = <String, String>{};
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      fieldErrors['latitude'] = 'Latitude must be between -90 and 90.';
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      fieldErrors['longitude'] = 'Longitude must be between -180 and 180.';
    }
    if (fieldErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid geographic coordinates.',
        code: 'invalid_geo_coordinates',
        fieldErrors: fieldErrors,
        cause: '($latitude, $longitude)',
      );
    }
    return GeoCoordinates._(latitude, longitude);
  }

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoordinates($latitude, $longitude)';

  /// Great-circle distance to [other], in kilometers (haversine formula).
  ///
  /// TASK-177: this is the only distance metric
  /// `RouteOptimizationService` (visit route planning) uses to order stops —
  /// a straight-line approximation, not a real driving distance/duration
  /// from a Directions API. Good enough for a nearest-neighbor heuristic
  /// over a seller's daily stops (typically a handful to a few dozen
  /// customers within the same city/region); never used for anything
  /// billing/SLA-sensitive.
  double distanceToKm(GeoCoordinates other) {
    const earthRadiusKm = 6371.0;
    final deltaLatitude = _degreesToRadians(other.latitude - latitude);
    final deltaLongitude = _degreesToRadians(other.longitude - longitude);
    final originLatitude = _degreesToRadians(latitude);
    final destinationLatitude = _degreesToRadians(other.latitude);

    final a =
        math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2) *
            math.cos(originLatitude) *
            math.cos(destinationLatitude);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

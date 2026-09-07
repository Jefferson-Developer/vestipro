import '../../../../core/errors/errors.dart';

/// Geographic coordinates (WGS84) of a geocoded [CustomerAddress].
///
/// TASK-176: produced by geocoding a customer's address (client-side best
/// effort on creation/edition, or by the server backfill job for customers
/// registered before this feature existed). Never trusted as authoritative
/// business data — it only feeds the customer map visualization (TASK-176)
/// and, later, route planning (TASK-177).
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
}

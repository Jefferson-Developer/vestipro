import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../value_objects/visit_check_in_location_status.dart';

/// Result of (optionally) capturing the device's current location for a
/// single visit check-in (TASK-178).
///
/// [distanceToCustomerKm] is always informational/complementary — never a
/// requirement or a reason to block a check-in (see
/// `CheckInVisitUseCase`/TASK-178 "Regras de negócio").
final class VisitCheckInLocationCapture {
  const VisitCheckInLocationCapture({
    required this.status,
    this.coordinates,
    this.distanceToCustomerKm,
  });

  /// The seller explicitly chose not to share location for this check-in —
  /// no permission was ever requested.
  static const VisitCheckInLocationCapture skippedByUser =
      VisitCheckInLocationCapture(
        status: VisitCheckInLocationStatus.skippedByUser,
      );

  final VisitCheckInLocationStatus status;
  final GeoCoordinates? coordinates;
  final double? distanceToCustomerKm;

  bool get hasCoordinates => coordinates != null;

  /// Returns a copy with [distanceToCustomerKm] computed against
  /// [customerCoordinates] (haversine, via `GeoCoordinates.distanceToKm`),
  /// when both this capture's coordinates and [customerCoordinates] are
  /// available. Returns this same instance otherwise.
  VisitCheckInLocationCapture withDistanceTo(
    GeoCoordinates? customerCoordinates,
  ) {
    final capturedCoordinates = coordinates;
    if (capturedCoordinates == null || customerCoordinates == null) {
      return this;
    }
    return VisitCheckInLocationCapture(
      status: status,
      coordinates: capturedCoordinates,
      distanceToCustomerKm: capturedCoordinates.distanceToKm(
        customerCoordinates,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VisitCheckInLocationCapture &&
            other.status == status &&
            other.coordinates == coordinates &&
            other.distanceToCustomerKm == distanceToCustomerKm;
  }

  @override
  int get hashCode => Object.hash(status, coordinates, distanceToCustomerKm);

  @override
  String toString() =>
      'VisitCheckInLocationCapture(status: $status, coordinates: '
      '$coordinates, distanceToCustomerKm: $distanceToCustomerKm)';
}

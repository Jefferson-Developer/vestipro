import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../../domain/entities/visit_check_in_location_capture.dart';
import '../../domain/services/visit_check_in_location_service.dart';
import '../../domain/value_objects/visit_check_in_location_status.dart';

/// [VisitCheckInLocationService] backed by `package:geolocator` (TASK-178).
///
/// Only ever invoked by `CheckInVisitUseCase` when the seller has already
/// opted in (app-level toggle) to share location for that specific
/// check-in — this class then triggers the OS-level permission prompt (when
/// not yet decided) and reads the current position. Every expected,
/// non-exceptional outcome (service disabled, permission denied/denied
/// forever, timeout/no signal) is reported as an [AppSuccess] carrying the
/// matching [VisitCheckInLocationStatus] — never as an [AppFailure] — so a
/// missing location structurally can never fail the check-in itself; only a
/// genuinely unexpected platform error is caught and reported the same way
/// (as [VisitCheckInLocationStatus.unavailable]).
@LazySingleton(as: VisitCheckInLocationService)
final class GeolocatorVisitCheckInLocationService
    implements VisitCheckInLocationService {
  const GeolocatorVisitCheckInLocationService();

  static const Duration _positionTimeLimit = Duration(seconds: 15);

  @override
  Future<AppResult<VisitCheckInLocationCapture>>
  captureCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const AppSuccess<VisitCheckInLocationCapture>(
          VisitCheckInLocationCapture(
            status: VisitCheckInLocationStatus.serviceDisabled,
          ),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Explicit, per-action permission request — this is the moment the
        // seller sees the OS consent dialog for this specific check-in.
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const AppSuccess<VisitCheckInLocationCapture>(
          VisitCheckInLocationCapture(
            status: VisitCheckInLocationStatus.permissionDenied,
          ),
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const AppSuccess<VisitCheckInLocationCapture>(
          VisitCheckInLocationCapture(
            status: VisitCheckInLocationStatus.permissionDeniedForever,
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _positionTimeLimit,
        ),
      );
      return AppSuccess<VisitCheckInLocationCapture>(
        VisitCheckInLocationCapture(
          status: VisitCheckInLocationStatus.captured,
          coordinates: GeoCoordinates.validated(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        ),
      );
    } catch (_) {
      // Timeout, no signal, or any other unexpected platform error — still
      // a valid, non-blocking check-in outcome, never a thrown/propagated
      // failure (see class doc).
      return const AppSuccess<VisitCheckInLocationCapture>(
        VisitCheckInLocationCapture(
          status: VisitCheckInLocationStatus.unavailable,
        ),
      );
    }
  }
}

import '../../../../core/utils/utils.dart';
import '../entities/visit_check_in_location_capture.dart';

/// Device geolocation gateway for a visit check-in (TASK-178).
///
/// Only ever called when the seller has explicitly opted in to share
/// location for *that specific* check-in (`CheckInVisitUseCase`'s
/// `shareLocation` flag) — this contract itself makes no decision about
/// when to ask, only how. Implementations must never throw for an expected
/// outcome (permission denied, service disabled, timeout/no signal) —
/// return the matching [VisitCheckInLocationCapture] status instead, so a
/// missing/denied location structurally can never fail the check-in itself.
abstract interface class VisitCheckInLocationService {
  Future<AppResult<VisitCheckInLocationCapture>> captureCurrentLocation();
}

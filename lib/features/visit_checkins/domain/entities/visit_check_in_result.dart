import '../../../crm/domain/entities/crm_activity.dart';
import 'visit_check_in_location_capture.dart';

/// Outcome of a successful visit check-in (TASK-178): the CRM activity that
/// is the check-in's evidence (always created) and the location capture
/// outcome (always present, possibly "skipped"/"denied"/"unavailable").
///
/// Deliberately carries nothing about visit routes (TASK-177) — a caller
/// that also needs to mark a route stop as visited (e.g. `VisitRouteBloc`)
/// does so itself with its own `MarkVisitRouteStopStatusUseCase`, see
/// `CheckInVisitUseCase`'s doc for why.
final class VisitCheckInResult {
  const VisitCheckInResult({required this.activity, required this.location});

  final CrmActivity activity;
  final VisitCheckInLocationCapture location;
}

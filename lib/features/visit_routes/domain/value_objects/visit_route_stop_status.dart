/// Progress status of a single stop in a [VisitRoute] (TASK-177).
///
/// - [pending]: not yet visited.
/// - [completed]: the seller has checked in/finished this stop. This module
///   only exposes a way to persist the flip (`MarkVisitRouteStopStatusUseCase`)
///   for the actual check-in flow (geofencing, evidence, timestamps) to be
///   built by TASK-178 — no check-in business rule is implemented here.
enum VisitRouteStopStatus { pending, completed }

extension VisitRouteStopStatusCode on VisitRouteStopStatus {
  String get code {
    return switch (this) {
      VisitRouteStopStatus.pending => 'pending',
      VisitRouteStopStatus.completed => 'completed',
    };
  }
}

VisitRouteStopStatus visitRouteStopStatusFromCode(String? code) {
  return switch (code) {
    'completed' => VisitRouteStopStatus.completed,
    _ => VisitRouteStopStatus.pending,
  };
}

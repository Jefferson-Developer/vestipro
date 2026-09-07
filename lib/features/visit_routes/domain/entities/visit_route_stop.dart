import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../value_objects/visit_route_stop_status.dart';

part 'visit_route_stop.freezed.dart';

/// A single ordered stop of a [VisitRoute] (TASK-177).
///
/// [coordinates] is always a validated [GeoCoordinates] instance — it can
/// only ever have been constructed via [GeoCoordinates.validated] — which is
/// the structural guarantee `NavigationLinkBuilder` relies on to never open
/// external navigation with an arbitrary/unvalidated location.
@freezed
abstract class VisitRouteStop with _$VisitRouteStop {
  const VisitRouteStop._();

  const factory VisitRouteStop({
    required String customerId,
    required String displayName,
    required GeoCoordinates coordinates,
    required int sequence,
    @Default(VisitRouteStopStatus.pending) VisitRouteStopStatus status,
    // Straight-line (haversine) distance/time estimate from the previous
    // stop (or from the seller's starting point, for the first stop) — a
    // nearest-neighbor heuristic approximation, not a real driving
    // distance/duration from a Directions API. `null` only when no
    // reference point was available to compute it from (first stop with no
    // known origin).
    double? distanceFromPreviousKm,
    int? etaMinutesFromPrevious,
  }) = _VisitRouteStop;

  bool get isCompleted => status == VisitRouteStopStatus.completed;
}

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/domain/entities/customer_map_pin.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../entities/visit_route_stop.dart';

/// Builds an ordered, distance/time-estimated visit sequence out of a set of
/// already-selected [CustomerMapPin]s (TASK-177).
///
/// This is a nearest-neighbor heuristic over straight-line (haversine)
/// distance — not a TSP solver and not a call to any external
/// Directions/routing API. That is a deliberate trade-off documented in
/// TASK-177's conclusion doc: it keeps route building 100% local/offline
/// (no network dependency, so it can never "be unavailable" the way a
/// remote routing service could) at the cost of not knowing real road
/// distances/travel times — acceptable for a seller's daily handful of
/// stops within the same city/region, and consistent with the spec's own
/// "não precisa ser um solver TSP complexo" allowance.
@injectable
final class RouteOptimizationService {
  const RouteOptimizationService({
    this.averageSpeedKmh = 30,
    this.maxStops = 20,
  });

  /// Assumed average travel speed used only to turn a distance estimate
  /// into a time estimate (urban driving approximation) — never presented
  /// as a guaranteed ETA.
  final double averageSpeedKmh;

  /// Upper bound of stops a single route may contain, keeping a vendor from
  /// building an absurdly long route (`tasks.md`/TASK-177: "limite razoável
  /// de paradas por rota (configurável)").
  final int maxStops;

  AppResult<List<VisitRouteStop>> optimize({
    required List<CustomerMapPin> selectedPins,
    GeoCoordinates? origin,
  }) {
    if (selectedPins.isEmpty) {
      return const AppFailure<List<VisitRouteStop>>(
        ValidationFailure(
          'Select at least one customer to build a visit route.',
          code: 'visit_route_empty_selection',
        ),
      );
    }
    if (selectedPins.length > maxStops) {
      return AppFailure<List<VisitRouteStop>>(
        ValidationFailure(
          'A visit route cannot have more than $maxStops stops.',
          code: 'visit_route_too_many_stops',
          fieldErrors: <String, String>{
            'selectedPins': 'Maximum of $maxStops stops per route.',
          },
        ),
      );
    }

    final remaining = List<CustomerMapPin>.of(selectedPins);
    final stops = <VisitRouteStop>[];

    var referencePoint = origin;
    var current = _nearestTo(referencePoint, remaining) ?? remaining.first;

    var sequence = 0;
    while (remaining.isNotEmpty) {
      remaining.remove(current);
      final distanceKm = referencePoint?.distanceToKm(current.coordinates);
      stops.add(
        VisitRouteStop(
          customerId: current.customerId,
          displayName: current.displayName,
          coordinates: current.coordinates,
          sequence: sequence,
          distanceFromPreviousKm: distanceKm,
          etaMinutesFromPrevious: distanceKm == null
              ? null
              : ((distanceKm / averageSpeedKmh) * 60).round(),
        ),
      );
      sequence += 1;
      referencePoint = current.coordinates;
      if (remaining.isEmpty) break;
      current = _nearestTo(referencePoint, remaining)!;
    }

    return AppSuccess<List<VisitRouteStop>>(stops);
  }

  CustomerMapPin? _nearestTo(
    GeoCoordinates? reference,
    List<CustomerMapPin> candidates,
  ) {
    if (reference == null) return null;
    var nearest = candidates.first;
    var nearestDistance = reference.distanceToKm(nearest.coordinates);
    for (final candidate in candidates.skip(1)) {
      final distance = reference.distanceToKm(candidate.coordinates);
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visit_route_stop.dart';

part 'visit_route.freezed.dart';

/// A seller's planned sequence of customer visits for a single calendar day
/// (TASK-177, EPIC-24).
///
/// Local-only aggregate: today there is no remote/Firestore counterpart —
/// `date` is normalized to UTC midnight so "the route for today" always
/// resolves to exactly one row locally
/// (`VisitRouteRepository.getForDate`/`DriftVisitRouteRepository`), which is
/// what makes closing and reopening the app resume the same route instead
/// of silently creating a second one for the same day.
@freezed
abstract class VisitRoute with _$VisitRoute {
  const VisitRoute._();

  const factory VisitRoute({
    required String id,
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required DateTime date,
    required List<VisitRouteStop> stops,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VisitRoute;

  bool get isEmpty => stops.isEmpty;

  int get completedStopCount => stops.where((stop) => stop.isCompleted).length;

  bool get isCompleted =>
      stops.isNotEmpty && completedStopCount == stops.length;

  double get totalDistanceKm => stops.fold<double>(
    0,
    (total, stop) => total + (stop.distanceFromPreviousKm ?? 0),
  );

  int get totalEtaMinutes => stops.fold<int>(
    0,
    (total, stop) => total + (stop.etaMinutesFromPrevious ?? 0),
  );

  /// Normalizes an arbitrary [DateTime] to the UTC-midnight key this
  /// aggregate is scoped by, so a route "for today" always resolves to the
  /// same day regardless of the time of day it was built/looked up at.
  static DateTime dateKey(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}

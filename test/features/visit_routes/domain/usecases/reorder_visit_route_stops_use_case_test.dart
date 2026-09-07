import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('ReorderVisitRouteStopsUseCase (TASK-177)', () {
    VisitRouteStop stop(String id, int sequence) {
      return VisitRouteStop(
        customerId: id,
        displayName: 'Cliente $id',
        coordinates: GeoCoordinates.validated(
          latitude: sequence.toDouble(),
          longitude: 0,
        ),
        sequence: sequence,
      );
    }

    VisitRoute route(List<VisitRouteStop> stops) {
      final now = DateTime.utc(2026, 9, 7);
      return VisitRoute(
        id: 'route-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: now,
        stops: stops,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('applies the manual order and recomputes sequence/distance from the '
        'new adjacency', () async {
      final repository = _FakeVisitRouteRepository();
      final useCase = ReorderVisitRouteStopsUseCase(repository);
      final original = route(<VisitRouteStop>[
        stop('A', 0),
        stop('B', 1),
        stop('C', 2),
      ]);

      final result = await useCase(
        route: original,
        orderedCustomerIds: <String>['C', 'A', 'B'],
      );

      final updated = (result as AppSuccess<VisitRoute>).value;
      expect(updated.stops.map((stop) => stop.customerId), <String>[
        'C',
        'A',
        'B',
      ]);
      expect(updated.stops.map((stop) => stop.sequence), <int>[0, 1, 2]);
      // First stop after reorder has no "previous" to measure from.
      expect(updated.stops.first.distanceFromPreviousKm, isNull);
      expect(updated.stops[1].distanceFromPreviousKm, isNotNull);
      expect(repository.saved, hasLength(1));
    });

    test('rejects a reorder that does not carry exactly the same stops '
        '(never silently drops/adds a customer)', () async {
      final repository = _FakeVisitRouteRepository();
      final useCase = ReorderVisitRouteStopsUseCase(repository);
      final original = route(<VisitRouteStop>[stop('A', 0), stop('B', 1)]);

      final result = await useCase(
        route: original,
        orderedCustomerIds: <String>['A', 'C'],
      );

      expect(result, isA<AppFailure<VisitRoute>>());
      expect(
        (result as AppFailure<VisitRoute>).failure.code,
        'visit_route_reorder_invalid_permutation',
      );
      expect(repository.saved, isEmpty);
    });
  });
}

class _FakeVisitRouteRepository implements VisitRouteRepository {
  final saved = <VisitRoute>[];

  @override
  Future<AppResult<VisitRoute?>> getForDate({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required DateTime date,
  }) async {
    return const AppSuccess<VisitRoute?>(null);
  }

  @override
  Future<AppResult<VisitRoute>> save(VisitRoute route) async {
    saved.add(route);
    return AppSuccess<VisitRoute>(route);
  }
}

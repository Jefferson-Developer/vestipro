import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('MarkVisitRouteStopStatusUseCase (TASK-177)', () {
    VisitRoute buildRoute() {
      final now = DateTime.utc(2026, 9, 7);
      return VisitRoute(
        id: 'route-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: now,
        stops: <VisitRouteStop>[
          VisitRouteStop(
            customerId: 'A',
            displayName: 'Cliente A',
            coordinates: GeoCoordinates.validated(latitude: 1, longitude: 0),
            sequence: 0,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
    }

    test('flips a stop to completed and persists the update', () async {
      final repository = _FakeVisitRouteRepository();
      final useCase = MarkVisitRouteStopStatusUseCase(repository);

      final result = await useCase(
        route: buildRoute(),
        customerId: 'A',
        status: VisitRouteStopStatus.completed,
      );

      final updated = (result as AppSuccess<VisitRoute>).value;
      expect(updated.stops.single.status, VisitRouteStopStatus.completed);
      expect(updated.isCompleted, isTrue);
      expect(repository.saved, hasLength(1));
    });

    test('fails when the customer is not a stop of this route', () async {
      final repository = _FakeVisitRouteRepository();
      final useCase = MarkVisitRouteStopStatusUseCase(repository);

      final result = await useCase(
        route: buildRoute(),
        customerId: 'not-in-route',
        status: VisitRouteStopStatus.completed,
      );

      expect(result, isA<AppFailure<VisitRoute>>());
      expect(
        (result as AppFailure<VisitRoute>).failure.code,
        'visit_route_stop_not_found',
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

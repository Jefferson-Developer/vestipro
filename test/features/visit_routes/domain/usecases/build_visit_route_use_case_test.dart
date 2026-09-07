import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('BuildVisitRouteUseCase (TASK-177)', () {
    CustomerMapPin pin(String id, double latitude, double longitude) {
      return CustomerMapPin(
        customerId: id,
        displayName: 'Cliente $id',
        status: CustomerStatus.active,
        potential: null,
        lastPurchaseAt: null,
        coordinates: GeoCoordinates.validated(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    test(
      'builds and persists an optimized route for the selected pins',
      () async {
        final repository = _FakeVisitRouteRepository();
        final useCase = BuildVisitRouteUseCase(
          repository,
          const RouteOptimizationService(),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          salesRepId: 'rep-1',
          selectedPins: <CustomerMapPin>[pin('A', 1, 0), pin('B', 2, 0)],
          now: DateTime.utc(2026, 9, 7, 8),
        );

        expect(result, isA<AppSuccess<VisitRoute>>());
        final route = (result as AppSuccess<VisitRoute>).value;
        expect(route.organizationId, 'org-1');
        expect(route.companyId, 'company-1');
        expect(route.salesRepId, 'rep-1');
        expect(route.date, DateTime.utc(2026, 9, 7));
        expect(route.stops, hasLength(2));
        expect(repository.saved, hasLength(1));
        expect(repository.saved.single.id, route.id);
      },
    );

    test(
      'rebuilding for the same day always resolves to the same route id '
      '(so persistence upserts instead of accumulating a second route)',
      () async {
        final repository = _FakeVisitRouteRepository();
        final useCase = BuildVisitRouteUseCase(
          repository,
          const RouteOptimizationService(),
        );
        final now = DateTime.utc(2026, 9, 7, 8);

        final first = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          salesRepId: 'rep-1',
          selectedPins: <CustomerMapPin>[pin('A', 1, 0)],
          now: now,
        );
        final second = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          salesRepId: 'rep-1',
          selectedPins: <CustomerMapPin>[pin('A', 1, 0), pin('B', 2, 0)],
          now: now.add(const Duration(hours: 2)),
        );

        final firstRoute = (first as AppSuccess<VisitRoute>).value;
        final secondRoute = (second as AppSuccess<VisitRoute>).value;
        expect(secondRoute.id, firstRoute.id);
        expect(repository.saved, hasLength(2));
      },
    );

    test('propagates a validation failure without ever calling save', () async {
      final repository = _FakeVisitRouteRepository();
      final useCase = BuildVisitRouteUseCase(
        repository,
        const RouteOptimizationService(),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        selectedPins: const <CustomerMapPin>[],
      );

      expect(result, isA<AppFailure<VisitRoute>>());
      expect(
        (result as AppFailure<VisitRoute>).failure.code,
        'visit_route_empty_selection',
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

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/fake_analytics_service.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/visit_checkins/visit_checkins.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

/// Covers TASK-178's check-in wiring into `VisitRouteBloc`: evidence
/// registration success/failure and the route stop's progress update that
/// must follow a successful check-in (see `VisitRouteCheckInRequested`'s
/// doc for why the stop is only ever marked from here, not from
/// `CheckInVisitUseCase` itself).
void main() {
  group('VisitRouteBloc — VisitRouteCheckInRequested (TASK-178)', () {
    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    VisitRoute buildRoute({
      VisitRouteStopStatus status = VisitRouteStopStatus.pending,
    }) {
      final now = DateTime.utc(2026, 9, 7);
      return VisitRoute(
        id: 'route-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: now,
        stops: <VisitRouteStop>[
          VisitRouteStop(
            customerId: 'customer-1',
            displayName: 'Cliente A',
            coordinates: GeoCoordinates.validated(latitude: 1, longitude: 2),
            sequence: 0,
            status: status,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
    }

    CrmActivity buildActivity(DateTime occurredAt) {
      return CrmActivity(
        id: 'checkin-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        type: CrmActivityType.visit,
        customerId: 'customer-1',
        userId: 'rep-1',
        occurredAt: occurredAt,
        description: 'Check-in de visita.',
        createdAt: occurredAt,
        createdBy: 'rep-1',
        updatedAt: occurredAt,
        updatedBy: 'rep-1',
        version: 1,
        syncStatus: CrmActivitySyncStatus.pending,
      );
    }

    VisitRouteBloc buildBloc({
      required _FakeCheckInVisitUseCase checkInVisit,
      required _FakeVisitRouteRepository repository,
      FakeAnalyticsService? analyticsService,
    }) {
      return VisitRouteBloc(
        getActiveVisitRoute: GetActiveVisitRouteUseCase(repository),
        buildVisitRoute: BuildVisitRouteUseCase(
          repository,
          const RouteOptimizationService(),
        ),
        reorderVisitRouteStops: ReorderVisitRouteStopsUseCase(repository),
        markVisitRouteStopStatus: MarkVisitRouteStopStatusUseCase(repository),
        checkInVisit: checkInVisit,
        analyticsService: analyticsService ?? FakeAnalyticsService(),
      );
    }

    blocTest<VisitRouteBloc, VisitRouteState>(
      'marks the matching stop completed, stores the check-in outcome and '
      'logs the existing crmActivityCreated analytics event on success',
      build: () => buildBloc(
        checkInVisit: _FakeCheckInVisitUseCase(
          result: AppSuccess<VisitCheckInResult>(
            VisitCheckInResult(
              activity: buildActivity(DateTime.utc(2026, 9, 7, 10)),
              location: VisitCheckInLocationCapture.skippedByUser,
            ),
          ),
        ),
        repository: _FakeVisitRouteRepository(),
        analyticsService: analyticsService,
      ),
      seed: () => VisitRouteState(route: buildRoute()),
      act: (bloc) => bloc.add(
        const VisitRouteCheckInRequested(
          customerId: 'customer-1',
          note: 'Cliente confirmou pedido',
        ),
      ),
      expect: () => <Matcher>[
        predicate<VisitRouteState>(
          (state) => state.checkInStatus == VisitRouteCheckInStatus.submitting,
        ),
        predicate<VisitRouteState>(
          (state) =>
              state.checkInStatus == VisitRouteCheckInStatus.success &&
              state.lastCheckIn != null &&
              state.route!.stops.single.status ==
                  VisitRouteStopStatus.completed,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        final logged = analyticsService.loggedEvents.single;
        expect(logged.name, 'crm_activity_created');
        expect(logged.parameters?['customer_id'], 'customer-1');
        expect(logged.parameters?['activity_type'], 'visit');
      },
    );

    blocTest<VisitRouteBloc, VisitRouteState>(
      'reports a failure and leaves the stop untouched when the check-in '
      'evidence could not be registered',
      build: () => buildBloc(
        checkInVisit: _FakeCheckInVisitUseCase(
          result: const AppFailure<VisitCheckInResult>(
            UnexpectedFailure('boom', code: 'unexpected'),
          ),
        ),
        repository: _FakeVisitRouteRepository(),
      ),
      seed: () => VisitRouteState(route: buildRoute()),
      act: (bloc) =>
          bloc.add(const VisitRouteCheckInRequested(customerId: 'customer-1')),
      expect: () => <Matcher>[
        predicate<VisitRouteState>(
          (state) => state.checkInStatus == VisitRouteCheckInStatus.submitting,
        ),
        predicate<VisitRouteState>(
          (state) =>
              state.checkInStatus == VisitRouteCheckInStatus.failure &&
              state.route!.stops.single.status == VisitRouteStopStatus.pending,
        ),
      ],
    );

    blocTest<VisitRouteBloc, VisitRouteState>(
      'does nothing when there is no active route to check in against',
      build: () => buildBloc(
        checkInVisit: _FakeCheckInVisitUseCase(
          result: AppSuccess<VisitCheckInResult>(
            VisitCheckInResult(
              activity: buildActivity(DateTime.utc(2026, 9, 7, 10)),
              location: VisitCheckInLocationCapture.skippedByUser,
            ),
          ),
        ),
        repository: _FakeVisitRouteRepository(),
      ),
      seed: VisitRouteState.new,
      act: (bloc) =>
          bloc.add(const VisitRouteCheckInRequested(customerId: 'customer-1')),
      expect: () => const <VisitRouteState>[],
    );

    blocTest<VisitRouteBloc, VisitRouteState>(
      'does nothing when the customer is not a stop of the active route',
      build: () {
        final checkInVisit = _FakeCheckInVisitUseCase(
          result: AppSuccess<VisitCheckInResult>(
            VisitCheckInResult(
              activity: buildActivity(DateTime.utc(2026, 9, 7, 10)),
              location: VisitCheckInLocationCapture.skippedByUser,
            ),
          ),
        );
        return buildBloc(
          checkInVisit: checkInVisit,
          repository: _FakeVisitRouteRepository(),
        );
      },
      seed: () => VisitRouteState(route: buildRoute()),
      act: (bloc) => bloc.add(
        const VisitRouteCheckInRequested(customerId: 'not-in-route'),
      ),
      expect: () => const <VisitRouteState>[],
    );
  });
}

final class _FakeCheckInVisitUseCase implements CheckInVisitUseCase {
  _FakeCheckInVisitUseCase({required this.result});

  final AppResult<VisitCheckInResult> result;

  @override
  Future<AppResult<VisitCheckInResult>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String customerId,
    required String userId,
    String? note,
    bool shareLocation = false,
    GeoCoordinates? customerCoordinates,
    DateTime? now,
  }) async {
    return result;
  }
}

final class _FakeVisitRouteRepository implements VisitRouteRepository {
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

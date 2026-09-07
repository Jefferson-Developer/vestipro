import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../visit_checkins/domain/entities/visit_check_in_result.dart';
import '../../../visit_checkins/domain/usecases/check_in_visit_use_case.dart';
import '../../../visit_checkins/domain/value_objects/visit_check_in_location_status.dart';
import '../../domain/entities/visit_route.dart';
import '../../domain/usecases/build_visit_route_use_case.dart';
import '../../domain/usecases/get_active_visit_route_use_case.dart';
import '../../domain/usecases/mark_visit_route_stop_status_use_case.dart';
import '../../domain/usecases/reorder_visit_route_stops_use_case.dart';
import '../../domain/value_objects/visit_route_stop_status.dart';
import 'visit_route_event.dart';
import 'visit_route_state.dart';

@injectable
final class VisitRouteBloc extends Bloc<VisitRouteEvent, VisitRouteState> {
  VisitRouteBloc({
    required this.getActiveVisitRoute,
    required this.buildVisitRoute,
    required this.reorderVisitRouteStops,
    required this.markVisitRouteStopStatus,
    required this.checkInVisit,
    required this.analyticsService,
  }) : super(const VisitRouteState()) {
    on<VisitRouteStarted>(_onStarted);
    on<VisitRouteAvailablePinsChanged>(_onAvailablePinsChanged);
    on<VisitRouteCustomerSelectionToggled>(_onCustomerSelectionToggled);
    on<VisitRouteBuildRequested>(_onBuildRequested);
    on<VisitRouteStopsReordered>(_onStopsReordered);
    on<VisitRouteStopStatusToggled>(_onStopStatusToggled);
    on<VisitRouteCheckInRequested>(_onCheckInRequested);
    on<VisitRouteSelectionReopened>(_onSelectionReopened);
  }

  final GetActiveVisitRouteUseCase getActiveVisitRoute;
  final BuildVisitRouteUseCase buildVisitRoute;
  final ReorderVisitRouteStopsUseCase reorderVisitRouteStops;
  final MarkVisitRouteStopStatusUseCase markVisitRouteStopStatus;
  final CheckInVisitUseCase checkInVisit;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    VisitRouteStarted event,
    Emitter<VisitRouteState> emit,
  ) async {
    emit(
      state.copyWith(
        status: VisitRouteStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        salesRepId: event.salesRepId,
        clearFailure: true,
      ),
    );
    final result = await getActiveVisitRoute(
      organizationId: event.organizationId,
      companyId: event.companyId,
      salesRepId: event.salesRepId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<VisitRoute?>(value: final route):
        emit(
          state.copyWith(
            status: VisitRouteStatus.ready,
            route: route,
            clearRoute: route == null,
            clearFailure: true,
          ),
        );
      case AppFailure<VisitRoute?>(failure: final failure):
        emit(
          state.copyWith(status: VisitRouteStatus.failure, failure: failure),
        );
    }
  }

  void _onAvailablePinsChanged(
    VisitRouteAvailablePinsChanged event,
    Emitter<VisitRouteState> emit,
  ) {
    final availableCustomerIds = event.pins
        .map((pin) => pin.customerId)
        .toSet();
    emit(
      state.copyWith(
        availablePins: event.pins,
        // Drops any previously selected customer that no longer belongs to
        // the available (visible, geocoded) portfolio — e.g. a filter
        // changed underneath the selection.
        selectedCustomerIds: state.selectedCustomerIds
            .where(availableCustomerIds.contains)
            .toSet(),
      ),
    );
  }

  void _onCustomerSelectionToggled(
    VisitRouteCustomerSelectionToggled event,
    Emitter<VisitRouteState> emit,
  ) {
    final updated = Set<String>.of(state.selectedCustomerIds);
    if (!updated.remove(event.customerId)) {
      updated.add(event.customerId);
    }
    emit(state.copyWith(selectedCustomerIds: updated));
  }

  Future<void> _onBuildRequested(
    VisitRouteBuildRequested event,
    Emitter<VisitRouteState> emit,
  ) async {
    final selectedPins = state.availablePins
        .where((pin) => state.selectedCustomerIds.contains(pin.customerId))
        .toList(growable: false);
    emit(state.copyWith(status: VisitRouteStatus.loading, clearFailure: true));
    final result = await buildVisitRoute(
      organizationId: state.organizationId,
      companyId: state.companyId,
      salesRepId: state.salesRepId,
      selectedPins: selectedPins,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<VisitRoute>(value: final route):
        emit(
          state.copyWith(
            status: VisitRouteStatus.ready,
            route: route,
            clearFailure: true,
          ),
        );
      case AppFailure<VisitRoute>(failure: final failure):
        emit(state.copyWith(status: VisitRouteStatus.ready, failure: failure));
    }
  }

  Future<void> _onStopsReordered(
    VisitRouteStopsReordered event,
    Emitter<VisitRouteState> emit,
  ) async {
    final route = state.route;
    if (route == null) return;
    final result = await reorderVisitRouteStops(
      route: route,
      orderedCustomerIds: event.orderedCustomerIds,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<VisitRoute>(value: final updated):
        emit(state.copyWith(route: updated, clearFailure: true));
      case AppFailure<VisitRoute>(failure: final failure):
        emit(state.copyWith(failure: failure));
    }
  }

  /// Reverts an already-completed stop back to pending (correcting a
  /// mistake) — never produces a check-in itself. See
  /// `VisitRouteStopStatusToggled`'s doc.
  Future<void> _onStopStatusToggled(
    VisitRouteStopStatusToggled event,
    Emitter<VisitRouteState> emit,
  ) async {
    final route = state.route;
    if (route == null) return;
    final currentStop = route.stops.where(
      (stop) => stop.customerId == event.customerId,
    );
    if (currentStop.isEmpty || !currentStop.first.isCompleted) return;
    final result = await markVisitRouteStopStatus(
      route: route,
      customerId: event.customerId,
      status: VisitRouteStopStatus.pending,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<VisitRoute>(value: final updated):
        emit(state.copyWith(route: updated, clearFailure: true));
      case AppFailure<VisitRoute>(failure: final failure):
        emit(state.copyWith(failure: failure));
    }
  }

  /// Registers a real check-in for a pending stop (TASK-178): evidence +
  /// optional location via `CheckInVisitUseCase` (crm/visit_checkins only),
  /// then — only once that succeeds — marks the stop completed with this
  /// bloc's own `MarkVisitRouteStopStatusUseCase`, keeping `visit_checkins`
  /// free of any dependency on `visit_routes` (see that use case's doc).
  Future<void> _onCheckInRequested(
    VisitRouteCheckInRequested event,
    Emitter<VisitRouteState> emit,
  ) async {
    final route = state.route;
    if (route == null || state.isCheckingIn) return;
    final matchingStops = route.stops.where(
      (stop) => stop.customerId == event.customerId,
    );
    if (matchingStops.isEmpty) return;

    emit(
      state.copyWith(
        checkInStatus: VisitRouteCheckInStatus.submitting,
        clearCheckInFailure: true,
      ),
    );

    final result = await checkInVisit(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      companyId: state.companyId,
      customerId: event.customerId,
      userId: state.salesRepId,
      note: event.note,
      shareLocation: event.shareLocation,
      customerCoordinates: matchingStops.first.coordinates,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure<VisitCheckInResult>(failure: final failure):
        emit(
          state.copyWith(
            checkInStatus: VisitRouteCheckInStatus.failure,
            checkInFailure: failure,
          ),
        );
      case AppSuccess<VisitCheckInResult>(value: final checkIn):
        // Reuses TASK-059's existing `crmActivityCreated` taxonomy (same
        // event `CustomerDetailBloc` fires for any other CRM activity)
        // instead of introducing a new event name — a visit check-in *is*
        // a CRM activity, just created from a different entry point. Never
        // logs raw coordinates, only the location outcome's stable code.
        await analyticsService.logEvent(
          AnalyticsEvents.crmActivityCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'customer_id': event.customerId,
            'activity_id': checkIn.activity.id,
            'activity_type': checkIn.activity.type.analyticsCode,
            'sync_status': checkIn.activity.syncStatus.name,
            'location_status': checkIn.location.status.analyticsCode,
          },
        );
        if (emit.isDone) return;
        await _markStopVisited(route, event.customerId, checkIn, emit);
    }
  }

  Future<void> _markStopVisited(
    VisitRoute route,
    String customerId,
    VisitCheckInResult checkIn,
    Emitter<VisitRouteState> emit,
  ) async {
    final markResult = await markVisitRouteStopStatus(
      route: route,
      customerId: customerId,
      status: VisitRouteStopStatus.completed,
      now: checkIn.activity.occurredAt,
    );
    if (emit.isDone) return;
    switch (markResult) {
      case AppSuccess<VisitRoute>(value: final updated):
        emit(
          state.copyWith(
            route: updated,
            checkInStatus: VisitRouteCheckInStatus.success,
            lastCheckIn: checkIn,
            clearFailure: true,
          ),
        );
      case AppFailure<VisitRoute>(failure: final failure):
        // The check-in evidence was already registered successfully — a
        // failure marking the stop is reported without discarding that.
        emit(
          state.copyWith(
            checkInStatus: VisitRouteCheckInStatus.success,
            lastCheckIn: checkIn,
            failure: failure,
          ),
        );
    }
  }

  void _onSelectionReopened(
    VisitRouteSelectionReopened event,
    Emitter<VisitRouteState> emit,
  ) {
    emit(
      state.copyWith(clearRoute: true, selectedCustomerIds: const <String>{}),
    );
  }
}

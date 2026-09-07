import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
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
  }) : super(const VisitRouteState()) {
    on<VisitRouteStarted>(_onStarted);
    on<VisitRouteAvailablePinsChanged>(_onAvailablePinsChanged);
    on<VisitRouteCustomerSelectionToggled>(_onCustomerSelectionToggled);
    on<VisitRouteBuildRequested>(_onBuildRequested);
    on<VisitRouteStopsReordered>(_onStopsReordered);
    on<VisitRouteStopStatusToggled>(_onStopStatusToggled);
    on<VisitRouteSelectionReopened>(_onSelectionReopened);
  }

  final GetActiveVisitRouteUseCase getActiveVisitRoute;
  final BuildVisitRouteUseCase buildVisitRoute;
  final ReorderVisitRouteStopsUseCase reorderVisitRouteStops;
  final MarkVisitRouteStopStatusUseCase markVisitRouteStopStatus;

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

  Future<void> _onStopStatusToggled(
    VisitRouteStopStatusToggled event,
    Emitter<VisitRouteState> emit,
  ) async {
    final route = state.route;
    if (route == null) return;
    final currentStop = route.stops.where(
      (stop) => stop.customerId == event.customerId,
    );
    if (currentStop.isEmpty) return;
    final nextStatus = currentStop.first.isCompleted
        ? VisitRouteStopStatus.pending
        : VisitRouteStopStatus.completed;
    final result = await markVisitRouteStopStatus(
      route: route,
      customerId: event.customerId,
      status: nextStatus,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<VisitRoute>(value: final updated):
        emit(state.copyWith(route: updated, clearFailure: true));
      case AppFailure<VisitRoute>(failure: final failure):
        emit(state.copyWith(failure: failure));
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

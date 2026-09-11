import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/usecases/fulfillment_use_cases.dart';
import '../../domain/value_objects/logistics_issue_type.dart';
import 'order_fulfillment_state.dart';

/// Drives the pedido's own rastreio logístico section (TASK-214, EPIC-32):
/// lists every `Shipment` opened for the pedido and watches the most recent
/// one's tracking history and ocorrências in real time, plus lets an
/// authorized vendedor/gestor report/resolve a `LogisticsIssue` — reusing
/// the exact same [FulfillmentRepository] contract both the seller-facing
/// `OrderHistoryPage` and, indirectly (masked/scoped read), the customer
/// portal snapshot rely on.
@injectable
final class OrderFulfillmentCubit extends Cubit<OrderFulfillmentState> {
  OrderFulfillmentCubit(
    this._watchShipmentsForOrder,
    this._watchTrackingEvents,
    this._watchLogisticsIssues,
    this._registerLogisticsIssue,
    this._resolveLogisticsIssue,
    this._analyticsService,
  ) : super(const OrderFulfillmentState());

  final WatchShipmentsForOrderUseCase _watchShipmentsForOrder;
  final WatchTrackingEventsUseCase _watchTrackingEvents;
  final WatchLogisticsIssuesUseCase _watchLogisticsIssues;
  final RegisterLogisticsIssueUseCase _registerLogisticsIssue;
  final ResolveLogisticsIssueUseCase _resolveLogisticsIssue;
  final AnalyticsService _analyticsService;

  StreamSubscription<dynamic>? _shipmentsSubscription;
  StreamSubscription<dynamic>? _trackingEventsSubscription;
  StreamSubscription<dynamic>? _logisticsIssuesSubscription;
  String? _selectedShipmentId;
  String? _organizationId;
  String? _orderId;

  Future<void> watch({
    required String organizationId,
    required String orderId,
  }) async {
    _organizationId = organizationId;
    _orderId = orderId;
    emit(state.copyWith(status: OrderFulfillmentStatus.loading));

    await _shipmentsSubscription?.cancel();
    _shipmentsSubscription =
        _watchShipmentsForOrder(
          organizationId: organizationId,
          orderId: orderId,
        ).listen((result) {
          result.fold(
            onSuccess: (shipments) {
              emit(
                state.copyWith(
                  status: OrderFulfillmentStatus.ready,
                  shipments: shipments,
                  clearFailureMessage: true,
                ),
              );
              final latestShipmentId = shipments.isEmpty
                  ? null
                  : shipments.last.id;
              if (latestShipmentId != _selectedShipmentId) {
                _selectedShipmentId = latestShipmentId;
                _watchSelectedShipmentDetails(organizationId, latestShipmentId);
              }
            },
            onFailure: (failure) => emit(
              state.copyWith(
                status: OrderFulfillmentStatus.failure,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  void _watchSelectedShipmentDetails(
    String organizationId,
    String? shipmentId,
  ) {
    unawaited(_trackingEventsSubscription?.cancel());
    unawaited(_logisticsIssuesSubscription?.cancel());
    if (shipmentId == null) {
      emit(state.copyWith(trackingEvents: const [], logisticsIssues: const []));
      return;
    }

    _trackingEventsSubscription =
        _watchTrackingEvents(
          organizationId: organizationId,
          shipmentId: shipmentId,
        ).listen((result) {
          result.fold(
            onSuccess: (events) => emit(state.copyWith(trackingEvents: events)),
            onFailure: (_) {},
          );
        });

    _logisticsIssuesSubscription =
        _watchLogisticsIssues(
          organizationId: organizationId,
          shipmentId: shipmentId,
        ).listen((result) {
          result.fold(
            onSuccess: (issues) =>
                emit(state.copyWith(logisticsIssues: issues)),
            onFailure: (_) {},
          );
        });
  }

  /// Opens a new `LogisticsIssue`/ocorrência for the currently selected
  /// shipment — no-op (returns without emitting) when there is no shipment
  /// selected yet, since there would be nothing to attach it to.
  Future<void> reportIssue({
    required String companyId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) async {
    final organizationId = _organizationId;
    final orderId = _orderId;
    final shipment = state.selectedShipment;
    if (organizationId == null || orderId == null || shipment == null) return;

    emit(
      state.copyWith(isSubmittingIssue: true, clearIssueFailureMessage: true),
    );

    final logisticsIssueId = const Uuid().v4();
    final result = await _registerLogisticsIssue(
      organizationId: organizationId,
      companyId: companyId,
      shipmentId: shipment.id,
      logisticsIssueId: logisticsIssueId,
      type: type,
      description: description,
      responsibleUserId: responsibleUserId,
      nextAction: nextAction,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            isSubmittingIssue: false,
            lastRegisteredIssueId: logisticsIssueId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.logisticsIssueRegistered,
            parameters: <String, Object?>{
              'order_id': orderId,
              'issue_type': type.code,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          isSubmittingIssue: false,
          issueFailureMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> resolveIssue({
    required String logisticsIssueId,
    required LogisticsIssueType type,
    String? resolutionNote,
  }) async {
    final organizationId = _organizationId;
    final orderId = _orderId;
    final shipment = state.selectedShipment;
    if (organizationId == null || orderId == null || shipment == null) return;

    emit(
      state.copyWith(isSubmittingIssue: true, clearIssueFailureMessage: true),
    );

    final result = await _resolveLogisticsIssue(
      organizationId: organizationId,
      shipmentId: shipment.id,
      logisticsIssueId: logisticsIssueId,
      resolved: true,
      resolutionNote: resolutionNote,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            isSubmittingIssue: false,
            lastResolvedIssueId: logisticsIssueId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.logisticsIssueResolved,
            parameters: <String, Object?>{
              'order_id': orderId,
              'issue_type': type.code,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          isSubmittingIssue: false,
          issueFailureMessage: failure.message,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_shipmentsSubscription?.cancel());
    unawaited(_trackingEventsSubscription?.cancel());
    unawaited(_logisticsIssuesSubscription?.cancel());
    return super.close();
  }
}

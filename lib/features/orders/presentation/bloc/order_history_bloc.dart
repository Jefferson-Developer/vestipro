import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent every other Orders
// bloc already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_order_by_id_use_case.dart';
import 'order_history_event.dart';
import 'order_history_state.dart';

/// Drives the pedido history/detail screen (TASK-104): a single, read-only
/// fetch of one Order through [GetOrderByIdUseCase] — the same RBAC-scoped
/// (`Capability.orderView` + `OrderVisibilityService`) read the pedidos
/// listing screen's own row action opens this from.
@injectable
final class OrderHistoryBloc
    extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc({required this.getOrderById, required this.analyticsService})
    : super(const OrderHistoryState()) {
    on<OrderHistoryStarted>(_onStarted);
    on<OrderHistoryRetried>(_onRetried);
  }

  final GetOrderByIdUseCase getOrderById;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    OrderHistoryStarted event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(
      OrderHistoryState(
        loadStatus: OrderHistoryLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        orderId: event.orderId,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    OrderHistoryRetried event,
    Emitter<OrderHistoryState> emit,
  ) async {
    if (state.orderId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: OrderHistoryLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<OrderHistoryState> emit) async {
    final result = await getOrderById(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      orderId: state.orderId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Order>(value: final order):
        emit(
          state.copyWith(
            loadStatus: OrderHistoryLoadStatus.ready,
            order: order,
            clearFailure: true,
          ),
        );
        await analyticsService.logEvent(
          AnalyticsEvents.orderHistoryViewed,
          parameters: <String, Object?>{
            'organization_id': order.organizationId,
            'company_id': order.companyId,
            'order_id': order.id,
            'status': order.status.name,
            'status_history_count': order.statusHistory.length,
          },
        );
      case AppFailure<Order>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: OrderHistoryLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_order_draft_use_case.dart';
import '../../domain/usecases/save_order_draft_use_case.dart';
import '../../domain/usecases/start_order_draft_for_customer_use_case.dart';
import 'order_draft_event.dart';
import 'order_draft_state.dart';

/// Owns the full lifecycle of a "novo pedido" draft (EPIC-13, TASK-096):
/// picking a customer, starting/persisting the resulting `Order` (fully
/// offline) and debounced autosave of further edits (notes today; item/
/// quantity edits join in later EPIC-13 tasks through the same
/// [OrderDraftNotesChanged]-like shape).
///
/// No event handler here ever calls Firestore/Storage — every dependency is
/// either a pure-local use case (`OrderDraftRepository` is Drift-backed) or
/// a read-only lookup already required to resolve who the customer/defaults
/// are (`GetCustomerByIdUseCase`, portfolio visibility, Price
/// List/Payment Term/Branch reads) — TASK-096 explicitly requires that
/// starting or editing a draft never depends on connectivity.
@injectable
final class OrderDraftBloc extends Bloc<OrderDraftEvent, OrderDraftState> {
  OrderDraftBloc({
    required this.getOrderDraft,
    required this.startOrderDraftForCustomer,
    required this.saveOrderDraft,
    required this.analyticsService,
  }) : super(const OrderDraftState()) {
    on<OrderDraftStarted>(_onStarted, transformer: restartable());
    on<OrderDraftCustomerSelected>(
      _onCustomerSelected,
      transformer: droppable(),
    );
    on<OrderDraftNotesChanged>(_onNotesChanged, transformer: sequential());
    on<OrderDraftAutoSaved>(_onAutoSaved, transformer: sequential());
    on<OrderDraftAutoSaveRetried>(_onAutoSaveRetried, transformer: droppable());
  }

  /// How long `OrderDraftNotesChanged` waits before persisting, mirroring
  /// `CustomerPortfolioBloc.searchDebounce`'s same token-based pattern.
  static const autoSaveDebounce = Duration(milliseconds: 500);

  final GetOrderDraftUseCase getOrderDraft;
  final StartOrderDraftForCustomerUseCase startOrderDraftForCustomer;
  final SaveOrderDraftUseCase saveOrderDraft;
  final AnalyticsService analyticsService;

  final Uuid _uuid = const Uuid();
  Timer? _autoSaveTimer;
  int _autoSaveToken = 0;

  Future<void> _onStarted(
    OrderDraftStarted event,
    Emitter<OrderDraftState> emit,
  ) async {
    emit(
      OrderDraftState(
        loadStatus: OrderDraftLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        sellerId: event.sellerId,
      ),
    );

    final draftId = event.draftId?.trim();
    if (draftId == null || draftId.isEmpty) {
      emit(
        state.copyWith(
          loadStatus: OrderDraftLoadStatus.awaitingCustomer,
          clearFailure: true,
        ),
      );
      return;
    }

    final result = await getOrderDraft(
      organizationId: event.organizationId,
      companyId: event.companyId,
      id: draftId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Order?>(value: final order):
        if (order == null || order.sellerId != event.sellerId) {
          // Either the draft no longer exists locally, or it belongs to a
          // different seller — both fall back to starting a fresh pick
          // instead of silently exposing someone else's draft.
          emit(
            state.copyWith(
              loadStatus: OrderDraftLoadStatus.awaitingCustomer,
              clearFailure: true,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            loadStatus: OrderDraftLoadStatus.ready,
            order: order,
            clearFailure: true,
          ),
        );
      case AppFailure<Order?>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: OrderDraftLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onCustomerSelected(
    OrderDraftCustomerSelected event,
    Emitter<OrderDraftState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: OrderDraftLoadStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await startOrderDraftForCustomer(
      id: state.order?.id ?? _uuid.v4(),
      organizationId: state.organizationId,
      companyId: state.companyId,
      sellerId: state.sellerId,
      customerId: event.customer.id,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Order>(value: final order):
        await analyticsService.logEvent(
          AnalyticsEvents.orderCreated,
          parameters: <String, Object?>{
            'organization_id': order.organizationId,
            'company_id': order.companyId,
            'order_id': order.id,
            'customer_id': order.customerId,
            'status': order.status.name,
            'sync_status': order.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            loadStatus: OrderDraftLoadStatus.ready,
            order: order,
            saveStatus: OrderDraftSaveStatus.saved,
            clearFailure: true,
          ),
        );
      case AppFailure<Order>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: OrderDraftLoadStatus.awaitingCustomer,
            failure: failure,
          ),
        );
    }
  }

  void _onNotesChanged(
    OrderDraftNotesChanged event,
    Emitter<OrderDraftState> emit,
  ) {
    final order = state.order;
    if (order == null) return;

    final trimmed = event.notes.trim();
    final updated = order.copyWith(notes: trimmed.isEmpty ? null : trimmed);
    emit(
      state.copyWith(
        order: updated,
        saveStatus: OrderDraftSaveStatus.idle,
        clearFailure: true,
      ),
    );
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    final token = ++_autoSaveToken;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(autoSaveDebounce, () {
      if (!isClosed) add(OrderDraftAutoSaved(token));
    });
  }

  Future<void> _onAutoSaved(
    OrderDraftAutoSaved event,
    Emitter<OrderDraftState> emit,
  ) async {
    if (event.token != _autoSaveToken) return;
    await _persist(emit);
  }

  Future<void> _onAutoSaveRetried(
    OrderDraftAutoSaveRetried event,
    Emitter<OrderDraftState> emit,
  ) async {
    await _persist(emit);
  }

  Future<void> _persist(Emitter<OrderDraftState> emit) async {
    final order = state.order;
    if (order == null) return;

    emit(
      state.copyWith(
        saveStatus: OrderDraftSaveStatus.saving,
        clearFailure: true,
      ),
    );
    final versioned = order.copyWith(
      updatedAt: DateTime.now().toUtc(),
      version: order.version + 1,
    );
    final result = await saveOrderDraft(order: versioned);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<void>():
        emit(
          state.copyWith(
            order: versioned,
            saveStatus: OrderDraftSaveStatus.saved,
            clearFailure: true,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: OrderDraftSaveStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
}

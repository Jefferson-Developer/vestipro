import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../pricing/domain/usecases/resolve_price_for_variant_use_case.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_product_by_id_use_case.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/services/order_item_editor.dart';
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
    this.getProductById,
    this.resolvePriceForVariant,
  }) : super(const OrderDraftState()) {
    on<OrderDraftStarted>(_onStarted, transformer: restartable());
    on<OrderDraftCustomerSelected>(
      _onCustomerSelected,
      transformer: droppable(),
    );
    on<OrderDraftNotesChanged>(_onNotesChanged, transformer: sequential());
    on<OrderDraftItemQuantityChanged>(
      _onItemQuantityChanged,
      transformer: sequential(),
    );
    on<OrderDraftItemRemoved>(_onItemRemoved, transformer: sequential());
    on<OrderDraftItemVariantQuantityChanged>(
      _onItemVariantQuantityChanged,
      transformer: sequential(),
    );
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

  /// Resolves the display-only `Product` name behind each item's
  /// denormalized `productId` (TASK-097's items list) — optional, mirroring
  /// `ProductDetailBloc.resolvePriceForVariant`'s own precedent for a
  /// read-only lookup that degrades to raw ids instead of ever blocking the
  /// draft screen when it is not wired.
  final GetProductByIdUseCase? getProductById;

  /// Resolves the price of a variant not yet on the draft when a grid cell
  /// is filled for the first time (`OrderItemsGrid`, TASK-098) — the exact
  /// same pricing engine already used to add products via the catalog
  /// (TASK-097/TASK-088), never a guessed or copied price. Optional, same
  /// precedent [getProductById] already sets: a missing dependency simply
  /// keeps the grid read-only for brand new variants instead of ever
  /// blocking the draft screen.
  final ResolvePriceForVariantUseCase? resolvePriceForVariant;

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
        await _resolveProductNames(emit, order);
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

  /// Edits the quantity of an item already on the draft, straight from the
  /// items list (TASK-097) — a quantity of zero or less removes the line,
  /// same convention [OrderItemEditor.withUpdatedQuantity] documents.
  void _onItemQuantityChanged(
    OrderDraftItemQuantityChanged event,
    Emitter<OrderDraftState> emit,
  ) {
    final order = state.order;
    if (order == null) return;

    final updatedItems = OrderItemEditor.withUpdatedQuantity(
      order.items,
      itemId: event.itemId,
      quantity: event.quantity,
    );
    emit(
      state.copyWith(
        order: order.copyWith(items: updatedItems),
        saveStatus: OrderDraftSaveStatus.idle,
        clearFailure: true,
      ),
    );
    _scheduleAutoSave();
  }

  /// Removes an item already on the draft, straight from the items list
  /// (TASK-097).
  void _onItemRemoved(
    OrderDraftItemRemoved event,
    Emitter<OrderDraftState> emit,
  ) {
    final order = state.order;
    if (order == null) return;

    final updatedItems = OrderItemEditor.withRemovedItem(
      order.items,
      itemId: event.itemId,
    );
    emit(
      state.copyWith(
        order: order.copyWith(items: updatedItems),
        saveStatus: OrderDraftSaveStatus.idle,
        clearFailure: true,
      ),
    );
    _scheduleAutoSave();
  }

  /// Handles a color x size grid cell edit (`OrderItemsGrid`, TASK-098).
  /// [event.variantId] matching an item already on the draft updates its
  /// quantity exactly like [_onItemQuantityChanged] (matched by variant
  /// instead of item id, same "0 means gone" convention). A variant not yet
  /// on the draft only ever gets a brand new item once its price is freshly
  /// resolved through [resolvePriceForVariant] — a quantity of zero for a
  /// variant not on the draft is simply a no-op (there is nothing to
  /// remove), and a variant whose price cannot be resolved never gets a
  /// guessed or zero price silently: the failure is surfaced through
  /// [OrderDraftState.failure] instead.
  Future<void> _onItemVariantQuantityChanged(
    OrderDraftItemVariantQuantityChanged event,
    Emitter<OrderDraftState> emit,
  ) async {
    final order = state.order;
    if (order == null) return;

    final existing = order.items.firstWhereOrNull(
      (item) => item.variantId == event.variantId,
    );
    if (existing != null) {
      final updatedItems = OrderItemEditor.withUpdatedQuantity(
        order.items,
        itemId: existing.id,
        quantity: event.quantity,
      );
      emit(
        state.copyWith(
          order: order.copyWith(items: updatedItems),
          saveStatus: OrderDraftSaveStatus.idle,
          clearFailure: true,
        ),
      );
      _scheduleAutoSave();
      return;
    }

    if (event.quantity <= 0) return;

    final resolvePriceForVariant = this.resolvePriceForVariant;
    if (resolvePriceForVariant == null) return;

    final priceResult = await resolvePriceForVariant(
      organizationId: order.organizationId,
      companyId: order.companyId,
      productId: event.productId,
      variantId: event.variantId,
    );
    if (emit.isDone) return;
    switch (priceResult) {
      case AppSuccess<ResolvedVariantPrice>(value: final resolved):
        if (!resolved.hasPrice) {
          emit(
            state.copyWith(
              failure: const ValidationFailure(
                'Não há preço disponível para esta variante.',
                code: 'order_draft_variant_price_unavailable',
              ),
            ),
          );
          return;
        }
        final price = resolved.price!;
        final newItem = OrderItem(
          id: _uuid.v4(),
          variantId: event.variantId,
          productId: event.productId,
          quantity: event.quantity,
          unitPrice: price,
          subtotal: event.quantity * price,
        );
        final updatedItems = OrderItemEditor.withAddedItems(
          order.items,
          <OrderItem>[newItem],
        );
        emit(
          state.copyWith(
            order: order.copyWith(items: updatedItems),
            saveStatus: OrderDraftSaveStatus.idle,
            clearFailure: true,
          ),
        );
        _scheduleAutoSave();
        await analyticsService.logEvent(
          AnalyticsEvents.productAddedToOrder,
          parameters: <String, Object?>{
            'organization_id': order.organizationId,
            'company_id': order.companyId,
            'order_id': order.id,
            'product_id': event.productId,
            'variant_id': event.variantId,
            'quantity': event.quantity,
            'source': 'order_items_grid',
          },
        );
      case AppFailure<ResolvedVariantPrice>(failure: final failure):
        emit(state.copyWith(failure: failure));
    }
  }

  /// Fetches the display-only `Product` behind every item's `productId` not
  /// already cached in [OrderDraftState.productsById] (TASK-097's items
  /// list) — a read-only lookup that never blocks or fails the draft screen:
  /// a product that fails to resolve simply keeps showing its raw id (see
  /// `OrderDraftState.productNameFor`).
  Future<void> _resolveProductNames(
    Emitter<OrderDraftState> emit,
    Order order,
  ) async {
    final getProductById = this.getProductById;
    if (getProductById == null || order.items.isEmpty) return;

    final missingProductIds = <String>{
      for (final item in order.items)
        if (!state.productsById.containsKey(item.productId)) item.productId,
    };
    if (missingProductIds.isEmpty) return;

    final resolved = Map<String, Product>.of(state.productsById);
    for (final productId in missingProductIds) {
      final result = await getProductById(
        organizationId: order.organizationId,
        id: productId,
      );
      if (result case AppSuccess<Product>(value: final product)) {
        resolved[productId] = product;
      }
    }
    if (emit.isDone) return;
    emit(
      state.copyWith(productsById: Map<String, Product>.unmodifiable(resolved)),
    );
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

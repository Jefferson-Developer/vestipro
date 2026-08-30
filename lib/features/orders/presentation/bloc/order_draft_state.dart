import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_draft_defaults.dart';

/// Load lifecycle of the "novo pedido" screen (EPIC-13, TASK-096).
enum OrderDraftLoadStatus {
  /// Nothing requested yet.
  initial,

  /// Resolving whether to resume an existing draft or start empty.
  loading,

  /// No `Order` exists yet for this session — the seller still has to pick
  /// a customer from their carteira.
  awaitingCustomer,

  /// An `Order` draft exists in [OrderDraftState.order] and is ready to be
  /// shown/edited.
  ready,

  /// Starting/resuming the draft failed — never silent, always surfaced
  /// through [OrderDraftState.failure].
  failure,
}

/// Autosave lifecycle for the current [OrderDraftState.order] edit.
enum OrderDraftSaveStatus { idle, saving, saved, failure }

/// State of `OrderDraftBloc` (EPIC-13, TASK-096).
final class OrderDraftState {
  const OrderDraftState({
    this.loadStatus = OrderDraftLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.sellerId = '',
    this.order,
    this.defaults,
    this.saveStatus = OrderDraftSaveStatus.idle,
    this.failure,
    this.productsById = const <String, Product>{},
  });

  final OrderDraftLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String sellerId;
  final Order? order;

  /// Human-readable unidade/tabela de preço/condição de pagamento the
  /// current [order] was pre-filled with, kept only in memory right after
  /// `OrderDraftCustomerSelected` succeeds — never persisted and always
  /// `null` again once a draft is resumed from [OrderDraftStarted] with a
  /// `draftId` (the UI falls back to showing the order's raw ids then).
  final OrderDraftDefaults? defaults;
  final OrderDraftSaveStatus saveStatus;
  final Failure? failure;

  /// Display-only cache of the `Product` behind each `OrderItem.productId`
  /// currently on [order] (TASK-097's items list) — never authoritative for
  /// price/availability/business rules, just a name to show instead of a raw
  /// id. Missing an entry (fetch failed, or not resolved yet) falls back to
  /// the raw id in the UI, never blocking the items list itself.
  final Map<String, Product> productsById;

  bool get isLoading => loadStatus == OrderDraftLoadStatus.loading;

  bool get isReady => loadStatus == OrderDraftLoadStatus.ready && order != null;

  bool get isSaving => saveStatus == OrderDraftSaveStatus.saving;

  /// Display name for [productId], falling back to the raw id when it was
  /// not resolved (see [productsById]'s own doc).
  String productNameFor(String productId) =>
      productsById[productId]?.name ?? productId;

  OrderDraftState copyWith({
    OrderDraftLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? sellerId,
    Order? order,
    OrderDraftDefaults? defaults,
    bool clearDefaults = false,
    OrderDraftSaveStatus? saveStatus,
    Failure? failure,
    bool clearFailure = false,
    Map<String, Product>? productsById,
  }) {
    return OrderDraftState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      sellerId: sellerId ?? this.sellerId,
      order: order ?? this.order,
      defaults: clearDefaults ? null : (defaults ?? this.defaults),
      saveStatus: saveStatus ?? this.saveStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
      productsById: productsById ?? this.productsById,
    );
  }
}

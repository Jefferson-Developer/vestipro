import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_order_draft_use_case.dart';
import 'order_items_counter_state.dart';

/// Backs the "produtos no pedido atual" indicator shown while browsing the
/// catalog from inside the "novo pedido" flow (TASK-097, EPIC-13, B2B
/// wording — never "carrinho"/"sacola" e-commerce terms).
///
/// Deliberately its own read-only cubit instead of sharing
/// `OrderDraftBloc`'s instance: the catalog picking flow (grid/detail) lives
/// on different routes than the draft summary screen, each with their own
/// widget tree, so this simply reloads the draft's `Order.itemCount` fresh
/// every time [load] is called — every catalog screen the seller lands on
/// while adding products calls it again, keeping the badge honest even
/// though items are actually persisted by `AddItemsToOrderDraftUseCase`
/// (a different call path than this cubit's own read).
@injectable
final class OrderItemsCounterCubit extends Cubit<OrderItemsCounterState> {
  OrderItemsCounterCubit(this._getOrderDraft)
    : super(const OrderItemsCounterState());

  final GetOrderDraftUseCase _getOrderDraft;

  Future<void> load({
    required String organizationId,
    required String companyId,
    required String draftId,
  }) async {
    emit(
      state.copyWith(
        status: OrderItemsCounterStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _getOrderDraft(
      organizationId: organizationId,
      companyId: companyId,
      id: draftId,
    );
    switch (result) {
      case AppSuccess<Order?>(value: final order):
        emit(
          state.copyWith(
            status: OrderItemsCounterStatus.ready,
            itemCount: order?.itemCount ?? 0,
            clearFailure: true,
          ),
        );
      case AppFailure<Order?>(failure: final failure):
        emit(
          state.copyWith(
            status: OrderItemsCounterStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

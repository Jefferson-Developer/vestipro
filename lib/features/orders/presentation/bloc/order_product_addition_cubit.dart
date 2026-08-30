import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/usecases/add_items_to_order_draft_use_case.dart';
import 'order_product_addition_state.dart';

/// Persists the variants/quantities the seller picked on the catalog's
/// product detail screen (`ProductDetailPage.onAddToOrder`, TASK-097) into
/// an existing `Order` draft, fully offline, through
/// `AddItemsToOrderDraftUseCase`.
///
/// Deliberately its own cubit (not `OrderDraftBloc` itself): the catalog
/// picking flow lives on a different route/widget tree than the draft
/// summary screen, so there is no live `OrderDraftBloc` instance to dispatch
/// into here — the hosting page instead reloads the draft
/// (`OrderDraftStarted(draftId: ...)`) once it is back in view.
@injectable
final class OrderProductAdditionCubit extends Cubit<OrderProductAdditionState> {
  OrderProductAdditionCubit(this._addItemsToOrderDraft)
    : super(const OrderProductAdditionState());

  final AddItemsToOrderDraftUseCase _addItemsToOrderDraft;

  Future<void> add({
    required String organizationId,
    required String companyId,
    required String draftId,
    required List<OrderItem> items,
  }) async {
    emit(
      state.copyWith(
        status: OrderProductAdditionStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await _addItemsToOrderDraft(
      organizationId: organizationId,
      companyId: companyId,
      draftId: draftId,
      items: items,
    );
    switch (result) {
      case AppSuccess<Order>():
        emit(
          state.copyWith(
            status: OrderProductAdditionStatus.success,
            clearFailure: true,
          ),
        );
      case AppFailure<Order>(failure: final failure):
        emit(
          state.copyWith(
            status: OrderProductAdditionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

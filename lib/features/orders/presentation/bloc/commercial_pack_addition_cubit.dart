import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderDraftBloc`/`OrderProductAdditionCubit` already follow.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../../commercial_packs/domain/entities/commercial_pack.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/usecases/add_items_to_order_draft_use_case.dart';
import '../../domain/usecases/expand_commercial_pack_to_order_items_use_case.dart';
import 'commercial_pack_addition_state.dart';

/// Persists a kit/pacote/sortimento the seller picked on the pack
/// picker/composition sheet (TASK-208, EPIC-32) into an existing `Order`
/// draft, fully offline: expands [pack] into its component `OrderItem`s
/// (`ExpandCommercialPackToOrderItemsUseCase`) and merges them into the
/// draft (`AddItemsToOrderDraftUseCase`) — the very same two steps
/// `OrderProductAdditionCubit` already performs for a plain catalog pick,
/// just with an extra expansion step in front.
///
/// Deliberately its own cubit (not `OrderDraftBloc` itself), mirroring
/// `OrderProductAdditionCubit`'s own precedent exactly: the pack picking
/// flow lives on a different route/widget tree than the draft summary
/// screen, so the hosting page reloads the draft
/// (`OrderDraftStarted(draftId: ...)`) once it is back in view instead of
/// dispatching into a live `OrderDraftBloc` instance here.
@injectable
final class CommercialPackAdditionCubit
    extends Cubit<CommercialPackAdditionState> {
  CommercialPackAdditionCubit(
    this._expandCommercialPackToOrderItems,
    this._addItemsToOrderDraft,
  ) : super(const CommercialPackAdditionState());

  final ExpandCommercialPackToOrderItemsUseCase
  _expandCommercialPackToOrderItems;
  final AddItemsToOrderDraftUseCase _addItemsToOrderDraft;

  Future<void> add({
    required String organizationId,
    required String companyId,
    required String draftId,
    required CommercialPack pack,
    String? customerChannel,
    String? customerSegment,
    Map<String, int>? quantityOverridesByComponent,
    int? totalGridQuantity,
  }) async {
    emit(
      state.copyWith(
        status: CommercialPackAdditionStatus.submitting,
        clearFailure: true,
      ),
    );

    final expansionResult = await _expandCommercialPackToOrderItems(
      pack: pack,
      organizationId: organizationId,
      companyId: companyId,
      customerChannel: customerChannel,
      customerSegment: customerSegment,
      quantityOverridesByComponent: quantityOverridesByComponent,
      totalGridQuantity: totalGridQuantity,
    );
    if (expansionResult case AppFailure<List<OrderItem>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: CommercialPackAdditionStatus.failure,
          failure: failure,
        ),
      );
      return;
    }
    final items = (expansionResult as AppSuccess<List<OrderItem>>).value;

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
            status: CommercialPackAdditionStatus.success,
            clearFailure: true,
          ),
        );
      case AppFailure<Order>(failure: final failure):
        emit(
          state.copyWith(
            status: CommercialPackAdditionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

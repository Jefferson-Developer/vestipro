import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_duplication_result.dart';
import '../../domain/usecases/duplicate_order_use_case.dart';
import 'order_duplication_state.dart';

/// Drives "Repetir pedido" (TASK-104), straight from the pedido history
/// screen: mints the new draft's id (same `Uuid().v4()` convention
/// `OrderDraftBloc` already uses for every id it generates locally) and
/// delegates every business rule — revalidação de preço/disponibilidade,
/// "nunca herda status/histórico" — to [DuplicateOrderUseCase].
@injectable
final class OrderDuplicationCubit extends Cubit<OrderDuplicationState> {
  OrderDuplicationCubit(this._duplicateOrder, this._analyticsService)
    : super(const OrderDuplicationState());

  final DuplicateOrderUseCase _duplicateOrder;
  final AnalyticsService _analyticsService;

  final Uuid _uuid = const Uuid();

  Future<void> duplicate({
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String sourceOrderId,
  }) async {
    emit(
      state.copyWith(
        status: OrderDuplicationStatus.submitting,
        clearFailure: true,
      ),
    );
    final result = await _duplicateOrder(
      organizationId: organizationId,
      companyId: companyId,
      sellerId: sellerId,
      sourceOrderId: sourceOrderId,
      newDraftId: _uuid.v4(),
    );
    switch (result) {
      case AppSuccess<OrderDuplicationResult>(value: final duplication):
        emit(
          state.copyWith(
            status: OrderDuplicationStatus.success,
            result: duplication,
            clearFailure: true,
          ),
        );
        await _analyticsService.logEvent(
          AnalyticsEvents.orderDuplicated,
          parameters: <String, Object?>{
            'organization_id': organizationId,
            'company_id': companyId,
            'source_order_id': sourceOrderId,
            'new_order_id': duplication.draft.id,
            'items_count': duplication.draft.itemCount,
            'price_changes_count': duplication.priceChanges.length,
            'issues_count': duplication.issues.length,
          },
        );
      case AppFailure<OrderDuplicationResult>(failure: final failure):
        emit(
          state.copyWith(
            status: OrderDuplicationStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

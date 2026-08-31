import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderDraftBloc`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../domain/entities/order.dart';
import '../../domain/entities/order_pricing_summary.dart';
import '../../domain/services/order_submission_validator.dart';
import '../../domain/usecases/get_order_submission_context_use_case.dart';
import 'order_submission_validation_state.dart';

/// Owns the "novo pedido" screen's pre-submit pendencies panel (EPIC-13,
/// TASK-100): every time [evaluate] runs for the draft's current `Order`
/// (and whatever `OrderPricingSummary` the commercial summary card already
/// resolved), it re-derives the exact list of pendencies/avisos through
/// [GetOrderSubmissionContextUseCase] + [OrderSubmissionValidator] — never
/// deciding on its own whether the order is submittable.
///
/// Its own cubit, separate from `OrderDraftBloc`/`OrderPricingSummaryCubit`,
/// same "cada preocupação, seu próprio cubit" precedent this screen already
/// follows (`OrderPricingSummaryCubit`'s own docs) — re-evaluating pendencies
/// is a slower, lookup-bound operation that must never block editing
/// quantities/notes elsewhere on the same screen while it is in flight.
@injectable
final class OrderSubmissionValidationCubit
    extends Cubit<OrderSubmissionValidationState> {
  OrderSubmissionValidationCubit(this._getContext, this._validator)
    : super(const OrderSubmissionValidationState());

  final GetOrderSubmissionContextUseCase _getContext;
  final OrderSubmissionValidator _validator;

  /// Guards against a stale evaluation overwriting a newer one — the same
  /// token-based staleness guard `OrderPricingSummaryCubit._requestToken`
  /// already uses, needed here because [evaluate] is expected to be called
  /// again (debounced by the caller) before a previous call resolves.
  int _requestToken = 0;

  Future<void> evaluate({
    required Order order,
    OrderPricingSummary? pricingSummary,
    Map<String, String> productNamesById = const <String, String>{},
  }) async {
    final token = ++_requestToken;
    emit(state.copyWith(status: OrderSubmissionValidationStatus.evaluating));

    final context = await _getContext(order: order);
    if (isClosed || token != _requestToken) return;

    final issues = _validator.validate(
      order: order,
      context: context,
      pricingSummary: pricingSummary,
      productNamesById: productNamesById,
    );
    if (isClosed || token != _requestToken) return;

    emit(
      OrderSubmissionValidationState(
        status: OrderSubmissionValidationStatus.evaluated,
        issues: issues,
      ),
    );
  }
}

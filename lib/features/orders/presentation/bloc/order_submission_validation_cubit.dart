import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderDraftBloc`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../../credit/domain/entities/credit_check_result.dart';
import '../../../credit/domain/usecases/credit_use_cases.dart';
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
  OrderSubmissionValidationCubit(
    this._getContext,
    this._validator,
    this._validateOrderCredit,
  ) : super(const OrderSubmissionValidationState());

  final GetOrderSubmissionContextUseCase _getContext;
  final OrderSubmissionValidator _validator;
  final ValidateOrderCreditUseCase _validateOrderCredit;

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

    // TASK-212: best-effort, exactly like `_getContext` right below —
    // resolved only once `pricingSummary` (and therefore a real order
    // total) is known, mirroring `_validatePricing`'s own "nothing to check
    // yet" precedent. A failed/slow lookup never blocks this screen: this
    // is explicitly a client-side/UX-only preview, `submitOrder` always
    // revalidates credit server-side regardless of what this call found.
    final contextFuture = _getContext(order: order);
    final creditFuture = pricingSummary == null
        ? Future<CreditCheckResult?>.value()
        : _resolveCreditCheck(order: order, orderTotal: pricingSummary.total);
    final context = await contextFuture;
    final creditCheck = await creditFuture;
    if (isClosed || token != _requestToken) return;

    final issues = _validator.validate(
      order: order,
      context: context,
      pricingSummary: pricingSummary,
      creditCheck: creditCheck,
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

  Future<CreditCheckResult?> _resolveCreditCheck({
    required Order order,
    required double orderTotal,
  }) async {
    final result = await _validateOrderCredit(
      organizationId: order.organizationId,
      companyId: order.companyId,
      customerId: order.customerId,
      orderTotal: orderTotal,
    );
    return switch (result) {
      AppSuccess<CreditCheckResult>(value: final check) => check,
      AppFailure<CreditCheckResult>() => null,
    };
  }
}

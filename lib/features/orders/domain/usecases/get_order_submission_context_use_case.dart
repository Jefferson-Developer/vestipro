// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderDraftBloc`/`OrderLocalMapper` already follow.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customer_by_id_use_case.dart';
import '../../../pricing/domain/entities/payment_term.dart';
import '../../../pricing/domain/entities/price_list.dart';
import '../../../pricing/domain/repositories/payment_term_repository.dart';
import '../../../pricing/domain/repositories/price_list_repository.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../entities/order.dart';
import '../entities/order_submission_context.dart';

/// Resolves every entity `OrderSubmissionValidator` (TASK-100) needs for
/// [order] right now: the real `Customer`/`PriceList`/`PaymentTerm` behind
/// its ids (never the in-memory snapshot a screen may already be holding,
/// same "never trust a client-supplied snapshot" precedent
/// `StartOrderDraftForCustomerUseCase` already follows for `Customer`) and
/// the inventory availability of every item still on the draft.
///
/// Deliberately best-effort and failure-swallowing: a lookup that fails
/// (offline, not found, permission denied) simply leaves the matching
/// `OrderSubmissionContext` field `null`/empty instead of failing this whole
/// call — `OrderSubmissionValidator` itself decides what a missing field
/// means for submission. This mirrors `OrderDraftBloc._resolveProductNames`'s
/// own "a failed lookup never blocks the screen" precedent, since this
/// validation is explicitly client-side/UX-only (TASK-100's own rule): the
/// Cloud Function behind submission (TASK-101) re-resolves and re-validates
/// every one of these server-side regardless of what this use case found.
@injectable
final class GetOrderSubmissionContextUseCase {
  const GetOrderSubmissionContextUseCase(
    this._getCustomerById,
    this._priceListRepository,
    this._paymentTermRepository,
    this._getVariantAvailability,
  );

  final GetCustomerByIdUseCase _getCustomerById;
  final PriceListRepository _priceListRepository;
  final PaymentTermRepository _paymentTermRepository;
  final GetVariantAvailabilityUseCase _getVariantAvailability;

  Future<OrderSubmissionContext> call({required Order order}) async {
    final customerResult = await _getCustomerById(
      organizationId: order.organizationId,
      id: order.customerId,
    );
    final customer = switch (customerResult) {
      AppSuccess<Customer>(value: final value) => value,
      AppFailure<Customer>() => null,
    };

    final priceListResult = await _priceListRepository.getById(
      organizationId: order.organizationId,
      id: order.priceListId,
    );
    final priceList = switch (priceListResult) {
      AppSuccess<PriceList?>(value: final value) => value,
      AppFailure<PriceList?>() => null,
    };

    final paymentTermResult = await _paymentTermRepository.getById(
      organizationId: order.organizationId,
      id: order.paymentTermId,
    );
    final paymentTerm = switch (paymentTermResult) {
      AppSuccess<PaymentTerm?>(value: final value) => value,
      AppFailure<PaymentTerm?>() => null,
    };

    var availabilityByVariantId = const <String, VariantAvailability>{};
    final variantIds = <String>{for (final item in order.items) item.variantId};
    if (variantIds.isNotEmpty) {
      final availabilityResult = await _getVariantAvailability(
        organizationId: order.organizationId,
        variantIds: variantIds,
      );
      if (availabilityResult case AppSuccess<VariantAvailabilitySnapshot>(
        value: final snapshot,
      )) {
        availabilityByVariantId = snapshot.byVariantId;
      }
    }

    return OrderSubmissionContext(
      customer: customer,
      priceList: priceList,
      paymentTerm: paymentTerm,
      availabilityByVariantId: availabilityByVariantId,
    );
  }
}

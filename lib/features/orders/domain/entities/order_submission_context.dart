import '../../../customers/domain/entities/customer.dart';
import '../../../pricing/domain/entities/payment_term.dart';
import '../../../pricing/domain/entities/price_list.dart';
import '../../../products/domain/entities/variant_availability.dart';

/// Best-effort snapshot of every entity `OrderSubmissionValidator` (TASK-100)
/// needs to evaluate an `Order` draft, resolved by
/// `GetOrderSubmissionContextUseCase` — a `null` field here only ever means
/// "could not be resolved right now" (offline, not found, lookup failed),
/// never "does not exist"; the validator itself decides what a missing field
/// means for submission (see its own docs), this context never does.
final class OrderSubmissionContext {
  const OrderSubmissionContext({
    this.customer,
    this.priceList,
    this.paymentTerm,
    this.availabilityByVariantId = const <String, VariantAvailability>{},
  });

  final Customer? customer;
  final PriceList? priceList;
  final PaymentTerm? paymentTerm;

  /// Keyed by `OrderItem.variantId`. A variant not present here simply was
  /// not resolved (offline, new variant, lookup failure) — the validator
  /// never blocks submission on a missing entry, same "never blocking on
  /// this lookup" precedent `OrderDraftState.productsById` already
  /// documents.
  final Map<String, VariantAvailability> availabilityByVariantId;
}

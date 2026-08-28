import '../value_objects/product_variant_status.dart';
import '../value_objects/variant_availability_status.dart';
import 'product_variant.dart';

/// Stable availability contract for a sellable product variant.
///
/// The current data source is manual metadata stored on [ProductVariant].
/// TASK-090 will replace that source with real inventory balance without
/// changing this domain contract or the UI consumers.
final class VariantAvailability {
  const VariantAvailability({
    required this.variantId,
    required this.productId,
    required this.status,
    this.availableQuantity,
    this.futureAvailableAt,
    this.futureAvailableQuantity,
    this.futureSourceLabel,
    this.warehouseQuantities = const <String, int>{},
  });

  factory VariantAvailability.fromVariant(ProductVariant variant) {
    final status = variant.status == ProductVariantStatus.inactive
        ? VariantAvailabilityStatus.unavailable
        : variant.manualAvailabilityStatus ??
              VariantAvailabilityStatus.readyStock;
    return VariantAvailability(
      variantId: variant.id,
      productId: variant.productId,
      status: status,
      availableQuantity:
          status == VariantAvailabilityStatus.unavailable ||
              variant.manualAvailableQuantity == null ||
              variant.manualAvailableQuantity! < 0
          ? null
          : variant.manualAvailableQuantity,
      futureAvailableAt: status == VariantAvailabilityStatus.futureStock
          ? variant.manualFutureAvailableAt?.toUtc()
          : null,
      futureAvailableQuantity: status == VariantAvailabilityStatus.futureStock
          ? variant.manualAvailableQuantity
          : null,
      futureSourceLabel:
          status == VariantAvailabilityStatus.futureStock &&
              variant.manualFutureAvailableAt != null
          ? 'Previsão manual'
          : null,
    );
  }

  final String variantId;
  final String productId;
  final VariantAvailabilityStatus status;
  final int? availableQuantity;
  final DateTime? futureAvailableAt;
  final int? futureAvailableQuantity;
  final String? futureSourceLabel;
  final Map<String, int> warehouseQuantities;

  bool get acceptsQuantity => status != VariantAvailabilityStatus.unavailable;

  bool get hasFutureDate =>
      status == VariantAvailabilityStatus.futureStock &&
      futureAvailableAt != null;
}

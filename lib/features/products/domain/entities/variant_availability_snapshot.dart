import '../value_objects/variant_availability_status.dart';
import 'variant_availability.dart';

final class VariantAvailabilitySnapshot {
  const VariantAvailabilitySnapshot({
    this.byVariantId = const <String, VariantAvailability>{},
    this.byProductId = const <String, List<VariantAvailability>>{},
  });

  factory VariantAvailabilitySnapshot.fromList(
    Iterable<VariantAvailability> availabilities,
  ) {
    final byVariantId = <String, VariantAvailability>{};
    final byProductId = <String, List<VariantAvailability>>{};
    for (final availability in availabilities) {
      byVariantId[availability.variantId] = availability;
      byProductId
          .putIfAbsent(availability.productId, () => <VariantAvailability>[])
          .add(availability);
    }
    return VariantAvailabilitySnapshot(
      byVariantId: Map<String, VariantAvailability>.unmodifiable(byVariantId),
      byProductId: Map<String, List<VariantAvailability>>.unmodifiable(
        byProductId.map(
          (productId, values) => MapEntry<String, List<VariantAvailability>>(
            productId,
            List<VariantAvailability>.unmodifiable(values),
          ),
        ),
      ),
    );
  }

  final Map<String, VariantAvailability> byVariantId;
  final Map<String, List<VariantAvailability>> byProductId;

  VariantAvailability? forVariant(String variantId) => byVariantId[variantId];

  VariantAvailability? primaryForProduct(String productId) {
    final availabilities = byProductId[productId];
    if (availabilities == null || availabilities.isEmpty) return null;
    return _firstByStatus(
          availabilities,
          VariantAvailabilityStatus.readyStock,
        ) ??
        _firstByStatus(availabilities, VariantAvailabilityStatus.futureStock) ??
        _firstByStatus(availabilities, VariantAvailabilityStatus.unavailable);
  }

  VariantAvailability? _firstByStatus(
    List<VariantAvailability> availabilities,
    VariantAvailabilityStatus status,
  ) {
    for (final availability in availabilities) {
      if (availability.status == status) return availability;
    }
    return null;
  }
}

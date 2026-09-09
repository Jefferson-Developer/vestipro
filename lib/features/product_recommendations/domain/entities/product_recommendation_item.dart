import '../value_objects/product_recommendation_reason_code.dart';

/// One suggested product inside a `ProductRecommendation` (TASK-190,
/// EPIC-28) — always carries a visible [reasonLabel], never a bare product
/// id/score without an explanation.
final class ProductRecommendationItem {
  const ProductRecommendationItem({
    required this.productId,
    required this.productName,
    required this.score,
    required this.reasonCode,
    required this.reasonLabel,
    this.relatedProductId,
    this.relatedProductName,
  });

  final String productId;
  final String productName;

  /// Always `>= 0`. Only meaningfully comparable within the same
  /// [reasonCode]/scope — a `bestSeller` score (a raw basket count) is never
  /// compared against a `boughtTogether`/`purchaseHistorySimilarity` score
  /// (a `0..1` confidence ratio).
  final double score;

  final ProductRecommendationReasonCode reasonCode;

  /// Human-readable, always-visible justification (e.g. "Clientes que
  /// compraram X também compraram Y").
  final String reasonLabel;

  /// The product this suggestion was derived from — the anchor product
  /// itself for `product` scope, or one of the customer's own past
  /// purchases for `customer` scope. `null` for a `bestSeller` reason
  /// (nothing "related" motivates a best-seller, it stands on its own).
  final String? relatedProductId;
  final String? relatedProductName;
}

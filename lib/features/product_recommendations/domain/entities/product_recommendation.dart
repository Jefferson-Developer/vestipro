import '../value_objects/product_recommendation_scope_type.dart';
import 'product_recommendation_item.dart';

/// A server-computed behavioral product recommendation (TASK-190, EPIC-28) —
/// co-occurrence of products already purchased ("comprado com frequência
/// junto"/"clientes com o mesmo perfil de compra"), always presented with a
/// visible justification per item, never a fabricated fallback.
///
/// One document per scope
/// (`organizations/{organizationId}/productRecommendations/
/// {companyId}_{scopeType}_{scopeId}`), written exclusively by the weekly
/// scheduled `calculateProductRecommendations` Cloud Function — the client
/// never writes this collection directly (`firestore.rules`).
final class ProductRecommendation {
  const ProductRecommendation({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.scopeType,
    required this.scopeId,
    required this.items,
    required this.fallbackApplied,
    required this.insufficientData,
    required this.signalsUsed,
    required this.lookbackDays,
    required this.model,
    required this.modelVersion,
    required this.generatedAt,
    required this.version,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final ProductRecommendationScopeType scopeType;
  final String scopeId;

  /// Always empty when [insufficientData] is `true` — never a fabricated
  /// item.
  final List<ProductRecommendationItem> items;

  /// `true` when [items] came from the company-wide best-sellers fallback
  /// instead of a personalized/item-specific signal (only ever `true` for
  /// [ProductRecommendationScopeType.customer]).
  final bool fallbackApplied;

  /// `true` when [items] is empty because there is genuinely not enough data
  /// yet (never because of an error) — the UI must render this as an
  /// explicit "sem dado suficiente" state, never silently hide the section.
  final bool insufficientData;

  /// Which signal(s) fed this exact result (e.g.
  /// `order_submitted_item_co_occurrence`, `best_sellers_fallback`) — empty
  /// only when [insufficientData] is `true`.
  final List<String> signalsUsed;

  /// Rolling window (in days) of order history the model was computed from.
  final int lookbackDays;

  /// Identifies the statistical method used (e.g. `itemCoOccurrenceV1`).
  final String model;

  /// Identifies the exact model version/tuning used, letting a gestor audit
  /// why a suggestion was generated on a given date.
  final String modelVersion;

  final DateTime generatedAt;
  final int version;

  bool get hasRecommendations => items.isNotEmpty;
}

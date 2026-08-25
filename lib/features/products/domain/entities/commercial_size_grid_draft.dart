/// Locally persisted quantity draft for one product commercial size grid.
final class CommercialSizeGridDraft {
  const CommercialSizeGridDraft({
    required this.organizationId,
    required this.productId,
    required this.quantitiesByVariantId,
    required this.updatedAt,
  });

  final String organizationId;
  final String productId;
  final Map<String, int> quantitiesByVariantId;
  final DateTime updatedAt;

  int get totalQuantity =>
      quantitiesByVariantId.values.fold(0, (sum, quantity) => sum + quantity);

  CommercialSizeGridDraft copyWith({
    Map<String, int>? quantitiesByVariantId,
    DateTime? updatedAt,
  }) {
    return CommercialSizeGridDraft(
      organizationId: organizationId,
      productId: productId,
      quantitiesByVariantId:
          quantitiesByVariantId ?? this.quantitiesByVariantId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

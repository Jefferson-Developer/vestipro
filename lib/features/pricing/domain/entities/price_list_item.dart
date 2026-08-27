import 'price_list.dart';

/// A base price row inside one [PriceList].
///
/// When [variantId] is `null`, the row applies to every variant of the same
/// [productId] in that table unless a variant-specific exception exists.
final class PriceListItem {
  const PriceListItem({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.priceListId,
    required this.productId,
    required this.price,
    required this.updatedAt,
    required this.updatedBy,
    this.variantId,
    this.deletedAt,
    this.version = 1,
    this.syncStatus = 'pending',
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String priceListId;
  final String productId;
  final String? variantId;
  final double price;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  bool get isVariantSpecific =>
      variantId != null && variantId!.trim().isNotEmpty;

  bool appliesToVariant(String candidateVariantId) =>
      isVariantSpecific ? variantId == candidateVariantId : true;

  static String composeId({
    required String priceListId,
    required String productId,
    String? variantId,
  }) {
    final normalizedVariantId = variantId?.trim();
    return '$priceListId::$productId::${normalizedVariantId?.isEmpty ?? true ? "*" : normalizedVariantId}';
  }
}

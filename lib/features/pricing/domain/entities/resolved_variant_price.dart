import 'price_list.dart';
import 'price_list_item.dart';

enum PriceResolutionOrigin { variant, product, missing }

/// Result of TASK-084's single documented fallback chain:
/// variant-specific -> product-level in the same table -> missing.
final class ResolvedVariantPrice {
  const ResolvedVariantPrice({
    required this.origin,
    required this.applicablePriceLists,
    this.priceList,
    this.matchedItem,
  });

  final PriceResolutionOrigin origin;
  final List<PriceList> applicablePriceLists;
  final PriceList? priceList;
  final PriceListItem? matchedItem;

  bool get hasPrice => matchedItem != null;
  double? get price => matchedItem?.price;
  bool get isVariantException => origin == PriceResolutionOrigin.variant;
}

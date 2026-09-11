import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_variant.dart';

/// One product a scanned code resolved to (TASK-216) — [variant] is `null`
/// only for the rare product that currently has no active sellable variant
/// at all, so the caller still has a [product] to show/navigate to instead
/// of silently dropping the match.
final class ProductCodeMatch {
  const ProductCodeMatch({required this.product, this.variant});

  final Product product;
  final ProductVariant? variant;
}

import 'product_code_match.dart';

/// Outcome of resolving one scanned/typed code against the catalog
/// (TASK-216).
enum ProductCodeResolutionStatus {
  /// Exactly one variant (or, for a product with no active variant, exactly
  /// one product) matched — the common case for a garment-tag EAN or a
  /// variant SKU, since both are unique per organization.
  singleMatch,

  /// The code matched a *product*-level identifier (SKU/reference/EAN) that
  /// has more than one active sellable variant — e.g. a box/reference label
  /// scanned instead of the garment's own color/size tag. The caller
  /// resolves this the same way it would a product tapped from a grid: by
  /// opening that one product ([matches] all share the same
  /// [ProductCodeMatch.product]) so the seller picks color/size normally,
  /// never by guessing.
  multipleMatches,

  /// No product, variant or registered alternate code matched — including a
  /// well-formed internal QR minted for a *different* organization (treated
  /// as not found, never as "exists elsewhere", see `InternalQrPayload`).
  notFound,
}

final class ProductCodeResolution {
  const ProductCodeResolution({
    required this.status,
    required this.rawCode,
    this.matches = const <ProductCodeMatch>[],
  });

  factory ProductCodeResolution.single(String rawCode, ProductCodeMatch match) {
    return ProductCodeResolution(
      status: ProductCodeResolutionStatus.singleMatch,
      rawCode: rawCode,
      matches: <ProductCodeMatch>[match],
    );
  }

  factory ProductCodeResolution.multiple(
    String rawCode,
    List<ProductCodeMatch> matches,
  ) {
    return ProductCodeResolution(
      status: ProductCodeResolutionStatus.multipleMatches,
      rawCode: rawCode,
      matches: matches,
    );
  }

  factory ProductCodeResolution.notFound(String rawCode) {
    return ProductCodeResolution(
      status: ProductCodeResolutionStatus.notFound,
      rawCode: rawCode,
    );
  }

  final ProductCodeResolutionStatus status;
  final String rawCode;
  final List<ProductCodeMatch> matches;

  bool get isResolved => matches.isNotEmpty;

  /// Only non-null for [ProductCodeResolutionStatus.singleMatch] — the exact
  /// variant/product the caller can add to an order/show without any further
  /// disambiguation.
  ProductCodeMatch? get singleMatchOrNull =>
      status == ProductCodeResolutionStatus.singleMatch ? matches.first : null;

  /// The one product every entry in [matches] shares, regardless of
  /// [status] — `null` only for [ProductCodeResolutionStatus.notFound].
  /// [singleMatch]/[multipleMatches] both resolve to a single product
  /// (see [ProductCodeResolutionStatus.multipleMatches] doc), so a caller
  /// that only needs "which product do I open" never has to branch on
  /// [status] at all.
  String? get productId => matches.isEmpty ? null : matches.first.product.id;
}

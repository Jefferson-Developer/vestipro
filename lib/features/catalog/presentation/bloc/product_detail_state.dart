import '../../../../core/errors/errors.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/product_media.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';

enum ProductDetailLoadStatus { initial, loading, success, failure }

/// One color this product has variants for, resolved even when the color
/// catalog failed to load or came back partial (TASK-078 "falha parcial") —
/// [color] is `null` in that case and [label] falls back to the raw id so
/// the swatch is never silently dropped.
final class ProductDetailColorOption {
  const ProductDetailColorOption({required this.id, this.color});

  final String id;
  final ProductColor? color;

  String get label => color?.name ?? id;
}

/// One line of the "adicionar ao pedido" request: a variant with a typed
/// quantity greater than zero. Carries the full [ProductVariant] (not just
/// an id) and the already-resolved [unitPrice] — the exact price the seller
/// was shown for this variant against the active tabela de preço at the
/// moment of the tap (`ResolvedVariantPrice.price`, never a flattened/
/// recalculated one) — so the hosting page's EPIC-13 integration has
/// everything it needs to build an `OrderItem` without a second, possibly
/// racy price lookup.
final class ProductDetailOrderLine {
  const ProductDetailOrderLine({
    required this.variant,
    required this.quantity,
    required this.unitPrice,
  });

  final ProductVariant variant;
  final int quantity;
  final double unitPrice;
}

final class ProductDetailState {
  const ProductDetailState({
    this.status = ProductDetailLoadStatus.initial,
    this.organizationId = '',
    this.productId = '',
    this.origin = 'grid',
    this.product,
    this.colors = const <ProductColor>[],
    this.variants = const <ProductVariant>[],
    this.sizeGridTemplate,
    this.availabilityByVariantId = const <String, VariantAvailability>{},
    this.hasAvailabilityWarning = false,
    this.selectedColorId,
    this.quantitiesByVariantId = const <String, int>{},
    this.failure,
    this.hasLoggedViewed = false,
    this.pricesByVariantId = const <String, ResolvedVariantPrice>{},
    this.hasPricingWarning = false,
  });

  final ProductDetailLoadStatus status;
  final String organizationId;
  final String productId;
  final String origin;
  final Product? product;
  final List<ProductColor> colors;
  final List<ProductVariant> variants;
  final SizeGridTemplate? sizeGridTemplate;
  final Map<String, VariantAvailability> availabilityByVariantId;

  /// Set when availability failed to load for at least one fetched entity —
  /// the grid still renders using `VariantAvailability.fromVariant` as a
  /// pure, already-fetched-data fallback (never a client-side stock
  /// calculation), but the UI must show this explicitly instead of quietly
  /// pretending everything is confirmed ready stock.
  final bool hasAvailabilityWarning;

  final String? selectedColorId;
  final Map<String, int> quantitiesByVariantId;
  final Failure? failure;
  final bool hasLoggedViewed;
  final Map<String, ResolvedVariantPrice> pricesByVariantId;
  final bool hasPricingWarning;

  bool get isInitialLoading =>
      status == ProductDetailLoadStatus.initial ||
      status == ProductDetailLoadStatus.loading;

  bool get isPriceAvailable =>
      pricesByVariantId.values.any((resolved) => resolved.hasPrice);

  List<SizeGridSize> get orderedSizes =>
      sizeGridTemplate?.orderedSizes ?? const <SizeGridSize>[];

  /// Every color id this product actually has variants for, ordered by
  /// `Product.colorIds` first and then by any color found only on a variant
  /// — mirrors `CommercialSizeGridState.orderedColors`. [ProductColor]
  /// metadata is attached when available, but a color is never left out
  /// just because [colors] failed to load or is missing that id.
  List<ProductDetailColorOption> get colorOptions {
    final currentProduct = product;
    if (currentProduct == null) return const <ProductDetailColorOption>[];
    final colorById = <String, ProductColor>{
      for (final color in colors) color.id: color,
    };
    final variantColorIds = <String>{for (final v in variants) v.colorId};
    final orderedIds = <String>[
      for (final id in currentProduct.colorIds)
        if (variantColorIds.contains(id)) id,
    ];
    for (final id in variantColorIds) {
      if (!orderedIds.contains(id)) orderedIds.add(id);
    }
    return orderedIds
        .map((id) => ProductDetailColorOption(id: id, color: colorById[id]))
        .toList(growable: false);
  }

  List<ProductVariant> variantsForColor(String colorId) => variants
      .where((variant) => variant.colorId == colorId)
      .toList(growable: false);

  ProductVariant? variantForCell({
    required String colorId,
    required String sizeId,
  }) {
    for (final variant in variants) {
      if (variant.colorId == colorId && variant.sizeId == sizeId) {
        return variant;
      }
    }
    return null;
  }

  VariantAvailability availabilityForVariant(ProductVariant variant) =>
      availabilityByVariantId[variant.id] ??
      VariantAvailability.fromVariant(variant);

  ResolvedVariantPrice? priceForVariant(ProductVariant variant) =>
      pricesByVariantId[variant.id];

  bool canAddVariantToOrder(ProductVariant variant) =>
      availabilityForVariant(variant).acceptsQuantity &&
      (priceForVariant(variant)?.hasPrice ?? false);

  /// Aggregate availability for a whole color, used by the color swatch:
  /// ready stock if any size of that color is ready, else future stock if
  /// any is a future arrival, else unavailable — the same
  /// ready-then-future-then-unavailable precedence
  /// `VariantAvailabilitySnapshot.primaryForProduct` already uses at the
  /// product level, applied here per color instead.
  VariantAvailabilityStatus availabilityForColor(String colorId) {
    final colorVariants = variantsForColor(colorId);
    if (colorVariants.isEmpty) return VariantAvailabilityStatus.unavailable;
    final statuses = colorVariants
        .map((variant) => availabilityForVariant(variant).status)
        .toSet();
    if (statuses.contains(VariantAvailabilityStatus.readyStock)) {
      return VariantAvailabilityStatus.readyStock;
    }
    if (statuses.contains(VariantAvailabilityStatus.futureStock)) {
      return VariantAvailabilityStatus.futureStock;
    }
    return VariantAvailabilityStatus.unavailable;
  }

  int quantityForVariant(ProductVariant variant) {
    if (!canAddVariantToOrder(variant)) return 0;
    return quantitiesByVariantId[variant.id] ?? 0;
  }

  double? get lowestResolvedPrice {
    final prices = pricesByVariantId.values
        .where((resolved) => resolved.price != null)
        .map((resolved) => resolved.price!)
        .toList(growable: false);
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  int get totalQuantity =>
      variants.fold(0, (sum, variant) => sum + quantityForVariant(variant));

  List<ProductDetailOrderLine> get orderLines => <ProductDetailOrderLine>[
    for (final variant in variants)
      if (quantityForVariant(variant) > 0)
        ProductDetailOrderLine(
          variant: variant,
          quantity: quantityForVariant(variant),
          // Safe: `quantityForVariant` only returns > 0 when
          // `canAddVariantToOrder` already confirmed `priceForVariant(...)`
          // has a resolved price.
          unitPrice: priceForVariant(variant)!.price!,
        ),
  ];

  /// Photos scoped to [selectedColorId] when the product has any (TASK-070
  /// per-color photos); falls back to the product's color-agnostic photos
  /// otherwise, so switching color always resolves to *some* gallery
  /// instead of an unexplained empty one.
  List<ProductMedia> get galleryPhotos {
    final currentProduct = product;
    if (currentProduct == null) return const <ProductMedia>[];
    final scoped = currentProduct.photos
        .where((media) => media.colorId == selectedColorId)
        .toList(growable: false);
    if (scoped.isNotEmpty) return scoped;
    return currentProduct.photos
        .where((media) => media.colorId == null)
        .toList(growable: false);
  }

  bool get hasNoPurchasableVariants =>
      status == ProductDetailLoadStatus.success && variants.isEmpty;

  ProductDetailState copyWith({
    ProductDetailLoadStatus? status,
    String? organizationId,
    String? productId,
    String? origin,
    Product? product,
    List<ProductColor>? colors,
    List<ProductVariant>? variants,
    SizeGridTemplate? sizeGridTemplate,
    bool clearSizeGridTemplate = false,
    Map<String, VariantAvailability>? availabilityByVariantId,
    bool? hasAvailabilityWarning,
    String? selectedColorId,
    Map<String, int>? quantitiesByVariantId,
    Failure? failure,
    bool clearFailure = false,
    bool? hasLoggedViewed,
    Map<String, ResolvedVariantPrice>? pricesByVariantId,
    bool? hasPricingWarning,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      productId: productId ?? this.productId,
      origin: origin ?? this.origin,
      product: product ?? this.product,
      colors: colors ?? this.colors,
      variants: variants ?? this.variants,
      sizeGridTemplate: clearSizeGridTemplate
          ? null
          : sizeGridTemplate ?? this.sizeGridTemplate,
      availabilityByVariantId:
          availabilityByVariantId ?? this.availabilityByVariantId,
      hasAvailabilityWarning:
          hasAvailabilityWarning ?? this.hasAvailabilityWarning,
      selectedColorId: selectedColorId ?? this.selectedColorId,
      quantitiesByVariantId:
          quantitiesByVariantId ?? this.quantitiesByVariantId,
      failure: clearFailure ? null : failure ?? this.failure,
      hasLoggedViewed: hasLoggedViewed ?? this.hasLoggedViewed,
      pricesByVariantId: pricesByVariantId ?? this.pricesByVariantId,
      hasPricingWarning: hasPricingWarning ?? this.hasPricingWarning,
    );
  }
}

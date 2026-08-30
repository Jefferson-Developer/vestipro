import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';

/// Load lifecycle of one product's size grid inside the order draft screen
/// (EPIC-13, TASK-098).
enum OrderItemsGridLoadStatus { loading, ready, failure }

/// Read-only "catalog shape" (colors, sizes, availability) of one product
/// already on an `Order` draft, resolved through the very same use cases
/// `ProductDetailBloc`/`CommercialSizeGridBloc` already rely on
/// (`ListProductVariantsByProductUseCase`, `ListProductColorsUseCase`,
/// `GetSizeGridTemplateByIdUseCase`, `GetVariantAvailabilityUseCase` —
/// TASK-072/TASK-090/TASK-091) — never a second implementation of "which
/// color/size combinations exist for this product".
///
/// This state deliberately carries no quantity of its own: [OrderItemsGrid]
/// (the widget) reads the already-typed quantities straight from
/// `OrderDraftState.order.items`, the single source of truth for what
/// survives a lost connection (`AGENTS.md`'s offline-first rule) — this
/// cubit only ever answers "what colors/sizes/availability does this
/// product have", never "how many of each did the seller already type".
final class OrderItemsGridState {
  const OrderItemsGridState({
    this.loadStatus = OrderItemsGridLoadStatus.loading,
    this.product,
    this.colors = const <ProductColor>[],
    this.sizeGridTemplate,
    this.variants = const <ProductVariant>[],
    this.availabilityByVariantId = const <String, VariantAvailability>{},
    this.failure,
  });

  final OrderItemsGridLoadStatus loadStatus;
  final Product? product;
  final List<ProductColor> colors;
  final SizeGridTemplate? sizeGridTemplate;
  final List<ProductVariant> variants;
  final Map<String, VariantAvailability> availabilityByVariantId;
  final Failure? failure;

  List<SizeGridSize> get orderedSizes =>
      sizeGridTemplate?.orderedSizes ?? const <SizeGridSize>[];

  /// Every color id this product actually has variants for, ordered by
  /// `Product.colorIds` first and then by any color found only on a variant
  /// — mirrors `CommercialSizeGridState.orderedColors`/
  /// `ProductDetailState.colorOptions`.
  List<ProductColor> get orderedColors {
    final currentProduct = product;
    if (currentProduct == null) return const <ProductColor>[];
    final colorById = <String, ProductColor>{
      for (final color in colors) color.id: color,
    };
    final result = <ProductColor>[
      for (final colorId in currentProduct.colorIds)
        if (colorById[colorId] != null) colorById[colorId]!,
    ];
    final included = result.map((color) => color.id).toSet();
    for (final color in colors) {
      if (!included.contains(color.id) &&
          variants.any((variant) => variant.colorId == color.id)) {
        result.add(color);
      }
    }
    return List<ProductColor>.unmodifiable(result);
  }

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

  OrderItemsGridState copyWith({
    OrderItemsGridLoadStatus? loadStatus,
    Product? product,
    List<ProductColor>? colors,
    SizeGridTemplate? sizeGridTemplate,
    List<ProductVariant>? variants,
    Map<String, VariantAvailability>? availabilityByVariantId,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderItemsGridState(
      loadStatus: loadStatus ?? this.loadStatus,
      product: product ?? this.product,
      colors: colors ?? this.colors,
      sizeGridTemplate: sizeGridTemplate ?? this.sizeGridTemplate,
      variants: variants ?? this.variants,
      availabilityByVariantId:
          availabilityByVariantId ?? this.availabilityByVariantId,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

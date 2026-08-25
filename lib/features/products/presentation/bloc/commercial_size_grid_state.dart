import '../../../../core/errors/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/size_grid_template.dart';
import '../../domain/value_objects/commercial_variant_availability.dart';
import '../../domain/value_objects/product_variant_status.dart';

enum CommercialSizeGridLoadStatus { loading, ready, failure }

enum CommercialSizeGridSaveStatus { idle, saving, saved, failure }

final class CommercialSizeGridState {
  const CommercialSizeGridState({
    this.loadStatus = CommercialSizeGridLoadStatus.loading,
    this.saveStatus = CommercialSizeGridSaveStatus.idle,
    this.product,
    this.colors = const <ProductColor>[],
    this.sizeGridTemplate,
    this.variants = const <ProductVariant>[],
    this.quantitiesByVariantId = const <String, int>{},
    this.availabilityByVariantId =
        const <String, CommercialVariantAvailability>{},
    this.isOnline = true,
    this.failure,
  });

  final CommercialSizeGridLoadStatus loadStatus;
  final CommercialSizeGridSaveStatus saveStatus;
  final Product? product;
  final List<ProductColor> colors;
  final SizeGridTemplate? sizeGridTemplate;
  final List<ProductVariant> variants;
  final Map<String, int> quantitiesByVariantId;
  final Map<String, CommercialVariantAvailability> availabilityByVariantId;
  final bool isOnline;
  final Failure? failure;

  List<SizeGridSize> get orderedSizes =>
      sizeGridTemplate?.orderedSizes ?? const <SizeGridSize>[];

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

  CommercialVariantAvailability availabilityForVariant(ProductVariant variant) {
    if (variant.status == ProductVariantStatus.inactive) {
      return CommercialVariantAvailability.unavailable;
    }
    return availabilityByVariantId[variant.id] ??
        CommercialVariantAvailability.readyStock;
  }

  bool isVariantEditable(ProductVariant variant) =>
      availabilityForVariant(variant) !=
      CommercialVariantAvailability.unavailable;

  int quantityForVariant(ProductVariant variant) {
    if (!isVariantEditable(variant)) return 0;
    return quantitiesByVariantId[variant.id] ?? 0;
  }

  int get totalQuantity =>
      variants.fold(0, (sum, variant) => sum + quantityForVariant(variant));

  CommercialSizeGridState copyWith({
    CommercialSizeGridLoadStatus? loadStatus,
    CommercialSizeGridSaveStatus? saveStatus,
    Product? product,
    List<ProductColor>? colors,
    SizeGridTemplate? sizeGridTemplate,
    List<ProductVariant>? variants,
    Map<String, int>? quantitiesByVariantId,
    Map<String, CommercialVariantAvailability>? availabilityByVariantId,
    bool? isOnline,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CommercialSizeGridState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      product: product ?? this.product,
      colors: colors ?? this.colors,
      sizeGridTemplate: sizeGridTemplate ?? this.sizeGridTemplate,
      variants: variants ?? this.variants,
      quantitiesByVariantId:
          quantitiesByVariantId ?? this.quantitiesByVariantId,
      availabilityByVariantId:
          availabilityByVariantId ?? this.availabilityByVariantId,
      isOnline: isOnline ?? this.isOnline,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

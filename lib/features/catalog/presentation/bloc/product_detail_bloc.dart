import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../pricing/domain/usecases/resolve_price_for_variant_use_case.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_product_by_id_use_case.dart';
import '../../../products/domain/usecases/get_size_grid_template_by_id_use_case.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../../products/domain/usecases/list_product_colors_use_case.dart';
import '../../../products/domain/usecases/list_product_variants_by_product_use_case.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../../products/domain/value_objects/product_variant_status.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

@injectable
final class ProductDetailBloc
    extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc({
    required this.getProductById,
    required this.listVariantsByProduct,
    required this.listProductColors,
    required this.getSizeGridTemplateById,
    required this.getVariantAvailability,
    this.resolvePriceForVariant,
    required this.analyticsService,
  }) : super(const ProductDetailState()) {
    on<ProductDetailStarted>(_onStarted, transformer: restartable());
    on<ProductDetailRetried>(_onRetried, transformer: droppable());
    on<ProductDetailColorSelected>(_onColorSelected, transformer: sequential());
    on<ProductDetailQuantityChanged>(
      _onQuantityChanged,
      transformer: sequential(),
    );
    on<ProductDetailAddToOrderRequested>(_onAddToOrderRequested);
  }

  final GetProductByIdUseCase getProductById;
  final ListProductVariantsByProductUseCase listVariantsByProduct;
  final ListProductColorsUseCase listProductColors;
  final GetSizeGridTemplateByIdUseCase getSizeGridTemplateById;
  final GetVariantAvailabilityUseCase getVariantAvailability;
  final ResolvePriceForVariantUseCase? resolvePriceForVariant;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    ProductDetailStarted event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(
      ProductDetailState(
        status: ProductDetailLoadStatus.loading,
        organizationId: event.organizationId,
        productId: event.productId,
        origin: event.origin,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    ProductDetailRetried event,
    Emitter<ProductDetailState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.productId.isEmpty) return;
    emit(
      state.copyWith(
        status: ProductDetailLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<ProductDetailState> emit) async {
    final productResult = await getProductById(
      organizationId: state.organizationId,
      id: state.productId,
    );
    if (emit.isDone) return;
    if (productResult is AppFailure<Product>) {
      emit(
        state.copyWith(
          status: ProductDetailLoadStatus.failure,
          failure: productResult.failure,
        ),
      );
      return;
    }
    final product = (productResult as AppSuccess<Product>).value;

    final variantsFuture = listVariantsByProduct(
      organizationId: state.organizationId,
      productId: product.id,
    );
    final colorsFuture = listProductColors(state.organizationId);
    final templateId = product.sizeGridTemplateId;
    final templateFuture = (templateId == null || templateId.trim().isEmpty)
        ? null
        : getSizeGridTemplateById(
            organizationId: state.organizationId,
            id: templateId,
          );

    final variantsResult = await variantsFuture;
    final colorsResult = await colorsFuture;
    final templateResult = templateFuture == null ? null : await templateFuture;
    if (emit.isDone) return;

    final variants = variantsResult is AppSuccess<List<ProductVariant>>
        ? variantsResult.value
              .where((variant) => variant.status == ProductVariantStatus.active)
              .toList(growable: false)
        : const <ProductVariant>[];
    final colors = colorsResult is AppSuccess<List<ProductColor>>
        ? colorsResult.value
        : const <ProductColor>[];
    final template = templateResult is AppSuccess<SizeGridTemplate>
        ? templateResult.value
        : null;

    var hasAvailabilityWarning =
        variantsResult is AppFailure<List<ProductVariant>> ||
        colorsResult is AppFailure<List<ProductColor>> ||
        templateResult is AppFailure<SizeGridTemplate>;

    final availabilityByVariantId = await _fetchAvailability(variants);
    if (emit.isDone) return;
    if (availabilityByVariantId == null) hasAvailabilityWarning = true;

    final priceFetch = await _fetchPrices(product, variants);
    if (emit.isDone) return;

    emit(
      state.copyWith(
        status: ProductDetailLoadStatus.success,
        product: product,
        colors: colors,
        variants: variants,
        sizeGridTemplate: template,
        clearSizeGridTemplate: template == null,
        availabilityByVariantId:
            availabilityByVariantId ?? const <String, VariantAvailability>{},
        hasAvailabilityWarning: hasAvailabilityWarning,
        pricesByVariantId: priceFetch.$1,
        hasPricingWarning: priceFetch.$2,
        selectedColorId: _firstColorId(product, variants),
        clearFailure: true,
      ),
    );
    await _logViewedIfNeeded(emit);
  }

  String? _firstColorId(Product product, List<ProductVariant> variants) {
    for (final id in product.colorIds) {
      if (variants.any((variant) => variant.colorId == id)) return id;
    }
    if (variants.isNotEmpty) return variants.first.colorId;
    return null;
  }

  Future<Map<String, VariantAvailability>?> _fetchAvailability(
    List<ProductVariant> variants,
  ) async {
    if (variants.isEmpty) return const <String, VariantAvailability>{};
    final result = await getVariantAvailability(
      organizationId: state.organizationId,
      variantIds: variants.map((variant) => variant.id),
    );
    return switch (result) {
      AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot) =>
        snapshot.byVariantId,
      AppFailure<VariantAvailabilitySnapshot>() => null,
    };
  }

  Future<(Map<String, ResolvedVariantPrice>, bool)> _fetchPrices(
    Product product,
    List<ProductVariant> variants,
  ) async {
    final companyId = product.companyId?.trim();
    if (resolvePriceForVariant == null ||
        companyId == null ||
        companyId.isEmpty ||
        variants.isEmpty) {
      return (const <String, ResolvedVariantPrice>{}, false);
    }

    final resolved = <String, ResolvedVariantPrice>{};
    var hasWarning = false;
    for (final variant in variants) {
      final result = await resolvePriceForVariant!(
        organizationId: state.organizationId,
        companyId: companyId,
        productId: product.id,
        variantId: variant.id,
      );
      switch (result) {
        case AppSuccess<ResolvedVariantPrice>(value: final price):
          resolved[variant.id] = price;
        case AppFailure<ResolvedVariantPrice>():
          hasWarning = true;
      }
    }

    return (
      Map<String, ResolvedVariantPrice>.unmodifiable(resolved),
      hasWarning,
    );
  }

  void _onColorSelected(
    ProductDetailColorSelected event,
    Emitter<ProductDetailState> emit,
  ) {
    if (event.colorId == state.selectedColorId) return;
    emit(state.copyWith(selectedColorId: event.colorId));
    if (state.availabilityForColor(event.colorId) ==
        VariantAvailabilityStatus.futureStock) {
      unawaited(
        analyticsService.logEvent(
          AnalyticsEvents.futureStockViewed,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'product_id': state.productId,
            'color_id': event.colorId,
            'source': 'product_detail_color_selection',
          },
        ),
      );
    }
  }

  void _onQuantityChanged(
    ProductDetailQuantityChanged event,
    Emitter<ProductDetailState> emit,
  ) {
    final variant = state.variantForCell(
      colorId: event.colorId,
      sizeId: event.sizeId,
    );
    if (variant == null || !state.canAddVariantToOrder(variant)) {
      return;
    }

    final nextQuantity = event.quantity < 0 ? 0 : event.quantity;
    final nextQuantities = Map<String, int>.of(state.quantitiesByVariantId);
    if (nextQuantity == 0) {
      nextQuantities.remove(variant.id);
    } else {
      nextQuantities[variant.id] = nextQuantity;
    }

    emit(
      state.copyWith(
        quantitiesByVariantId: Map<String, int>.unmodifiable(nextQuantities),
      ),
    );
  }

  Future<void> _onAddToOrderRequested(
    ProductDetailAddToOrderRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final product = state.product;
    final lines = state.orderLines;
    if (product == null || lines.isEmpty) return;

    await analyticsService.logEvent(
      AnalyticsEvents.productAddedToOrder,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': product.id,
        'items_count': state.totalQuantity,
        'colors_count': lines
            .map((line) => line.variant.colorId)
            .toSet()
            .length,
        // Origin surface (catálogo/busca/favoritos) this addition came from
        // — same `source` parameter/precedent `product_viewed` already logs
        // from this same [ProductDetailState.origin].
        'source': state.origin,
      },
    );
  }

  Future<void> _logViewedIfNeeded(Emitter<ProductDetailState> emit) async {
    final product = state.product;
    if (state.hasLoggedViewed || product == null) return;
    await analyticsService.logEvent(
      AnalyticsEvents.productViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': product.id,
        'source': state.origin,
      },
    );
    if (emit.isDone) return;
    emit(state.copyWith(hasLoggedViewed: true));
  }
}

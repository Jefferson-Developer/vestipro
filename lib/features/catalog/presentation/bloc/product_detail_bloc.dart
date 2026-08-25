import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
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
import '../../../products/domain/value_objects/product_variant_status.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

/// Orchestrates the product detail screen (TASK-078, EPIC-10) — the B2B
/// purchase experience every catalog surface (grid, busca, favoritos,
/// compartilhamento) links into.
///
/// Product, variants, colors and the size grid template are fetched
/// concurrently (each use case call starts its Future immediately; only the
/// final `await` chain is sequential), then availability is resolved once
/// the variant ids are known — composing one single, internally-consistent
/// [ProductDetailState] the whole screen renders from, per the task's
/// "compondo um estado único e consistente" requirement.
///
/// There is no price fetch: no price-list/pricing-engine implementation
/// exists yet (EPIC-11), so [ProductDetailState.isPriceAvailable] is always
/// `false` and this bloc never calculates or caches one — see that getter's
/// doc for the precedent this follows.
@injectable
final class ProductDetailBloc
    extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc({
    required this.getProductById,
    required this.listVariantsByProduct,
    required this.listProductColors,
    required this.getSizeGridTemplateById,
    required this.getVariantAvailability,
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

    // Every call below starts its Future immediately (Dart Futures are
    // eager), so these three requests already run concurrently even though
    // they are awaited one after another — no `Future.wait` needed to keep
    // a single, easily-testable result type per use case.
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

    var hasWarning =
        variantsResult is AppFailure<List<ProductVariant>> ||
        colorsResult is AppFailure<List<ProductColor>> ||
        templateResult is AppFailure<SizeGridTemplate>;

    final availabilityByVariantId = await _fetchAvailability(variants);
    if (emit.isDone) return;
    if (availabilityByVariantId == null) hasWarning = true;

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
        hasAvailabilityWarning: hasWarning,
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
      // Availability failing to load never blocks the rest of the screen —
      // `ProductDetailState.availabilityForVariant` falls back to
      // `VariantAvailability.fromVariant` (a pure derivation of data
      // already fetched on the variant itself, not a client-side stock
      // calculation) while `hasAvailabilityWarning` tells the UI to show
      // that explicitly instead of a silent "tudo pronta entrega".
      AppFailure<VariantAvailabilitySnapshot>() => null,
    };
  }

  void _onColorSelected(
    ProductDetailColorSelected event,
    Emitter<ProductDetailState> emit,
  ) {
    if (event.colorId == state.selectedColorId) return;
    emit(state.copyWith(selectedColorId: event.colorId));
  }

  void _onQuantityChanged(
    ProductDetailQuantityChanged event,
    Emitter<ProductDetailState> emit,
  ) {
    final variant = state.variantForCell(
      colorId: event.colorId,
      sizeId: event.sizeId,
    );
    if (variant == null ||
        !state.availabilityForVariant(variant).acceptsQuantity) {
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

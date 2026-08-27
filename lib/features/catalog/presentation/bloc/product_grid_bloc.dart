import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../pricing/domain/usecases/resolve_price_for_variant_use_case.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../../products/domain/usecases/list_product_variants_by_product_use_case.dart';
import '../../domain/usecases/list_catalog_products_use_case.dart';
import 'product_grid_event.dart';
import 'product_grid_state.dart';

@injectable
final class ProductGridBloc extends Bloc<ProductGridEvent, ProductGridState> {
  ProductGridBloc({
    required this.listCatalogProducts,
    required this.getVariantAvailability,
    this.listVariantsByProduct,
    this.resolvePriceForVariant,
    required this.analyticsService,
  }) : super(const ProductGridState()) {
    on<ProductGridStarted>(_onStarted, transformer: restartable());
    on<ProductGridNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<ProductGridRetried>(_onRetried, transformer: droppable());
    on<ProductGridProductOpened>(_onProductOpened);
  }

  final ListCatalogProductsUseCase listCatalogProducts;
  final GetVariantAvailabilityUseCase getVariantAvailability;
  final ListProductVariantsByProductUseCase? listVariantsByProduct;
  final ResolvePriceForVariantUseCase? resolvePriceForVariant;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    ProductGridStarted event,
    Emitter<ProductGridState> emit,
  ) async {
    emit(
      ProductGridState(
        status: ProductGridLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
      ),
    );
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onNextPageRequested(
    ProductGridNextPageRequested event,
    Emitter<ProductGridState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != ProductGridLoadStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    await _loadPage(emit, cursor: state.cursor, replace: false);
  }

  Future<void> _onRetried(
    ProductGridRetried event,
    Emitter<ProductGridState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(state.copyWith(status: ProductGridLoadStatus.loading));
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onProductOpened(
    ProductGridProductOpened event,
    Emitter<ProductGridState> emit,
  ) async {
    await analyticsService.logEvent(
      AnalyticsEvents.productViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': event.product.id,
        'source': 'catalog_grid',
      },
    );
  }

  Future<void> _loadPage(
    Emitter<ProductGridState> emit, {
    required String? cursor,
    required bool replace,
  }) async {
    final result = await listCatalogProducts(
      organizationId: state.organizationId,
      companyId: state.companyId,
      cursor: cursor,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<ProductCatalogPage>(value: final page):
        final mergedProducts = replace
            ? page.products
            : _mergeProducts(state.products, page.products);
        final availability = await _fetchAvailability(page.products);
        final pricing = await _fetchPrices(page.products);
        if (emit.isDone) return;
        final mergedAvailability = replace
            ? availability
            : <String, VariantAvailability>{
                ...state.availabilityByProductId,
                ...availability,
              };
        final mergedPriceLabels = replace
            ? pricing.$1
            : <String, String>{...state.priceLabelsByProductId, ...pricing.$1};
        final mergedUnpriced = replace
            ? pricing.$2
            : <String>{...state.unpricedProductIds, ...pricing.$2};

        emit(
          state.copyWith(
            status: mergedProducts.isEmpty
                ? ProductGridLoadStatus.empty
                : ProductGridLoadStatus.success,
            products: mergedProducts,
            availabilityByProductId: mergedAvailability,
            priceLabelsByProductId: mergedPriceLabels,
            unpricedProductIds: mergedUnpriced,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            hasMore: page.hasMore,
            isLoadingMore: false,
            hasPricingWarning: pricing.$3,
            clearFailure: true,
          ),
        );
        await _logViewedIfNeeded(emit);
      case AppFailure<ProductCatalogPage>(failure: final failure):
        if (replace) {
          emit(
            state.copyWith(
              status: ProductGridLoadStatus.failure,
              isLoadingMore: false,
              failure: failure,
            ),
          );
        } else {
          emit(state.copyWith(isLoadingMore: false));
        }
    }
  }

  Future<Map<String, VariantAvailability>> _fetchAvailability(
    List<Product> products,
  ) async {
    if (products.isEmpty) return const <String, VariantAvailability>{};
    final result = await getVariantAvailability(
      organizationId: state.organizationId,
      productIds: products.map((product) => product.id),
    );
    return switch (result) {
      AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot) =>
        _availabilityByProductId(products, snapshot),
      AppFailure<VariantAvailabilitySnapshot>() =>
        const <String, VariantAvailability>{},
    };
  }

  Future<(Map<String, String>, Set<String>, bool)> _fetchPrices(
    List<Product> products,
  ) async {
    if (listVariantsByProduct == null || resolvePriceForVariant == null) {
      return (const <String, String>{}, const <String>{}, false);
    }

    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final labels = <String, String>{};
    final unpriced = <String>{};
    var hasWarning = false;

    for (final product in products) {
      final companyId = product.companyId?.trim();
      if (companyId == null || companyId.isEmpty) {
        unpriced.add(product.id);
        continue;
      }

      final variantsResult = await listVariantsByProduct!(
        organizationId: state.organizationId,
        productId: product.id,
      );
      if (variantsResult is AppFailure<List<ProductVariant>>) {
        hasWarning = true;
        continue;
      }

      final activeVariants =
          (variantsResult as AppSuccess<List<ProductVariant>>).value
              .where((variant) => variant.isActive)
              .toList(growable: false);
      if (activeVariants.isEmpty) {
        unpriced.add(product.id);
        continue;
      }

      final resolved = <ResolvedVariantPrice>[];
      for (final variant in activeVariants) {
        final priceResult = await resolvePriceForVariant!(
          organizationId: state.organizationId,
          companyId: companyId,
          productId: product.id,
          variantId: variant.id,
        );
        switch (priceResult) {
          case AppSuccess<ResolvedVariantPrice>(value: final price):
            if (price.hasPrice) resolved.add(price);
          case AppFailure<ResolvedVariantPrice>():
            hasWarning = true;
        }
      }

      if (resolved.isEmpty) {
        unpriced.add(product.id);
        continue;
      }

      final distinctPrices =
          resolved.map((item) => item.price!).toSet().toList(growable: false)
            ..sort();
      labels[product.id] = distinctPrices.length == 1
          ? formatter.format(distinctPrices.first)
          : 'A partir de ${formatter.format(distinctPrices.first)}';
    }

    return (
      Map<String, String>.unmodifiable(labels),
      Set<String>.unmodifiable(unpriced),
      hasWarning,
    );
  }

  Map<String, VariantAvailability> _availabilityByProductId(
    List<Product> products,
    VariantAvailabilitySnapshot snapshot,
  ) {
    final result = <String, VariantAvailability>{};
    for (final product in products) {
      final availability = snapshot.primaryForProduct(product.id);
      if (availability != null) {
        result[product.id] = availability;
      }
    }
    return result;
  }

  List<Product> _mergeProducts(List<Product> current, List<Product> nextPage) {
    final existingIds = current.map((product) => product.id).toSet();
    final newProducts = nextPage.where(
      (product) => !existingIds.contains(product.id),
    );
    return <Product>[...current, ...newProducts];
  }

  Future<void> _logViewedIfNeeded(Emitter<ProductGridState> emit) async {
    if (state.hasLoggedViewed || state.products.isEmpty) return;
    await analyticsService.logEvent(
      AnalyticsEvents.catalogGridViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'products_count': state.products.length,
      },
    );
    if (emit.isDone) return;
    emit(state.copyWith(hasLoggedViewed: true));
  }
}

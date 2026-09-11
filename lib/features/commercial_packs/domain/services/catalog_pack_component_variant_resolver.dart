import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/domain/repositories/product_variant_repository.dart';
import '../../../products/domain/value_objects/product_status.dart';
import '../entities/commercial_pack.dart';
import '../repositories/commercial_pack_repository.dart';
import '../value_objects/pack_component_scope_type.dart';
import 'pack_component_variant_resolver.dart';

/// [PackComponentVariantResolver] backed by the real catalog
/// (`ProductRepository`/`ProductVariantRepository`, EPIC-08/EPIC-09) and by
/// `CommercialPackRepository` itself for the `commercialPack` scope
/// (TASK-208, EPIC-32) — the "materialização real" TASK-207's own completion
/// doc left entirely to this task.
///
/// [PackComponentScopeType.category]/[.collection]/[.color]/[.size] have no
/// direct "give me every variant of this X" query in this codebase today
/// (`ProductRepository.listCatalog` filters *products*, not variants) — this
/// resolver answers them with a bounded scan of [_maxScannedProducts]
/// catalog pages (`_maxScanPages` × `_scanPageSize`), listing each matching
/// product's variants and filtering client-side. This is deliberately not
/// the hot path (catalog browsing/grid rendering never calls this resolver,
/// only pack composition/expansion does), so the extra reads are an
/// accepted, documented cost rather than a new indexed query — narrowing
/// this to a real repository-level filter is left as a follow-up
/// optimization once a real catalog data-warehouse/search index exists
/// (EPIC-31), never a blocker for this task's acceptance criteria.
@LazySingleton(as: PackComponentVariantResolver)
final class CatalogPackComponentVariantResolver
    implements PackComponentVariantResolver {
  const CatalogPackComponentVariantResolver(
    this._productRepository,
    this._productVariantRepository,
    this._commercialPackRepository,
  );

  final ProductRepository _productRepository;
  final ProductVariantRepository _productVariantRepository;
  final CommercialPackRepository _commercialPackRepository;

  static const int _scanPageSize = 50;
  static const int _maxScanPages = 10;

  @override
  Future<AppResult<List<ResolvedComponentVariant>>> resolveSellableVariants({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  }) async {
    switch (scopeType) {
      case PackComponentScopeType.variant:
        return _resolveVariantScope(
          organizationId: organizationId,
          variantId: scopeReferenceId,
        );
      case PackComponentScopeType.product:
        return _resolveProductScope(
          organizationId: organizationId,
          productId: scopeReferenceId,
        );
      case PackComponentScopeType.category:
        return _resolveCatalogScope(
          organizationId: organizationId,
          companyId: companyId,
          filter: CatalogFilter(categoryId: scopeReferenceId),
        );
      case PackComponentScopeType.collection:
        return _resolveCatalogScope(
          organizationId: organizationId,
          companyId: companyId,
          filter: CatalogFilter(collectionId: scopeReferenceId),
        );
      case PackComponentScopeType.color:
        return _resolveCatalogScope(
          organizationId: organizationId,
          companyId: companyId,
          filter: CatalogFilter(colorIds: <String>{scopeReferenceId}),
          variantFilter: (variant) => variant.colorId == scopeReferenceId,
        );
      case PackComponentScopeType.size:
        return _resolveCatalogScope(
          organizationId: organizationId,
          companyId: companyId,
          filter: CatalogFilter.empty,
          variantFilter: (variant) => variant.sizeId == scopeReferenceId,
        );
      case PackComponentScopeType.commercialPack:
        // Nested-pack composition is never a flat variant list — the caller
        // (`ExpandCommercialPackToOrderItemsUseCase`) recurses into the
        // nested pack's own components instead of asking this resolver.
        return const AppFailure<List<ResolvedComponentVariant>>(
          ValidationFailure(
            'commercialPack scope must be expanded recursively by the '
            'caller, never resolved to a flat variant list.',
            code: 'pack_component_scope_commercial_pack_unsupported',
          ),
        );
    }
  }

  @override
  Future<AppResult<bool>> isReferenceValid({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  }) async {
    switch (scopeType) {
      case PackComponentScopeType.variant:
        final result = await _resolveVariantScope(
          organizationId: organizationId,
          variantId: scopeReferenceId,
        );
        return switch (result) {
          AppSuccess<List<ResolvedComponentVariant>>(value: final variants) =>
            AppSuccess<bool>(variants.isNotEmpty),
          AppFailure<List<ResolvedComponentVariant>>(failure: final failure) =>
            AppFailure<bool>(failure),
        };
      case PackComponentScopeType.product:
        final product = await _activeProduct(
          organizationId: organizationId,
          productId: scopeReferenceId,
        );
        return switch (product) {
          AppSuccess<Product?>(value: final value) => AppSuccess<bool>(
            value != null,
          ),
          AppFailure<Product?>(failure: final failure) => AppFailure<bool>(
            failure,
          ),
        };
      case PackComponentScopeType.category:
      case PackComponentScopeType.collection:
      case PackComponentScopeType.color:
      case PackComponentScopeType.size:
        // These scopes are valid as long as *some* sellable variant
        // currently matches them — an empty catalog match is a composition
        // problem for `ValidateCommercialPackCompositionUseCase` to flag,
        // not a crash here.
        final result = await resolveSellableVariants(
          organizationId: organizationId,
          companyId: companyId,
          scopeType: scopeType,
          scopeReferenceId: scopeReferenceId,
        );
        return switch (result) {
          AppSuccess<List<ResolvedComponentVariant>>(value: final variants) =>
            AppSuccess<bool>(variants.isNotEmpty),
          AppFailure<List<ResolvedComponentVariant>>(failure: final failure) =>
            AppFailure<bool>(failure),
        };
      case PackComponentScopeType.commercialPack:
        final packResult = await _commercialPackRepository.getById(
          organizationId: organizationId,
          id: scopeReferenceId,
        );
        return switch (packResult) {
          AppSuccess<CommercialPack?>(value: final pack) => AppSuccess<bool>(
            pack != null && pack.deletedAt == null,
          ),
          AppFailure<CommercialPack?>(failure: final failure) =>
            AppFailure<bool>(failure),
        };
    }
  }

  Future<AppResult<List<ResolvedComponentVariant>>> _resolveVariantScope({
    required String organizationId,
    required String variantId,
  }) async {
    final variantResult = await _productVariantRepository.getById(
      organizationId: organizationId,
      id: variantId,
    );
    if (variantResult case AppFailure<ProductVariant>(failure: final failure)) {
      if (failure is NotFoundFailure) {
        return const AppSuccess<List<ResolvedComponentVariant>>(
          <ResolvedComponentVariant>[],
        );
      }
      return AppFailure<List<ResolvedComponentVariant>>(failure);
    }
    final variant = (variantResult as AppSuccess<ProductVariant>).value;
    if (!variant.isActive) {
      return const AppSuccess<List<ResolvedComponentVariant>>(
        <ResolvedComponentVariant>[],
      );
    }
    final product = await _activeProduct(
      organizationId: organizationId,
      productId: variant.productId,
    );
    if (product case AppFailure<Product?>(failure: final failure)) {
      return AppFailure<List<ResolvedComponentVariant>>(failure);
    }
    if ((product as AppSuccess<Product?>).value == null) {
      return const AppSuccess<List<ResolvedComponentVariant>>(
        <ResolvedComponentVariant>[],
      );
    }
    return AppSuccess<List<ResolvedComponentVariant>>(
      <ResolvedComponentVariant>[
        (variantId: variant.id, productId: variant.productId),
      ],
    );
  }

  Future<AppResult<List<ResolvedComponentVariant>>> _resolveProductScope({
    required String organizationId,
    required String productId,
  }) async {
    final product = await _activeProduct(
      organizationId: organizationId,
      productId: productId,
    );
    if (product case AppFailure<Product?>(failure: final failure)) {
      return AppFailure<List<ResolvedComponentVariant>>(failure);
    }
    if ((product as AppSuccess<Product?>).value == null) {
      return const AppSuccess<List<ResolvedComponentVariant>>(
        <ResolvedComponentVariant>[],
      );
    }

    final variantsResult = await _productVariantRepository.listByProduct(
      organizationId: organizationId,
      productId: productId,
    );
    if (variantsResult case AppFailure<List<ProductVariant>>(
      failure: final failure,
    )) {
      return AppFailure<List<ResolvedComponentVariant>>(failure);
    }
    final variants = (variantsResult as AppSuccess<List<ProductVariant>>).value;
    return AppSuccess<List<ResolvedComponentVariant>>(
      <ResolvedComponentVariant>[
        for (final variant in variants)
          if (variant.isActive)
            (variantId: variant.id, productId: variant.productId),
      ],
    );
  }

  /// Bounded scan behind `category`/`collection`/`color`/`size` scope — see
  /// this class's own doc for why this is a scan rather than an indexed
  /// query.
  Future<AppResult<List<ResolvedComponentVariant>>> _resolveCatalogScope({
    required String organizationId,
    String? companyId,
    required CatalogFilter filter,
    bool Function(ProductVariant variant)? variantFilter,
  }) async {
    final resolved = <ResolvedComponentVariant>[];
    String? cursor;
    var scannedPages = 0;

    while (scannedPages < _maxScanPages) {
      final pageResult = await _productRepository.listCatalog(
        organizationId: organizationId,
        companyId: companyId,
        cursor: cursor,
        limit: _scanPageSize,
        filter: filter,
      );
      if (pageResult case AppFailure<ProductCatalogPage>(
        failure: final failure,
      )) {
        return AppFailure<List<ResolvedComponentVariant>>(failure);
      }
      final page = (pageResult as AppSuccess<ProductCatalogPage>).value;
      scannedPages++;

      for (final product in page.products) {
        if (product.status != ProductStatus.active) continue;
        final variantsResult = await _productVariantRepository.listByProduct(
          organizationId: organizationId,
          productId: product.id,
        );
        if (variantsResult case AppFailure<List<ProductVariant>>(
          failure: final failure,
        )) {
          return AppFailure<List<ResolvedComponentVariant>>(failure);
        }
        final variants =
            (variantsResult as AppSuccess<List<ProductVariant>>).value;
        for (final variant in variants) {
          if (!variant.isActive) continue;
          if (variantFilter != null && !variantFilter(variant)) continue;
          resolved.add((variantId: variant.id, productId: variant.productId));
        }
      }

      if (!page.hasMore || page.nextCursor == null) break;
      cursor = page.nextCursor;
    }

    return AppSuccess<List<ResolvedComponentVariant>>(
      List<ResolvedComponentVariant>.unmodifiable(resolved),
    );
  }

  Future<AppResult<Product?>> _activeProduct({
    required String organizationId,
    required String productId,
  }) async {
    final result = await _productRepository.getById(
      organizationId: organizationId,
      id: productId,
    );
    if (result case AppFailure<Product>(failure: final failure)) {
      if (failure is NotFoundFailure) {
        return const AppSuccess<Product?>(null);
      }
      return AppFailure<Product?>(failure);
    }
    final product = (result as AppSuccess<Product>).value;
    return AppSuccess<Product?>(
      product.status == ProductStatus.active ? product : null,
    );
  }
}

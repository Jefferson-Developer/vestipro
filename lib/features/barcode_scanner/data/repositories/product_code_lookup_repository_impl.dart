import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_search_result.dart';
import '../../../products/domain/entities/product_search_source.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/domain/repositories/product_variant_repository.dart';
import '../../../products/domain/usecases/search_products_use_case.dart';
import '../../../products/domain/value_objects/product_variant_status.dart';
import '../../domain/entities/alternate_product_code.dart';
import '../../domain/entities/product_code_match.dart';
import '../../domain/entities/product_code_resolution.dart';
import '../../domain/repositories/product_code_lookup_repository.dart';
import '../../domain/services/scanned_code_classifier.dart';
import '../../domain/value_objects/internal_qr_payload.dart';
import '../../domain/value_objects/scanned_code_format.dart';
import '../datasources/alternate_product_code_local_data_source.dart';

/// Resolution algorithm behind [ProductCodeLookupRepository] (TASK-216).
///
/// Tries, in order, the cheapest/most-specific match first: a registered
/// [AlternateProductCode], then an exact variant SKU/EAN, then an exact
/// product-level SKU/reference/EAN (which may resolve to several active
/// variants of that one product — see
/// [ProductCodeResolutionStatus.multipleMatches]). The product-level step
/// reuses [SearchProductsUseCase] — first against its offline index
/// (works with no network at all, satisfying the "índice local offline"
/// requirement without a second, redundant local cache), then, only if
/// that finds nothing, against the remote index in case the offline index
/// is merely stale; a remote failure at that point (typically "no network")
/// degrades to "not found" rather than surfacing a hard error, since the
/// offline index already gave a definitive answer.
@LazySingleton(as: ProductCodeLookupRepository)
final class ProductCodeLookupRepositoryImpl
    implements ProductCodeLookupRepository {
  const ProductCodeLookupRepositoryImpl({
    required this.variantRepository,
    required this.productRepository,
    required this.searchProducts,
    required this.alternateCodeDataSource,
  });

  final ProductVariantRepository variantRepository;
  final ProductRepository productRepository;
  final SearchProductsUseCase searchProducts;
  final AlternateProductCodeLocalDataSource alternateCodeDataSource;

  @override
  Future<AppResult<ProductCodeResolution>> resolveCode({
    required String organizationId,
    required String rawCode,
  }) async {
    try {
      final classified = ScannedCodeClassifier.classify(rawCode);
      if (classified.format == ScannedCodeFormat.unknown) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }

      if (classified.format == ScannedCodeFormat.internalQr) {
        return _resolveInternalQr(
          organizationId: organizationId,
          rawCode: rawCode,
          raw: classified.rawValue,
        );
      }

      final comparableCode = ScannedCodeClassifier.comparableValue(classified);

      final alternate = await alternateCodeDataSource.findByCode(
        organizationId: organizationId,
        code: comparableCode,
      );
      if (alternate != null) {
        return _resolveByProductAndVariantId(
          organizationId: organizationId,
          rawCode: rawCode,
          productId: alternate.productId,
          variantId: alternate.variantId,
        );
      }

      final variantMatch = await _findExactVariantMatch(
        organizationId: organizationId,
        comparableCode: comparableCode,
      );
      if (variantMatch != null) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.single(rawCode, variantMatch),
        );
      }

      final productMatches = await _findExactProductMatches(
        organizationId: organizationId,
        comparableCode: comparableCode,
      );
      if (productMatches.isEmpty) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }
      if (productMatches.length == 1) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.single(rawCode, productMatches.single),
        );
      }
      return AppSuccess<ProductCodeResolution>(
        ProductCodeResolution.multiple(rawCode, productMatches),
      );
    } on AppException catch (exception) {
      return AppFailure<ProductCodeResolution>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ProductCodeResolution>(
        UnexpectedFailure(
          'Unexpected error resolving product code.',
          code: 'product_code_resolve_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<AlternateProductCode>> registerAlternateCode({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
  }) async {
    try {
      final classified = ScannedCodeClassifier.classify(code);
      final normalized = ScannedCodeClassifier.comparableValue(classified);
      final registered = await alternateCodeDataSource.upsert(
        AlternateProductCode(
          organizationId: organizationId,
          code: normalized,
          productId: productId,
          variantId: variantId,
          registeredAt: DateTime.now().toUtc(),
          registeredBy: registeredBy,
        ),
      );
      return AppSuccess<AlternateProductCode>(registered);
    } catch (exception) {
      return AppFailure<AlternateProductCode>(
        UnexpectedFailure(
          'Unexpected error registering alternate product code.',
          code: 'alternate_product_code_register_unexpected',
          cause: exception,
        ),
      );
    }
  }

  /// A well-formed internal QR is only ever a *hint*, never an authorization
  /// token (see `InternalQrPayload` doc): a payload minted for a different
  /// organization than [organizationId] resolves to "not found" instead of
  /// leaking whether the variant exists in that other tenant, and instead of
  /// ever switching the caller into that tenant.
  Future<AppResult<ProductCodeResolution>> _resolveInternalQr({
    required String organizationId,
    required String rawCode,
    required String raw,
  }) async {
    InternalQrPayload payload;
    try {
      payload = InternalQrPayload.parse(raw);
    } on FormatException {
      return AppSuccess<ProductCodeResolution>(
        ProductCodeResolution.notFound(rawCode),
      );
    }
    if (payload.organizationId != organizationId) {
      return AppSuccess<ProductCodeResolution>(
        ProductCodeResolution.notFound(rawCode),
      );
    }
    return _resolveByProductAndVariantId(
      organizationId: organizationId,
      rawCode: rawCode,
      productId: null,
      variantId: payload.variantId,
    );
  }

  Future<AppResult<ProductCodeResolution>> _resolveByProductAndVariantId({
    required String organizationId,
    required String rawCode,
    required String? productId,
    required String? variantId,
  }) async {
    if (variantId != null) {
      final variantResult = await variantRepository.getById(
        organizationId: organizationId,
        id: variantId,
      );
      if (variantResult is AppFailure<ProductVariant>) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }
      final variant = (variantResult as AppSuccess<ProductVariant>).value;
      if (!variant.isActive) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }
      final productResult = await productRepository.getById(
        organizationId: organizationId,
        id: variant.productId,
      );
      if (productResult is AppFailure<Product>) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }
      final product = (productResult as AppSuccess<Product>).value;
      return AppSuccess<ProductCodeResolution>(
        ProductCodeResolution.single(
          rawCode,
          ProductCodeMatch(product: product, variant: variant),
        ),
      );
    }

    if (productId != null) {
      final productResult = await productRepository.getById(
        organizationId: organizationId,
        id: productId,
      );
      if (productResult is AppFailure<Product>) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
      }
      final product = (productResult as AppSuccess<Product>).value;
      final matches = await _activeVariantMatchesForProduct(
        organizationId: organizationId,
        product: product,
      );
      if (matches.isEmpty) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.single(
            rawCode,
            ProductCodeMatch(product: product),
          ),
        );
      }
      if (matches.length == 1) {
        return AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.single(rawCode, matches.single),
        );
      }
      return AppSuccess<ProductCodeResolution>(
        ProductCodeResolution.multiple(rawCode, matches),
      );
    }

    return AppSuccess<ProductCodeResolution>(
      ProductCodeResolution.notFound(rawCode),
    );
  }

  Future<ProductCodeMatch?> _findExactVariantMatch({
    required String organizationId,
    required String comparableCode,
  }) async {
    final variantsResult = await variantRepository.listByOrganization(
      organizationId,
    );
    if (variantsResult is AppFailure<List<ProductVariant>>) return null;
    final variants = (variantsResult as AppSuccess<List<ProductVariant>>).value;
    for (final variant in variants) {
      if (!variant.isActive) continue;
      if (variant.sku.value == comparableCode ||
          variant.ean?.digits == comparableCode) {
        final productResult = await productRepository.getById(
          organizationId: organizationId,
          id: variant.productId,
        );
        if (productResult is AppFailure<Product>) return null;
        return ProductCodeMatch(
          product: (productResult as AppSuccess<Product>).value,
          variant: variant,
        );
      }
    }
    return null;
  }

  Future<List<ProductCodeMatch>> _findExactProductMatches({
    required String organizationId,
    required String comparableCode,
  }) async {
    final offlineProduct = await _searchExactProduct(
      organizationId: organizationId,
      comparableCode: comparableCode,
      source: ProductSearchSource.offline,
    );
    final product =
        offlineProduct ??
        await _searchExactProduct(
          organizationId: organizationId,
          comparableCode: comparableCode,
          source: ProductSearchSource.remote,
        );
    if (product == null) return const <ProductCodeMatch>[];
    return _activeVariantMatchesForProduct(
      organizationId: organizationId,
      product: product,
    );
  }

  Future<Product?> _searchExactProduct({
    required String organizationId,
    required String comparableCode,
    required ProductSearchSource source,
  }) async {
    final result = await searchProducts(
      organizationId: organizationId,
      query: comparableCode,
      source: source,
    );
    if (result is! AppSuccess<ProductSearchResult>) return null;
    final products = result.value.products;
    for (final product in products) {
      if (product.sku.value == comparableCode ||
          product.reference.trim().toUpperCase() == comparableCode ||
          product.ean?.digits == comparableCode) {
        return product;
      }
    }
    return null;
  }

  Future<List<ProductCodeMatch>> _activeVariantMatchesForProduct({
    required String organizationId,
    required Product product,
  }) async {
    final variantsResult = await variantRepository.listByProduct(
      organizationId: organizationId,
      productId: product.id,
    );
    if (variantsResult is AppFailure<List<ProductVariant>>) {
      return const <ProductCodeMatch>[];
    }
    final variants = (variantsResult as AppSuccess<List<ProductVariant>>).value
        .where((variant) => variant.status == ProductVariantStatus.active)
        .toList(growable: false);
    return variants
        .map((variant) => ProductCodeMatch(product: product, variant: variant))
        .toList(growable: false);
  }
}

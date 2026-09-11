import '../../../../core/utils/utils.dart';
import '../entities/alternate_product_code.dart';
import '../entities/product_code_resolution.dart';

/// Resolves a scanned/typed code to a product/variant, and lets an
/// authorized profile register a code an unknown scan surfaced (TASK-216).
///
/// Implementations never bypass price/stock/RBAC: resolving a code only ever
/// identifies *which* product/variant the seller meant — the exact same
/// `ProductDetailPage`/order-addition flow every manually picked product
/// already goes through is what actually validates price, availability and
/// permissions afterward.
abstract interface class ProductCodeLookupRepository {
  Future<AppResult<ProductCodeResolution>> resolveCode({
    required String organizationId,
    required String rawCode,
  });

  /// Registers [code] as an extra way to find [productId]/[variantId] going
  /// forward (TASK-216 "sugestão de cadastro/correção"). Callers must
  /// already have re-checked `Capability.catalogManage` themselves — see
  /// `RegisterUnknownProductCodeUseCase`, the only intended caller.
  Future<AppResult<AlternateProductCode>> registerAlternateCode({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
  });
}

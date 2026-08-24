import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../value_objects/sku.dart';

/// Domain contract for Product persistence, decoupled from Firestore/Drift.
///
/// TASK-064 modeled the entity and the basic read use case with only
/// [getById] as a contract-only repository, no concrete implementation.
/// TASK-065 adds [existsBySku]/[create]/[update] plus a first concrete
/// implementation (`SharedPreferencesProductRepository`), the same
/// local-store-until-outbox-exists precedent `SharedPreferencesCustomerRepository`
/// (TASK-048/049) already set.
abstract interface class ProductRepository {
  /// Whether an active (non soft-deleted) Product with [sku] already exists
  /// in [organizationId]. [excludingProductId] lets an update check
  /// uniqueness against every other product without flagging itself as a
  /// duplicate. SKU uniqueness is scoped by organization, mirroring
  /// `CustomerRepository.existsByDocument`.
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  });

  Future<AppResult<Product>> create({required Product product});

  Future<AppResult<Product>> update({required Product product});

  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  });
}

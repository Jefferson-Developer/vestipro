import '../../../../core/utils/utils.dart';
import '../entities/product_collection_link.dart';

/// Contract for reading and writing `ProductCollectionLink` join records
/// scoped under one Organization (TASK-066).
abstract interface class ProductCollectionLinkRepository {
  Future<AppResult<ProductCollectionLink>> create({
    required ProductCollectionLink link,
  });

  /// Every non-deleted link of [productId], in no particular order.
  Future<AppResult<List<ProductCollectionLink>>> listByProduct({
    required String organizationId,
    required String productId,
  });

  /// Every non-deleted link of [collectionId], used to list the Products of
  /// a Collection (`ListProductsByCollectionUseCase`) and, later, by the
  /// catalog filter (EPIC-10) reusing the same data.
  Future<AppResult<List<ProductCollectionLink>>> listByCollection({
    required String organizationId,
    required String collectionId,
  });

  /// Removes the single link between [productId] and [collectionId], if
  /// any. Succeeds (returns `true`) even when no such link exists.
  Future<AppResult<bool>> deleteByProductAndCollection({
    required String organizationId,
    required String productId,
    required String collectionId,
  });

  /// Removes every link of [productId], used when the Organization does not
  /// allow multiple Collections per Product and a new association must
  /// replace the previous one(s) — see
  /// `AssociateProductWithCollectionUseCase`.
  Future<AppResult<bool>> deleteAllByProduct({
    required String organizationId,
    required String productId,
  });
}

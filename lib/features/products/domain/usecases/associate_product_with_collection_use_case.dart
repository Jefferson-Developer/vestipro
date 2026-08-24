import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';
import '../entities/product_collection_link.dart';
import '../repositories/collection_repository.dart';
import '../repositories/product_collection_link_repository.dart';
import '../value_objects/collection_status.dart';

/// Associates a Product with a `Collection` (TASK-066).
///
/// Whether a Product can belong to more than one Collection at once is
/// controlled by the caller through
/// [allowMultipleCollectionsPerProduct] — resolved by the caller from
/// `OrganizationSettings.allowMultipleCollectionsPerProduct`, never
/// re-fetched here, so this use case stays independent from the
/// organizations feature:
///
/// * `false` (the default): any existing link of [productId] in
///   [organizationId] is removed first, so the Product only ever belongs to
///   the Collection it was most recently associated with — an explicit,
///   visible replace, never a silent extra membership (TASK-066 business
///   rule: "comportamento explícito, nunca silencioso").
/// * `true`: previous link(s) are kept and this one is added alongside them
///   (N:N). Associating the same pair twice is rejected as a conflict
///   instead of silently creating a duplicate link.
///
/// Associating a Product with a closed Collection is rejected — closing a
/// Collection stops it from accepting *new* associations, even though
/// existing ones (and the Products themselves) remain untouched.
@injectable
final class AssociateProductWithCollectionUseCase {
  AssociateProductWithCollectionUseCase(
    this._linkRepository,
    this._collectionRepository,
  );

  final ProductCollectionLinkRepository _linkRepository;
  final CollectionRepository _collectionRepository;

  Future<AppResult<ProductCollectionLink>> call({
    required String id,
    required String organizationId,
    required String productId,
    required String collectionId,
    required bool allowMultipleCollectionsPerProduct,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedProductId = productId.trim();
    final trimmedCollectionId = collectionId.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedProductId.isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (trimmedCollectionId.isEmpty) {
      fieldErrors['collectionId'] = 'CollectionId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ProductCollectionLink>(
        ValidationFailure(
          'Invalid product-collection association payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_collection_link_payload',
        ),
      );
    }

    final collectionResult = await _collectionRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedCollectionId,
    );
    if (collectionResult is AppFailure<Collection>) {
      return AppFailure<ProductCollectionLink>(collectionResult.failure);
    }
    final collection = (collectionResult as AppSuccess<Collection>).value;
    if (collection.status == CollectionStatus.closed) {
      return const AppFailure<ProductCollectionLink>(
        ConflictFailure(
          'Não é possível associar um produto a uma coleção encerrada.',
          code: 'collection_closed',
        ),
      );
    }

    if (!allowMultipleCollectionsPerProduct) {
      final removeResult = await _linkRepository.deleteAllByProduct(
        organizationId: trimmedOrganizationId,
        productId: trimmedProductId,
      );
      if (removeResult is AppFailure<bool>) {
        return AppFailure<ProductCollectionLink>(removeResult.failure);
      }
    } else {
      final existingLinksResult = await _linkRepository.listByProduct(
        organizationId: trimmedOrganizationId,
        productId: trimmedProductId,
      );
      if (existingLinksResult is AppFailure<List<ProductCollectionLink>>) {
        return AppFailure<ProductCollectionLink>(existingLinksResult.failure);
      }
      final alreadyLinked =
          (existingLinksResult as AppSuccess<List<ProductCollectionLink>>).value
              .any((link) => link.collectionId == trimmedCollectionId);
      if (alreadyLinked) {
        return const AppFailure<ProductCollectionLink>(
          ConflictFailure(
            'Este produto já está associado a esta coleção.',
            code: 'product_collection_link_already_exists',
          ),
        );
      }
    }

    final link = ProductCollectionLink(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      productId: trimmedProductId,
      collectionId: trimmedCollectionId,
      createdAt: DateTime.now().toUtc(),
      createdBy: trimmedCreatedBy,
    );

    return _linkRepository.create(link: link);
  }
}

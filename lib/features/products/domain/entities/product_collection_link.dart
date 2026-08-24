import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_collection_link.freezed.dart';

/// Join record associating one Product with one `Collection` (TASK-066).
///
/// Most Organizations keep at most one active link per Product —
/// `AssociateProductWithCollectionUseCase` removes any previous link before
/// creating a new one whenever
/// `OrganizationSettings.allowMultipleCollectionsPerProduct` is `false`.
/// This entity is what makes the *N:N* case possible: when that flag is
/// `true`, a Product can hold more than one [ProductCollectionLink] at once
/// (e.g. a continuous product carried in both a core collection and a
/// seasonal drop), each one independently created/removed.
///
/// This is deliberately kept separate from `Product.collectionId` (the
/// single free-text field the cadastro form sets today, TASK-065): unifying
/// both is left as a documented pendency for when the Product form stops
/// treating collection as free text (see TASK-066 completion notes).
@freezed
abstract class ProductCollectionLink with _$ProductCollectionLink {
  const factory ProductCollectionLink({
    required String id,
    required String organizationId,
    required String productId,
    required String collectionId,
    required DateTime createdAt,
    required String createdBy,
  }) = _ProductCollectionLink;
}

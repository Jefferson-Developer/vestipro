import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/collection_status.dart';

part 'collection.freezed.dart';

/// A fashion calendar Collection (TASK-066): the grouping Organizations use
/// to organize Products by drop/season, e.g. "Verão 2026" or "Inverno Kids
/// 2026". Belongs to exactly one [organizationId] — never shared between
/// tenants.
///
/// [seasonId] points at a `Season` of the same Organization; nullable
/// because an Organization may create a Collection before assigning its
/// season, mirroring how `Product.collectionId`/`Product.seasonId` are both
/// optional (TASK-064).
///
/// [status] only ever moves `active -> closed` through
/// `CloseCollectionUseCase`; [CreateCollectionUseCase] never accepts it as a
/// parameter, the same "never accept the terminal status at creation time"
/// guarantee `CreateProductUseCase` already applies to `ProductStatus`.
@freezed
abstract class Collection with _$Collection {
  const Collection._();

  const factory Collection({
    required String id,
    required String organizationId,
    required String name,
    String? seasonId,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    required CollectionStatus status,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Collection;

  /// Whether this Collection should still be offered as a target for new
  /// Product associations/catalog filters.
  bool get isActive => status == CollectionStatus.active && deletedAt == null;
}

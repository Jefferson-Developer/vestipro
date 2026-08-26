import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/catalog_share_outcome.dart';
import '../value_objects/catalog_share_scope.dart';
import 'catalog_share_item.dart';

part 'catalog_share_preview.freezed.dart';

/// What `CatalogSharePublicPage` (TASK-081, EPIC-10) receives about a share
/// link — the **public, unauthenticated recipient's** view, mirroring
/// `functions/src/catalog/catalog-share-shared.ts`'s
/// `CatalogSharePreviewResponse` exactly.
///
/// [items]/[scope]/[collectionName]/[expiresAt] are only ever populated when
/// [outcome] is [CatalogShareOutcome.valid] — for any other outcome they are
/// `null`/empty by construction (the callable never sends them), matching
/// TASK-081's rule that an expired/revoked link must never leak what it used
/// to expose.
@freezed
abstract class CatalogSharePreview with _$CatalogSharePreview {
  const factory CatalogSharePreview({
    required CatalogShareOutcome outcome,
    String? organizationName,
    CatalogShareScope? scope,
    @Default(<CatalogShareItem>[]) List<CatalogShareItem> items,
    String? collectionName,
    DateTime? expiresAt,
  }) = _CatalogSharePreview;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/catalog_share_scope.dart';
import 'catalog_share_item.dart';

part 'catalog_share.freezed.dart';

/// A catalog share record, as its **creator** (or an OWNER/ADMIN auditing
/// the organization) sees it (TASK-081, EPIC-10) — mirrors
/// `functions/src/catalog/catalog-share-shared.ts`'s `CatalogShareResponse`.
///
/// Never rendered to the public/anonymous recipient of the share link — see
/// `CatalogSharePreview` for that restricted view. `status`/`openCount`/
/// `firstOpenedAt`/`lastOpenedAt` are exactly what let the vendor see, on
/// their own side, "se e quando o link foi aberto" (TASK-081's acceptance
/// criteria), without ever exposing that same information to the visitor.
@freezed
abstract class CatalogShare with _$CatalogShare {
  const CatalogShare._();

  const factory CatalogShare({
    required String id,
    required String organizationId,
    required CatalogShareScope scope,
    required List<CatalogShareItem> items,
    String? collectionId,
    String? collectionName,
    required bool isRevoked,
    required int openCount,
    DateTime? firstOpenedAt,
    DateTime? lastOpenedAt,
    required DateTime expiresAt,
    required String createdBy,
    required String createdByName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CatalogShare;

  /// Whether this share is still usable *right now*, computed the same way
  /// the server does (`resolveCatalogShareOutcome`) — never trusts a stale
  /// client cache of "is it expired yet".
  bool isActiveAt(DateTime now) => !isRevoked && expiresAt.isAfter(now);
}

import '../../domain/entities/catalog_share_item.dart';
import '../../domain/value_objects/catalog_share_scope.dart';

sealed class CatalogShareSheetEvent {
  const CatalogShareSheetEvent();
}

/// Starts the sheet: immediately creates the share (TASK-081 — sharing is a
/// single tap, there is no separate "confirm" step once the caller already
/// picked what to share) and, once created, keeps the request payload
/// around so [CatalogShareSheetRetried] can resend the exact same thing
/// after a failure.
final class CatalogShareSheetStarted extends CatalogShareSheetEvent {
  const CatalogShareSheetStarted({
    required this.organizationId,
    required this.scope,
    required this.items,
    this.collectionId,
    this.collectionName,
  });

  final String organizationId;
  final CatalogShareScope scope;
  final List<CatalogShareItem> items;
  final String? collectionId;
  final String? collectionName;
}

/// Retries creation with the exact same payload [CatalogShareSheetStarted]
/// was given, after a failure.
final class CatalogShareSheetRetried extends CatalogShareSheetEvent {
  const CatalogShareSheetRetried();
}

/// Re-reads the just-created share to refresh `openCount`/`lastOpenedAt`
/// (TASK-081: "vendedor consegue ver... se e quando o link foi aberto").
final class CatalogShareSheetRefreshRequested extends CatalogShareSheetEvent {
  const CatalogShareSheetRefreshRequested();
}

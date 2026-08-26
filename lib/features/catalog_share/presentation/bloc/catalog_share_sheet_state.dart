import '../../../../core/errors/errors.dart';
import '../../domain/entities/catalog_share.dart';
import '../../domain/entities/catalog_share_item.dart';
import '../../domain/entities/issued_catalog_share.dart';
import '../../domain/value_objects/catalog_share_scope.dart';

enum CatalogShareSheetStatus { initial, submitting, success, failure }

final class CatalogShareSheetState {
  const CatalogShareSheetState({
    this.status = CatalogShareSheetStatus.initial,
    this.organizationId = '',
    this.scope = CatalogShareScope.product,
    this.items = const <CatalogShareItem>[],
    this.collectionId,
    this.collectionName,
    this.issuedShare,
    this.refreshedShare,
    this.isRefreshing = false,
    this.failure,
  });

  final CatalogShareSheetStatus status;

  // The last-requested payload, kept around so `CatalogShareSheetRetried`
  // can resend exactly what `CatalogShareSheetStarted` was given.
  final String organizationId;
  final CatalogShareScope scope;
  final List<CatalogShareItem> items;
  final String? collectionId;
  final String? collectionName;

  final IssuedCatalogShare? issuedShare;

  /// The most recently re-read [CatalogShare] (`openCount`/`lastOpenedAt`
  /// refreshed), or `null` if [CatalogShareSheetRefreshRequested] was never
  /// dispatched yet — callers should fall back to
  /// `issuedShare.share` (always `openCount: 0`) until this is set.
  final CatalogShare? refreshedShare;
  final bool isRefreshing;

  final Failure? failure;

  /// The share to render — [refreshedShare] once available, otherwise the
  /// one just returned by creation.
  CatalogShare? get currentShare => refreshedShare ?? issuedShare?.share;

  CatalogShareSheetState copyWith({
    CatalogShareSheetStatus? status,
    String? organizationId,
    CatalogShareScope? scope,
    List<CatalogShareItem>? items,
    String? collectionId,
    String? collectionName,
    IssuedCatalogShare? issuedShare,
    CatalogShare? refreshedShare,
    bool? isRefreshing,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CatalogShareSheetState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      scope: scope ?? this.scope,
      items: items ?? this.items,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      issuedShare: issuedShare ?? this.issuedShare,
      refreshedShare: refreshedShare ?? this.refreshedShare,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

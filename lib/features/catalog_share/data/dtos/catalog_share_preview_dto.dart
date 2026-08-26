import '../../../../core/errors/errors.dart';
import 'catalog_share_item_dto.dart';

/// Plain-JSON shape of `getCatalogShareLink`'s callable response
/// (TASK-081, `functions/src/catalog/get-catalog-share-link.ts`'s
/// `GetCatalogShareLinkResponse`).
final class CatalogSharePreviewDto {
  const CatalogSharePreviewDto({
    required this.outcome,
    this.organizationName,
    this.scope,
    required this.items,
    this.collectionName,
    this.expiresAt,
  });

  factory CatalogSharePreviewDto.fromJson(Map<String, dynamic> json) {
    final outcome = json['outcome'];
    final organizationName = json['organizationName'];
    final scope = json['scope'];
    final rawItems = json['items'];
    final collectionName = json['collectionName'];
    final expiresAt = json['expiresAt'];

    if (outcome is! String ||
        (organizationName != null && organizationName is! String) ||
        (scope != null && scope is! String) ||
        rawItems is! List ||
        (collectionName != null && collectionName is! String) ||
        (expiresAt != null && expiresAt is! String)) {
      throw const ServerException(
        'Unexpected getCatalogShareLink callable response shape.',
        code: 'invalid_catalog_share_preview_response',
      );
    }

    return CatalogSharePreviewDto(
      outcome: outcome,
      organizationName: organizationName as String?,
      scope: scope as String?,
      items: rawItems
          .map(
            (item) => CatalogShareItemDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      collectionName: collectionName as String?,
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt as String),
    );
  }

  final String outcome;
  final String? organizationName;
  final String? scope;
  final List<CatalogShareItemDto> items;
  final String? collectionName;
  final DateTime? expiresAt;
}

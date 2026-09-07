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
    this.brandingLogoUrl,
    this.brandingPrimaryColorHex,
  });

  factory CatalogSharePreviewDto.fromJson(Map<String, dynamic> json) {
    final outcome = json['outcome'];
    final organizationName = json['organizationName'];
    final scope = json['scope'];
    final rawItems = json['items'];
    final collectionName = json['collectionName'];
    final expiresAt = json['expiresAt'];
    final brandingLogoUrl = json['brandingLogoUrl'];
    final brandingPrimaryColorHex = json['brandingPrimaryColorHex'];

    if (outcome is! String ||
        (organizationName != null && organizationName is! String) ||
        (scope != null && scope is! String) ||
        rawItems is! List ||
        (collectionName != null && collectionName is! String) ||
        (expiresAt != null && expiresAt is! String) ||
        (brandingLogoUrl != null && brandingLogoUrl is! String) ||
        (brandingPrimaryColorHex != null &&
            brandingPrimaryColorHex is! String)) {
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
      brandingLogoUrl: brandingLogoUrl as String?,
      brandingPrimaryColorHex: brandingPrimaryColorHex as String?,
    );
  }

  final String outcome;
  final String? organizationName;
  final String? scope;
  final List<CatalogShareItemDto> items;
  final String? collectionName;
  final DateTime? expiresAt;

  /// The organization's configured catalog branding (TASK-179), `null` when
  /// not configured or when [outcome] is not `valid`.
  final String? brandingLogoUrl;
  final String? brandingPrimaryColorHex;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_campaign.freezed.dart';

/// A promotional/visual campaign banner shown in the catalog home's
/// "campanhas em destaque" section (TASK-076) and, in full, by the future
/// lookbook/campaigns screen (TASK-080 — this task only reads campaigns,
/// admin CRUD belongs there, the same "TASK-064 modeled the entity, TASK-065
/// added create/update" incremental precedent `Product`/`ProductRepository`
/// already set).
///
/// [collectionId] optionally links the campaign to a `Collection`, so
/// tapping the banner can open that collection's products; `null` when the
/// campaign is not tied to one specific collection.
///
/// Belongs to exactly one [organizationId] — never shared between tenants.
@freezed
abstract class CatalogCampaign with _$CatalogCampaign {
  const CatalogCampaign._();

  const factory CatalogCampaign({
    required String id,
    required String organizationId,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? collectionId,
    required int order,
    required bool active,
    DateTime? startAt,
    DateTime? endAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _CatalogCampaign;

  /// Whether this campaign should be shown at [now]: not soft-deleted, not
  /// deactivated, and — when set — within its [startAt]/[endAt] window.
  /// Applied by `GetCatalogCampaignsSectionUseCase`, never left for the UI
  /// to decide (TASK-076: "nenhuma seção pode simular urgência falsa").
  bool isVisibleAt(DateTime now) {
    if (deletedAt != null || !active) return false;
    final start = startAt;
    if (start != null && now.isBefore(start)) return false;
    final end = endAt;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }
}

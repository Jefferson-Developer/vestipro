import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/catalog_campaign_status.dart';

part 'catalog_campaign.freezed.dart';

/// A lookbook/promotional visual campaign (TASK-080, EPIC-10): editorial
/// narrative for a coleção/campanha — cover + editorial images, descriptive
/// text and a curated list of related products — shown both as a teaser in
/// the catalog home's "campanhas em destaque" section (TASK-076) and, in
/// full, by `LookbookPage`.
///
/// 100% data-driven: every field an admin can publish through
/// `CampaignFormPage` (TASK-080) — no campaign is ever hardcoded in the app.
///
/// [collectionId] optionally links the campaign to a `Collection`, so
/// tapping the banner can open that collection's products; `null` when the
/// campaign is not tied to one specific collection.
///
/// [relatedProductIds] is the curated, admin-picked product list the
/// lookbook's carousel renders (`ListCampaignRelatedProductsUseCase`
/// resolves the ids into `Product`s, silently dropping any that no longer
/// exist — same "stale reference never blocks the rest of the list"
/// contract `ProductRepository.getByIds` already documents).
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
    String? description,
    String? imageUrl,
    @Default(<String>[]) List<String> editorialImageUrls,
    @Default(<String>[]) List<String> relatedProductIds,
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

  /// The campaign's lifecycle status at [now] — see `CatalogCampaignStatus`.
  /// The single source of truth every reader (home section, admin list,
  /// lookbook screen) derives visibility/labels from, so none of them can
  /// drift out of sync with each other.
  CatalogCampaignStatus statusAt(DateTime now) {
    if (deletedAt != null || !active) return CatalogCampaignStatus.inactive;
    final start = startAt;
    if (start != null && now.isBefore(start)) {
      return CatalogCampaignStatus.scheduled;
    }
    final end = endAt;
    if (end != null && now.isAfter(end)) return CatalogCampaignStatus.expired;
    return CatalogCampaignStatus.active;
  }

  /// Whether this campaign should be shown at [now]: not soft-deleted, not
  /// deactivated, and — when set — within its [startAt]/[endAt] window.
  /// Applied by every reader (`GetCatalogCampaignsSectionUseCase`,
  /// `LookbookBloc`), never left for the UI to decide (TASK-076: "nenhuma
  /// seção pode simular urgência falsa").
  bool isVisibleAt(DateTime now) =>
      statusAt(now) == CatalogCampaignStatus.active;
}

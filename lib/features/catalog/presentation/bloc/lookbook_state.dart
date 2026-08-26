import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';

enum LookbookStatus {
  loading,

  /// The campaign was loaded and is currently within its visibility
  /// window (`CatalogCampaign.isVisibleAt`).
  ready,

  /// The campaign either does not exist, was soft-deleted, or exists but
  /// is not visible right now (inactive/scheduled/expired) — rendered
  /// exactly the same as "not found", never leaking *why* an
  /// inactive/expired campaign is unavailable (TASK-080: "produtos
  /// relacionados de uma campanha expirada não devem continuar aparecendo
  /// como 'em campanha' em nenhuma tela").
  unavailable,

  failure,
}

final class LookbookState {
  const LookbookState({
    this.status = LookbookStatus.loading,
    this.organizationId = '',
    this.campaignId = '',
    this.campaign,
    this.relatedProducts = const <Product>[],
    this.failure,
    this.hasLoggedView = false,
  });

  final LookbookStatus status;
  final String organizationId;
  final String campaignId;
  final CatalogCampaign? campaign;
  final List<Product> relatedProducts;
  final Failure? failure;
  final bool hasLoggedView;

  LookbookState copyWith({
    LookbookStatus? status,
    String? organizationId,
    String? campaignId,
    CatalogCampaign? campaign,
    List<Product>? relatedProducts,
    Failure? failure,
    bool? hasLoggedView,
    bool clearFailure = false,
  }) {
    return LookbookState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      campaignId: campaignId ?? this.campaignId,
      campaign: campaign ?? this.campaign,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      failure: clearFailure ? null : failure ?? this.failure,
      hasLoggedView: hasLoggedView ?? this.hasLoggedView,
    );
  }
}

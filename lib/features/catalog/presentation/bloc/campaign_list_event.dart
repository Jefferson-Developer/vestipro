import '../../domain/entities/catalog_campaign.dart';

sealed class CampaignListEvent {
  const CampaignListEvent();
}

final class CampaignListStarted extends CampaignListEvent {
  const CampaignListStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class CampaignListRefreshRequested extends CampaignListEvent {
  const CampaignListRefreshRequested();
}

final class CampaignListSearchChanged extends CampaignListEvent {
  const CampaignListSearchChanged(this.query);

  final String query;
}

final class CampaignListDeleteRequested extends CampaignListEvent {
  const CampaignListDeleteRequested(this.campaign);

  final CatalogCampaign campaign;
}

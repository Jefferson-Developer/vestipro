import 'applied_promotional_campaign.dart';
import 'promotional_campaign.dart';

final class PromotionalCampaignResolution {
  const PromotionalCampaignResolution({
    required this.eligibleCampaigns,
    required this.appliedCampaigns,
    this.winningCampaign,
    this.winningReason,
  });

  final List<PromotionalCampaign> eligibleCampaigns;
  final List<AppliedPromotionalCampaign> appliedCampaigns;
  final PromotionalCampaign? winningCampaign;
  final String? winningReason;

  bool get hasAnyCampaign => appliedCampaigns.isNotEmpty;
}

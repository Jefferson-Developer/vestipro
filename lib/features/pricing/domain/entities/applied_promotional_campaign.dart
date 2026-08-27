import '../value_objects/promotional_discount_type.dart';

final class AppliedPromotionalCampaign {
  const AppliedPromotionalCampaign({
    required this.campaignId,
    required this.campaignName,
    required this.discountType,
    required this.discountValue,
    required this.reason,
  });

  final String campaignId;
  final String campaignName;
  final PromotionalDiscountType discountType;
  final double discountValue;
  final String reason;
}

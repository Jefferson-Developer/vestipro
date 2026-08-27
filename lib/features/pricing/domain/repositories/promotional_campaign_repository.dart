import '../../../../core/utils/utils.dart';
import '../entities/promotional_campaign.dart';

abstract interface class PromotionalCampaignRepository {
  Future<AppResult<PromotionalCampaign>> create({
    required PromotionalCampaign campaign,
  });

  Future<AppResult<PromotionalCampaign>> update({
    required PromotionalCampaign campaign,
  });

  Future<AppResult<PromotionalCampaign?>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<PromotionalCampaign>>> listByCompany({
    required String organizationId,
    required String companyId,
  });
}

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/applied_promotional_campaign.dart';
import '../entities/promotional_campaign.dart';
import '../entities/promotional_campaign_resolution.dart';
import '../repositories/promotional_campaign_repository.dart';

@injectable
final class ResolveApplicableCampaignsUseCase {
  const ResolveApplicableCampaignsUseCase(this._repository);

  final PromotionalCampaignRepository _repository;

  Future<AppResult<PromotionalCampaignResolution>> call({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String productId,
    String? collectionId,
    String? categoryId,
    DateTime? now,
  }) async {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (customerSegment.trim().isEmpty) {
      fieldErrors['customerSegment'] = 'Customer segment is required.';
    }
    if (productId.trim().isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<PromotionalCampaignResolution>(
        ValidationFailure(
          'Invalid promotional campaign resolution payload.',
          code: 'invalid_promotional_campaign_resolution_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final itemsResult = await _repository.listByCompany(
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
    );
    if (itemsResult is AppFailure<List<PromotionalCampaign>>) {
      return AppFailure<PromotionalCampaignResolution>(itemsResult.failure);
    }

    final effectiveNow = (now ?? DateTime.now()).toUtc();
    final eligible =
        (itemsResult as AppSuccess<List<PromotionalCampaign>>).value
            .where(
              (campaign) =>
                  campaign.isActive &&
                  campaign.isValidAt(effectiveNow) &&
                  campaign.matchesCustomerSegment(customerSegment) &&
                  campaign.matchesProduct(
                    productId: productId,
                    collectionId: collectionId,
                    categoryId: categoryId,
                  ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final byPriority = b.priority.compareTo(a.priority);
            if (byPriority != 0) return byPriority;
            return a.id.compareTo(b.id);
          });

    if (eligible.isEmpty) {
      return const AppSuccess<PromotionalCampaignResolution>(
        PromotionalCampaignResolution(
          eligibleCampaigns: <PromotionalCampaign>[],
          appliedCampaigns: <AppliedPromotionalCampaign>[],
        ),
      );
    }

    final nonStackable = eligible.where(
      (item) => !item.stackableWithOtherCampaigns,
    );
    if (nonStackable.isNotEmpty) {
      final winner = nonStackable.first;
      return AppSuccess<PromotionalCampaignResolution>(
        PromotionalCampaignResolution(
          eligibleCampaigns: eligible,
          appliedCampaigns: <AppliedPromotionalCampaign>[
            AppliedPromotionalCampaign(
              campaignId: winner.id,
              campaignName: winner.name,
              discountType: winner.discountType,
              discountValue: winner.discountValue,
              reason:
                  'Campanha vencedora por maior prioridade entre campanhas não empilháveis.',
            ),
          ],
          winningCampaign: winner,
          winningReason:
              'Maior prioridade (${winner.priority}) entre campanhas não empilháveis.',
        ),
      );
    }

    return AppSuccess<PromotionalCampaignResolution>(
      PromotionalCampaignResolution(
        eligibleCampaigns: eligible,
        appliedCampaigns: eligible
            .map(
              (campaign) => AppliedPromotionalCampaign(
                campaignId: campaign.id,
                campaignName: campaign.name,
                discountType: campaign.discountType,
                discountValue: campaign.discountValue,
                reason:
                    'Campanha elegível empilhável mantida na composição do preço.',
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/applied_promotional_campaign.dart';

class PricingAdjustmentOriginCard extends StatelessWidget {
  const PricingAdjustmentOriginCard({
    required this.campaigns,
    required this.manualDiscountDescription,
    super.key,
  });

  final List<AppliedPromotionalCampaign> campaigns;
  final String? manualDiscountDescription;

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty && manualDiscountDescription == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Origem dos descontos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            for (final campaign in campaigns)
              Text('Campanha ${campaign.campaignName}: ${campaign.campaignId}'),
            if (manualDiscountDescription != null)
              Text('Desconto manual: $manualDiscountDescription'),
          ],
        ),
      ),
    );
  }
}

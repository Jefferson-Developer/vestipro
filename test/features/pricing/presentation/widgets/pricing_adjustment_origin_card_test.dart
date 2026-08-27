import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/pricing/pricing.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

void main() {
  testWidgets('renders campaign and manual discount origins', (tester) async {
    await pumpApp(
      tester,
      const Material(
        child: PricingAdjustmentOriginCard(
          campaigns: <AppliedPromotionalCampaign>[
            AppliedPromotionalCampaign(
              campaignId: 'campaign-1',
              campaignName: 'Liquidação',
              discountType: PromotionalDiscountType.percentage,
              discountValue: 10,
              reason: 'Maior prioridade.',
            ),
          ],
          manualDiscountDescription: '5% aprovado pelo perfil',
        ),
      ),
    );

    expect(find.text('Origem dos descontos'), findsOneWidget);
    expect(find.textContaining('campaign-1'), findsOneWidget);
    expect(find.textContaining('5% aprovado'), findsOneWidget);
  });
}

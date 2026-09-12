import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/showroom_samples/showroom_samples.dart';

void main() {
  SampleItem item(String id, String repId) {
    return SampleItem(
      id: id,
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: 'product-1',
      variantId: id,
      sampleWarehouseId: 'sample-wh',
      status: SampleItemStatus.checkedOut,
      holderType: SampleHolderType.salesRep,
      holderId: repId,
      responsibleUserId: repId,
      physicalCondition: 'Novo',
      replacementValueCents: 10000,
    );
  }

  testWidgets('sales rep sees only samples under own responsibility', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SampleInventoryPanel(
            title: 'Mostruario',
            items: [item('variant-1', 'rep-1'), item('variant-2', 'rep-2')],
            currentUserId: 'rep-1',
            canManageAllSamples: false,
          ),
        ),
      ),
    );

    expect(find.text('Variante variant-1'), findsOneWidget);
    expect(find.text('Variante variant-2'), findsNothing);
  });
}

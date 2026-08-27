import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/pricing/pricing.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 8, 27);
  final policy = DiscountPolicy(
    id: 'policy-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    role: 'SALES_REP',
    maxDiscountPercent: 15,
    requiresApprovalAbovePercent: 10,
    status: DiscountPolicyStatus.active,
    createdAt: now,
    createdBy: 'admin-1',
    updatedAt: now,
    updatedBy: 'admin-1',
  );

  testWidgets('shows approval guidance and payload when approval is required', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Material(
        child: DiscountValidationBanner(
          result: DiscountRequiresApproval(
            requestedDiscountPercent: 12,
            policy: policy,
            approvalRequest: DiscountApprovalRequest(
              organizationId: 'org-1',
              companyId: 'company-1',
              requestedByUserId: 'rep-1',
              requestedByRole: 'SALES_REP',
              discountPolicyId: 'policy-1',
              requestedDiscountPercent: 12,
              approvalThresholdPercent: 10,
              maxDiscountPercent: 15,
              priceListId: 'vip',
              createdAt: now,
              orderDraftId: 'draft-1',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Desconto exige aprovação'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('discount_approval_payload')),
      findsOneWidget,
    );
  });

  testWidgets('shows blocked state when discount is not allowed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Material(
        child: DiscountValidationBanner(
          result: DiscountBlocked(
            requestedDiscountPercent: 18,
            policy: policy,
            reason: 'Limite excedido.',
          ),
        ),
      ),
    );

    expect(find.text('Desconto bloqueado'), findsOneWidget);
    expect(find.text('Limite excedido.'), findsOneWidget);
  });
}

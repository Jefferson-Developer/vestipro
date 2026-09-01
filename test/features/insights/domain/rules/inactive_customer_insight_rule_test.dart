import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('InactiveCustomerInsightRule', () {
    const rule = InactiveCustomerInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    test('fires only at or above threshold and honors segment override', () {
      final context = InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: const InsightOrganizationSettings(
            inactivityThresholdDays: 45,
            inactivityThresholdDaysBySegment: <String, int>{'premium': 30},
          ),
          customerSnapshots: <InsightCustomerSnapshot>[
            InsightCustomerSnapshot(
              customerId: 'on-edge',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-1',
              customerName: 'Edge',
              customerStatus: 'active',
              lastOrderAt: asOf.subtract(const Duration(days: 45)),
              averageTicket: 1000,
              responsibleSellerId: 'seller-1',
            ),
            InsightCustomerSnapshot(
              customerId: 'below',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-1',
              customerName: 'Below',
              customerStatus: 'active',
              lastOrderAt: asOf.subtract(const Duration(days: 44)),
              averageTicket: 1000,
              responsibleSellerId: 'seller-1',
            ),
            InsightCustomerSnapshot(
              customerId: 'segment-override',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-2',
              customerName: 'Premium',
              customerStatus: 'active',
              segment: 'premium',
              lastOrderAt: asOf.subtract(const Duration(days: 30)),
              averageTicket: 3000,
              responsibleSellerId: 'seller-2',
            ),
          ],
        ),
      );

      final insights = rule.evaluate(context);

      expect(insights.map((item) => item.customerId), <String?>[
        'on-edge',
        'segment-override',
      ]);
    });

    test(
      'does not fire for customers without order history or inactive ones',
      () {
        final context = InsightContext(
          organizationId: 'org-1',
          companyId: 'company-1',
          asOf: asOf,
          dataset: InsightDataset(
            settings: const InsightOrganizationSettings(),
            customerSnapshots: <InsightCustomerSnapshot>[
              const InsightCustomerSnapshot(
                customerId: 'never-bought',
                organizationId: 'org-1',
                companyId: 'company-1',
                recipientUserId: 'seller-1',
                customerName: 'Never',
                customerStatus: 'active',
              ),
              InsightCustomerSnapshot(
                customerId: 'inactive-admin',
                organizationId: 'org-1',
                companyId: 'company-1',
                recipientUserId: 'seller-1',
                customerName: 'Inactive',
                customerStatus: 'inactive',
                lastOrderAt: asOf.subtract(const Duration(days: 90)),
                averageTicket: 2000,
              ),
            ],
          ),
        );

        expect(rule.evaluate(context), isEmpty);
      },
    );
  });
}

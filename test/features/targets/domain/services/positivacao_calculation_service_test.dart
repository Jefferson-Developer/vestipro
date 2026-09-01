import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('PositivacaoCalculationService.calculate', () {
    const service = PositivacaoCalculationService();
    final periodStart = DateTime.utc(2026, 9);
    final periodEnd = DateTime.utc(2026, 10);
    final calculatedAt = DateTime.utc(2026, 9, 15);

    const defaultSettings = PositivacaoSettings(
      periodGranularity: TargetPeriodGranularity.monthly,
      eligibleOrderStatusCodes: <String>{'approved', 'invoiced'},
    );

    PositivacaoSnapshot calculate({
      required Set<String> portfolio,
      required List<PositivacaoOrderSignal> orders,
      PositivacaoSettings settings = defaultSettings,
    }) {
      return service.calculate(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'seller-1',
        portfolioCustomerIds: portfolio,
        orders: orders,
        settings: settings,
        periodStart: periodStart,
        periodEnd: periodEnd,
        calculatedAt: calculatedAt,
      );
    }

    test('positivates a customer with an eligible-status order inside the '
        'period', () {
      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-1',
            statusCode: 'approved',
            orderTotal: 500,
            orderDate: DateTime.utc(2026, 9, 10),
          ),
        ],
      );

      expect(snapshot.totalPortfolio, 1);
      expect(snapshot.positivatedCount, 1);
      expect(snapshot.nonPositivatedCustomerIds, isEmpty);
      expect(snapshot.percentage, 100);
      expect(snapshot.isCalculated, isTrue);
    });

    test('does not positivate a customer whose only order has a non-eligible '
        'status', () {
      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-1',
            statusCode: 'draft',
            orderTotal: 500,
            orderDate: DateTime.utc(2026, 9, 10),
          ),
        ],
      );

      expect(snapshot.totalPortfolio, 1);
      expect(snapshot.positivatedCount, 0);
      expect(snapshot.nonPositivatedCustomerIds, <String>['customer-1']);
      expect(snapshot.percentage, 0);
    });

    test('does not positivate a customer with no orders at all', () {
      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: const <PositivacaoOrderSignal>[],
      );

      expect(snapshot.totalPortfolio, 1);
      expect(snapshot.positivatedCount, 0);
      expect(snapshot.nonPositivatedCustomerIds, <String>['customer-1']);
    });

    test('does not positivate a customer whose eligible-status order is below '
        'the configured minimum value', () {
      const settingsWithMinimum = PositivacaoSettings(
        periodGranularity: TargetPeriodGranularity.monthly,
        eligibleOrderStatusCodes: <String>{'approved'},
        minOrderValue: 300,
      );

      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-1',
            statusCode: 'approved',
            orderTotal: 200,
            orderDate: DateTime.utc(2026, 9, 10),
          ),
        ],
        settings: settingsWithMinimum,
      );

      expect(snapshot.positivatedCount, 0);
      expect(snapshot.nonPositivatedCustomerIds, <String>['customer-1']);
    });

    test('positivates a customer whose order meets the configured minimum '
        'value exactly', () {
      const settingsWithMinimum = PositivacaoSettings(
        periodGranularity: TargetPeriodGranularity.monthly,
        eligibleOrderStatusCodes: <String>{'approved'},
        minOrderValue: 300,
      );

      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-1',
            statusCode: 'approved',
            orderTotal: 300,
            orderDate: DateTime.utc(2026, 9, 10),
          ),
        ],
        settings: settingsWithMinimum,
      );

      expect(snapshot.positivatedCount, 1);
    });

    test('ignores an order outside the period window', () {
      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-1',
            statusCode: 'approved',
            orderTotal: 500,
            orderDate: DateTime.utc(2026, 8, 31),
          ),
        ],
      );

      expect(snapshot.positivatedCount, 0);
    });

    test('ignores an order from a customer outside the portfolio', () {
      final snapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: <PositivacaoOrderSignal>[
          PositivacaoOrderSignal(
            customerId: 'customer-outsider',
            statusCode: 'approved',
            orderTotal: 500,
            orderDate: DateTime.utc(2026, 9, 10),
          ),
        ],
      );

      expect(snapshot.positivatedCount, 0);
      expect(snapshot.totalPortfolio, 1);
    });

    test('two organizations with different rules produce different results '
        'for the same raw orders (TASK-117)', () {
      final orders = <PositivacaoOrderSignal>[
        PositivacaoOrderSignal(
          customerId: 'customer-1',
          statusCode: 'shipped',
          orderTotal: 80,
          orderDate: DateTime.utc(2026, 9, 10),
        ),
      ];

      const strictSettings = PositivacaoSettings(
        periodGranularity: TargetPeriodGranularity.monthly,
        eligibleOrderStatusCodes: <String>{'approved', 'invoiced'},
        minOrderValue: 100,
      );
      const permissiveSettings = PositivacaoSettings(
        periodGranularity: TargetPeriodGranularity.monthly,
        eligibleOrderStatusCodes: <String>{'shipped'},
      );

      final strictSnapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: orders,
        settings: strictSettings,
      );
      final permissiveSnapshot = calculate(
        portfolio: <String>{'customer-1'},
        orders: orders,
        settings: permissiveSettings,
      );

      expect(strictSnapshot.positivatedCount, 0);
      expect(permissiveSnapshot.positivatedCount, 1);
    });

    test('an empty portfolio calculates to 0% without dividing by zero', () {
      final snapshot = calculate(
        portfolio: const <String>{},
        orders: const <PositivacaoOrderSignal>[],
      );

      expect(snapshot.totalPortfolio, 0);
      expect(snapshot.percentage, 0);
    });
  });
}

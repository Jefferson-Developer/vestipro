import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('PositivacaoSettings.fromOrganizationSettings', () {
    test('parses a fully configured organization rule', () {
      final organizationSettings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        positivacaoPeriodGranularity: 'quarterly',
        positivacaoEligibleOrderStatuses: <String>['invoiced', 'delivered'],
        positivacaoMinOrderValue: 250,
      );

      final settings = PositivacaoSettings.fromOrganizationSettings(
        organizationSettings,
      );

      expect(settings.periodGranularity, TargetPeriodGranularity.quarterly);
      expect(settings.eligibleOrderStatusCodes, <String>{
        'invoiced',
        'delivered',
      });
      expect(settings.minOrderValue, 250);
      expect(settings.isEligibleStatus('invoiced'), isTrue);
      expect(settings.isEligibleStatus('draft'), isFalse);
      expect(settings.meetsMinimumValue(300), isTrue);
      expect(settings.meetsMinimumValue(100), isFalse);
    });

    test('falls back to monthly for an unrecognized granularity code '
        'instead of throwing', () {
      const organizationSettings = OrganizationSettings(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        positivacaoPeriodGranularity: 'weekly',
      );

      final settings = PositivacaoSettings.fromOrganizationSettings(
        organizationSettings,
      );

      expect(settings.periodGranularity, TargetPeriodGranularity.monthly);
    });

    test('meetsMinimumValue is always true when no minimum is configured', () {
      const settings = PositivacaoSettings(
        periodGranularity: TargetPeriodGranularity.monthly,
        eligibleOrderStatusCodes: <String>{'approved'},
      );

      expect(settings.meetsMinimumValue(0), isTrue);
      expect(settings.meetsMinimumValue(999999), isTrue);
    });
  });

  group('PositivacaoPeriod.current', () {
    test('resolves the monthly window containing now', () {
      final period = PositivacaoPeriod.current(
        granularity: TargetPeriodGranularity.monthly,
        now: DateTime.utc(2026, 9, 15),
      );

      expect(period.start, DateTime.utc(2026, 9));
      expect(period.end, DateTime.utc(2026, 10));
    });

    test('resolves the quarterly window containing now', () {
      final period = PositivacaoPeriod.current(
        granularity: TargetPeriodGranularity.quarterly,
        now: DateTime.utc(2026, 8, 1),
      );

      expect(period.start, DateTime.utc(2026, 7));
      expect(period.end, DateTime.utc(2026, 10));
    });

    test('resolves the yearly window containing now', () {
      final period = PositivacaoPeriod.current(
        granularity: TargetPeriodGranularity.yearly,
        now: DateTime.utc(2026, 3, 1),
      );

      expect(period.start, DateTime.utc(2026));
      expect(period.end, DateTime.utc(2027));
    });
  });

  group('PositivacaoDimensionType.asTargetDimensionType', () {
    test('maps every value to its TargetDimensionType equivalent', () {
      expect(
        PositivacaoDimensionType.salesRep.asTargetDimensionType,
        TargetDimensionType.salesRep,
      );
      expect(
        PositivacaoDimensionType.team.asTargetDimensionType,
        TargetDimensionType.team,
      );
      expect(
        PositivacaoDimensionType.company.asTargetDimensionType,
        TargetDimensionType.company,
      );
    });
  });

  group('PositivacaoSnapshot', () {
    test('notCalculated leaves totals/calculatedAt null', () {
      final snapshot = PositivacaoSnapshot.notCalculated(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'rep-1',
        periodStart: DateTime.utc(2026, 9),
        periodEnd: DateTime.utc(2026, 10),
      );

      expect(snapshot.isCalculated, isFalse);
      expect(snapshot.percentage, 0);
    });

    test('percentage never divides by zero for an empty carteira', () {
      final snapshot = PositivacaoSnapshot(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'rep-1',
        periodStart: DateTime.utc(2026, 9),
        periodEnd: DateTime.utc(2026, 10),
        totalPortfolio: 0,
        positivatedCount: 0,
        calculatedAt: DateTime.utc(2026, 9, 15),
      );

      expect(snapshot.isCalculated, isTrue);
      expect(snapshot.percentage, 0);
    });
  });
}

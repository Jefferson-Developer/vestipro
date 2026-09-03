import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  group('ExecutiveDashboardFilters', () {
    test('monthKey pads single-digit months', () {
      const filters = ExecutiveDashboardFilters(
        companyId: 'company-1',
        year: 2026,
        month: 3,
      );

      expect(filters.monthKey, '2026-03');
      expect(filters.periodStart, DateTime.utc(2026, 3));
      expect(filters.periodEnd, DateTime.utc(2026, 4));
    });

    test('previousMonth rolls over the year boundary', () {
      const january = ExecutiveDashboardFilters(
        companyId: 'company-1',
        year: 2026,
        month: 1,
      );

      final previous = january.previousMonth;

      expect(previous.year, 2025);
      expect(previous.month, 12);
    });

    test('previousYear keeps the same month, one year before', () {
      const filters = ExecutiveDashboardFilters(
        companyId: 'company-1',
        teamId: 'team-1',
        year: 2026,
        month: 6,
      );

      final previousYear = filters.previousYear;

      expect(previousYear.year, 2025);
      expect(previousYear.month, 6);
      expect(previousYear.companyId, 'company-1');
      expect(previousYear.teamId, 'team-1');
    });

    test('isAfter is true only for a strictly later calendar month', () {
      const august = ExecutiveDashboardFilters(
        companyId: 'company-1',
        year: 2026,
        month: 8,
      );

      expect(august.isAfter(DateTime.utc(2026, 7, 15)), isTrue);
      expect(august.isAfter(DateTime.utc(2026, 8, 15)), isFalse);
      expect(august.isAfter(DateTime.utc(2026, 9, 1)), isFalse);
      expect(august.isAfter(DateTime.utc(2025, 12, 1)), isTrue);
    });

    test('toQueryParameters/fromQueryParameters round-trip', () {
      const filters = ExecutiveDashboardFilters(
        companyId: 'company-1',
        teamId: 'team-1',
        year: 2026,
        month: 9,
      );

      final restored = ExecutiveDashboardFilters.fromQueryParameters(
        filters.toQueryParameters(),
        defaultCompanyId: 'fallback-company',
      );

      expect(restored, filters);
    });

    test('fromQueryParameters falls back to the current month when month is '
        'missing/malformed', () {
      final restored = ExecutiveDashboardFilters.fromQueryParameters(
        <String, String>{'month': 'not-a-month'},
        defaultCompanyId: 'fallback-company',
        now: DateTime.utc(2026, 5, 10),
      );

      expect(restored.companyId, 'fallback-company');
      expect(restored.year, 2026);
      expect(restored.month, 5);
      expect(restored.teamId, isNull);
    });

    test('fromQueryParameters uses defaultCompanyId when companyId is '
        'blank', () {
      final restored = ExecutiveDashboardFilters.fromQueryParameters(
        <String, String>{'companyId': '', 'month': '2026-02'},
        defaultCompanyId: 'fallback-company',
      );

      expect(restored.companyId, 'fallback-company');
      expect(restored.year, 2026);
      expect(restored.month, 2);
    });

    test('copyWith clearTeamId removes the team filter', () {
      const withTeam = ExecutiveDashboardFilters(
        companyId: 'company-1',
        teamId: 'team-1',
        year: 2026,
        month: 1,
      );

      final withoutTeam = withTeam.copyWith(clearTeamId: true);

      expect(withoutTeam.teamId, isNull);
      expect(withoutTeam.companyId, 'company-1');
    });

    test('currentMonth builds from the injected now', () {
      final filters = ExecutiveDashboardFilters.currentMonth(
        companyId: 'company-1',
        now: DateTime.utc(2026, 11, 20),
      );

      expect(filters.year, 2026);
      expect(filters.month, 11);
    });
  });
}

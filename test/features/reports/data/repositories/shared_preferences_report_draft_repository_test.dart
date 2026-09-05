import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/reports/data/repositories/shared_preferences_report_draft_repository.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('round-trips a draft per user and tenant scope', () async {
    const repository = SharedPreferencesReportDraftRepository();
    const definition = ReportDefinition(
      organizationId: 'org-a',
      companyId: 'company-a',
      dimensions: <String>['seller'],
      metrics: <String>['orders'],
      filters: <ReportFilter>[
        ReportFilter(fieldId: 'period', operatorId: 'equals', value: '2026-09'),
      ],
      groupBy: <String>['seller'],
      sortBy: ReportSort(
        fieldId: 'orders',
        direction: ReportSortDirection.descending,
      ),
      comparisonPeriod: ReportComparisonPeriod.previousYear,
    );
    await repository.save(userId: 'user-a', definition: definition);

    final restored = await repository.load(
      userId: 'user-a',
      organizationId: 'org-a',
      companyId: 'company-a',
    );
    expect(restored?.dimensions, <String>['seller']);
    expect(restored?.sortBy?.fieldId, 'orders');
    expect(restored?.comparisonPeriod, ReportComparisonPeriod.previousYear);
  });

  test('never returns another user or tenant draft', () async {
    const repository = SharedPreferencesReportDraftRepository();
    await repository.save(
      userId: 'user-a',
      definition: const ReportDefinition(
        organizationId: 'org-a',
        companyId: 'company-a',
      ),
    );
    expect(
      await repository.load(
        userId: 'user-b',
        organizationId: 'org-a',
        companyId: 'company-a',
      ),
      isNull,
    );
    expect(
      await repository.load(
        userId: 'user-a',
        organizationId: 'org-b',
        companyId: 'company-a',
      ),
      isNull,
    );
  });
}

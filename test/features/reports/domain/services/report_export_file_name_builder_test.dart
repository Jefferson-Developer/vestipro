import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('ReportExportFileNameBuilder (TASK-146)', () {
    const definition = ReportDefinition(
      organizationId: 'org-a',
      companyId: 'company-a',
      dimensions: <String>['customer'],
      metrics: <String>['revenueNet'],
    );

    test('is deterministic for the same definition and generation instant', () {
      final generatedAt = DateTime.utc(2026, 9, 4, 12, 30);
      final first = ReportExportFileNameBuilder.build(
        definition: definition,
        generatedAt: generatedAt,
        extension: 'csv',
      );
      final second = ReportExportFileNameBuilder.build(
        definition: definition,
        generatedAt: generatedAt,
        extension: 'csv',
      );
      expect(first, second);
      expect(first, 'customer-revenuenet_org-a_20260904-123000.csv');
    });

    test('identifies the report and the generation date/time in the name', () {
      final fileName = ReportExportFileNameBuilder.build(
        definition: definition,
        generatedAt: DateTime.utc(2026, 9, 4, 8, 5, 9),
        extension: 'csv',
      );
      expect(fileName, contains('customer-revenuenet'));
      expect(fileName, contains('org-a'));
      expect(fileName, contains('20260904-080509'));
    });

    test(
      'two exports generated at different instants get different, still traceable, names',
      () {
        final first = ReportExportFileNameBuilder.build(
          definition: definition,
          generatedAt: DateTime.utc(2026, 9, 4, 12, 0, 0),
          extension: 'csv',
        );
        final second = ReportExportFileNameBuilder.build(
          definition: definition,
          generatedAt: DateTime.utc(2026, 9, 4, 12, 0, 1),
          extension: 'csv',
        );
        expect(first, isNot(second));
      },
    );

    test('slugifies accented dimensions/metrics and the organization id', () {
      const accented = ReportDefinition(
        organizationId: 'Órg Ação',
        companyId: 'company-a',
        dimensions: <String>['região'],
        metrics: <String>['faturamento'],
      );
      final fileName = ReportExportFileNameBuilder.build(
        definition: accented,
        generatedAt: DateTime.utc(2026, 9, 4),
        extension: 'csv',
      );
      expect(fileName, 'regiao-faturamento_org-acao_20260904-000000.csv');
    });
  });
}

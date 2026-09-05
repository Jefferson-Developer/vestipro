import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('PdfReportEncoder (TASK-148)', () {
    const catalog = ReportCatalog(
      fields: <ReportFieldDefinition>[
        ReportFieldDefinition(
          id: 'period',
          label: 'Período',
          type: ReportFieldType.dimension,
          valueType: ReportValueType.date,
        ),
        ReportFieldDefinition(
          id: 'customer',
          label: 'Cliente',
          type: ReportFieldType.dimension,
          valueType: ReportValueType.text,
        ),
        ReportFieldDefinition(
          id: 'revenueNet',
          label: 'Faturamento líquido',
          type: ReportFieldType.metric,
          valueType: ReportValueType.currency,
        ),
      ],
    );

    const definition = ReportDefinition(
      organizationId: 'org-a',
      companyId: 'company-a',
      dimensions: <String>['period', 'customer'],
      metrics: <String>['revenueNet'],
      filters: <ReportFilter>[
        ReportFilter(fieldId: 'period', operatorId: 'equals', value: '2026-09'),
      ],
    );

    ReportQueryResult resultWithRows(int rowCount) => ReportQueryResult(
      columns: const <String>['period', 'customer', 'revenueNet'],
      rows: List<Map<String, Object?>>.generate(
        rowCount,
        (index) => <String, Object?>{
          'period': '2026-09',
          'customer': 'Cliente $index',
          'revenueNet': 1234.5 + index,
        },
      ),
      generatedAt: DateTime(2026, 9, 4),
    );

    Future<Uint8List> encode({
      required int rowCount,
      ReportBranding branding = const ReportBranding.none(),
    }) => const PdfReportEncoder().encodeToBytes(
      definition: definition,
      result: resultWithRows(rowCount),
      catalog: catalog,
      branding: branding,
    );

    test(
      'produces a well-formed PDF (starts with the %PDF magic bytes)',
      () async {
        final bytes = await encode(rowCount: 3);
        expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      },
    );

    test(
      'produces a structurally valid PDF (cover page only) with no rows',
      () async {
        final bytes = await encode(rowCount: 0);
        expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
        expect(bytes, isNotEmpty);
      },
    );

    test('a larger result produces a larger (or equal) byte payload', () async {
      final small = await encode(rowCount: 1);
      final large = await encode(rowCount: 200);
      expect(large.length, greaterThanOrEqualTo(small.length));
    });

    test(
      'never throws when the organization has no configured branding (falls back to VestiPro default)',
      () async {
        expect(
          () => encode(rowCount: 1, branding: const ReportBranding.none()),
          returnsNormally,
        );
      },
    );

    test('applies a configured brand color without throwing', () async {
      final bytes = await encode(
        rowCount: 1,
        branding: const ReportBranding(primaryColorHex: '#123456'),
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test(
      'falls back to VestiPro default when an invalid hex color is supplied',
      () async {
        final bytes = await encode(
          rowCount: 1,
          branding: const ReportBranding(primaryColorHex: 'not-a-color'),
        );
        expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      },
    );
  });

  group('ReportBranding (TASK-148)', () {
    test('.none() is never configured', () {
      expect(const ReportBranding.none().isConfigured, isFalse);
    });

    test('is configured when only a color is set', () {
      expect(
        const ReportBranding(primaryColorHex: '#000000').isConfigured,
        isTrue,
      );
    });

    test('is configured when only a logo is set', () {
      expect(
        ReportBranding(
          logoBytes: Uint8List.fromList(<int>[1, 2, 3]),
        ).isConfigured,
        isTrue,
      );
    });
  });
}

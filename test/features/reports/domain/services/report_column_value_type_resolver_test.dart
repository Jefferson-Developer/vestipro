import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('ReportColumnValueTypeResolver (TASK-147)', () {
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
        ReportFieldDefinition(
          id: 'averageDiscount',
          label: 'Desconto médio',
          type: ReportFieldType.metric,
          valueType: ReportValueType.percentage,
        ),
        ReportFieldDefinition(
          id: 'orderCount',
          label: 'Pedidos',
          type: ReportFieldType.metric,
          valueType: ReportValueType.number,
        ),
      ],
    );

    test('resolves a direct catalog field id to its own valueType', () {
      expect(
        ReportColumnValueTypeResolver.resolve('period', catalog),
        ReportValueType.date,
      );
      expect(
        ReportColumnValueTypeResolver.resolve('customer', catalog),
        ReportValueType.text,
      );
      expect(
        ReportColumnValueTypeResolver.resolve('revenueNet', catalog),
        ReportValueType.currency,
      );
      expect(
        ReportColumnValueTypeResolver.resolve('orderCount', catalog),
        ReportValueType.number,
      );
    });

    test(
      'a "<metric>ChangePercent" comparison column is always a percentage',
      () {
        expect(
          ReportColumnValueTypeResolver.resolve(
            'revenueNetChangePercent',
            catalog,
          ),
          ReportValueType.percentage,
        );
        expect(
          ReportColumnValueTypeResolver.resolve(
            'orderCountChangePercent',
            catalog,
          ),
          ReportValueType.percentage,
        );
      },
    );

    test(
      'a "<metric>Comparison" column mirrors its base metric\'s own valueType',
      () {
        expect(
          ReportColumnValueTypeResolver.resolve(
            'revenueNetComparison',
            catalog,
          ),
          ReportValueType.currency,
        );
        expect(
          ReportColumnValueTypeResolver.resolve(
            'orderCountComparison',
            catalog,
          ),
          ReportValueType.number,
        );
      },
    );

    test('falls back to number/text for an id the catalog never lists', () {
      expect(
        ReportColumnValueTypeResolver.resolve(
          'somethingUnknownComparison',
          catalog,
        ),
        ReportValueType.number,
      );
      expect(
        ReportColumnValueTypeResolver.resolve('somethingUnknown', catalog),
        ReportValueType.text,
      );
    });
  });
}

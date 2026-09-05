import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  const validator = ValidateReportDefinition();
  const catalog = ReportCatalog(
    fields: <ReportFieldDefinition>[
      ReportFieldDefinition(
        id: 'seller',
        label: 'Vendedor',
        type: ReportFieldType.dimension,
        valueType: ReportValueType.text,
      ),
      ReportFieldDefinition(
        id: 'product',
        label: 'Produto',
        type: ReportFieldType.dimension,
        valueType: ReportValueType.text,
      ),
      ReportFieldDefinition(
        id: 'orders',
        label: 'Pedidos',
        type: ReportFieldType.metric,
        valueType: ReportValueType.number,
        compatibleDimensions: <String>['seller'],
      ),
      ReportFieldDefinition(
        id: 'margin',
        label: 'Margem',
        type: ReportFieldType.metric,
        valueType: ReportValueType.currency,
        isAvailable: false,
      ),
    ],
  );

  test('accepts a compatible tenant-scoped definition', () {
    final result = validator(
      const ReportDefinition(
        organizationId: 'org-a',
        companyId: 'company-a',
        dimensions: <String>['seller'],
        metrics: <String>['orders'],
        filters: <ReportFilter>[
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ],
      ),
      catalog,
    );
    expect(result, isA<AppSuccess<void>>());
  });

  test('blocks incompatible combinations before a repository call', () {
    final result = validator(
      const ReportDefinition(
        organizationId: 'org-a',
        companyId: 'company-a',
        dimensions: <String>['product'],
        metrics: <String>['orders'],
        filters: <ReportFilter>[
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ],
      ),
      catalog,
    );
    expect(result, isA<AppFailure<void>>());
    expect(
      (result as AppFailure<void>).failure.message,
      contains('não pode ser combinada'),
    );
  });

  test('fails closed for a field hidden by RBAC catalog', () {
    final result = validator(
      const ReportDefinition(
        organizationId: 'org-a',
        companyId: 'company-a',
        dimensions: <String>['seller'],
        metrics: <String>['margin'],
        filters: <ReportFilter>[
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ],
      ),
      catalog,
    );
    expect(result, isA<AppFailure<void>>());
    expect(
      (result as AppFailure<void>).failure.message,
      contains('não está disponível'),
    );
  });

  test('blocks dimensions from different server aggregation families', () {
    final result = validator(
      const ReportDefinition(
        organizationId: 'org-a',
        companyId: 'company-a',
        dimensions: <String>['seller', 'product'],
        metrics: <String>['orders'],
        filters: <ReportFilter>[
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ],
      ),
      catalog,
    );
    expect(result, isA<AppFailure<void>>());
    expect(
      (result as AppFailure<void>).failure.message,
      contains('não podem ser combinadas'),
    );
  });
}

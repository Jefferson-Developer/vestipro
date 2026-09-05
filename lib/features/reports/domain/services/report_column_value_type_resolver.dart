import '../entities/report_catalog.dart';

/// Resolves the [ReportValueType] backing a `ReportQueryResult` column id
/// (TASK-147) — needed because the query result itself carries only raw
/// values (`Map<String, Object?>` rows), never a schema; the schema lives in
/// the [ReportCatalog] the report was built against
/// (`ReportFieldDefinition.valueType`).
///
/// Comparison columns synthesized server-side by `runReportAggregation`
/// (`execute-report-query.ts`'s `mergeComparison`) — `<metric>Comparison` and
/// `<metric>ChangePercent` — never appear in the catalog themselves, so they
/// are resolved from the base metric id instead: a `Comparison` column
/// mirrors its base metric's own type (a "faturamento" comparison column is
/// still a currency), while a `ChangePercent` column is always a percentage
/// regardless of what the base metric measures.
final class ReportColumnValueTypeResolver {
  const ReportColumnValueTypeResolver._();

  static const String _changePercentSuffix = 'ChangePercent';
  static const String _comparisonSuffix = 'Comparison';

  static ReportValueType resolve(String columnId, ReportCatalog catalog) {
    if (columnId.endsWith(_changePercentSuffix)) {
      return ReportValueType.percentage;
    }
    if (columnId.endsWith(_comparisonSuffix)) {
      final baseId = columnId.substring(
        0,
        columnId.length - _comparisonSuffix.length,
      );
      return catalog.find(baseId)?.valueType ?? ReportValueType.number;
    }
    return catalog.find(columnId)?.valueType ?? ReportValueType.text;
  }
}

import '../entities/report_definition.dart';

/// Builds the deterministic `<slug-do-relatorio>_<organizacao>_<timestamp>`
/// file name required by TASK-146 — same composition rule mirrored
/// server-side by `buildExportFileName` in
/// `functions/src/reports/export-report-to-csv.ts`, so a client-generated
/// (small result) and a Cloud-Function-generated (large result) export are
/// never ambiguous about which report/organization/moment produced them.
///
/// "Deterministic" here means composed from meaningful, reproducible parts
/// (dimensions + metrics + organization + generation instant) — never a
/// random UUID — not that calling it twice for two different exports
/// produces the same name: two exports generated at different instants
/// legitimately get two different, still fully traceable, file names.
final class ReportExportFileNameBuilder {
  const ReportExportFileNameBuilder._();

  static String build({
    required ReportDefinition definition,
    required DateTime generatedAt,
    required String extension,
  }) {
    final reportSlug = _slugify(
      <String>[...definition.dimensions, ...definition.metrics].join('-'),
    );
    final organizationSlug = _slugify(definition.organizationId);
    return '${reportSlug}_${organizationSlug}_${_timestamp(generatedAt)}.$extension';
  }

  static String _timestamp(DateTime value) {
    final utc = value.toUtc();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${pad(utc.month)}${pad(utc.day)}'
        '-${pad(utc.hour)}${pad(utc.minute)}${pad(utc.second)}';
  }

  static String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'relatorio' : normalized;
  }
}

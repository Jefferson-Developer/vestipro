/// The locale a CSV export (TASK-146) is formatted for. Deliberately tied to
/// a single delimiter/decimal-separator pair instead of letting them vary
/// independently — pt-BR always pairs `;` with a comma decimal separator and
/// en-US always pairs `,` with a dot decimal separator, so the two can never
/// be combined into an ambiguous file (a comma-delimited file whose numbers
/// also use a comma as the decimal separator would be unreadable).
enum ReportExportLocale { ptBr, enUs }

/// Wire code sent to `exportReportToCsv` (`functions/src/reports/export-report-to-csv.ts`'s
/// `parseLocale`) — kept as its own extension instead of `.name` so the two
/// sides staying in sync is an explicit, grep-able contract rather than an
/// accident of Dart's enum naming.
extension ReportExportLocaleCode on ReportExportLocale {
  String get code => switch (this) {
    ReportExportLocale.ptBr => 'ptBr',
    ReportExportLocale.enUs => 'enUs',
  };
}

/// Where a generated CSV export (TASK-146) ended up — never both at once:
/// [LocalReportExportLocation] for a file saved directly to the user's own
/// device (small/medium result, encoded client-side in an isolate) or
/// [RemoteReportExportLocation] for a large result the Cloud Function
/// generated and uploaded to a user-restricted, time-limited Storage
/// location instead.
sealed class ReportExportLocation {
  const ReportExportLocation();
}

/// The export was small enough to be generated on-device
/// (`ExportReportToCsv`, TASK-146) and saved through the platform's own
/// "save file" flow. [path] is whatever URI/path that flow reports back —
/// never assumed to be a `dart:io` filesystem path, since the same flow also
/// runs on web.
final class LocalReportExportLocation extends ReportExportLocation {
  const LocalReportExportLocation(this.path);

  final String path;
}

/// The export exceeded the client-side row threshold
/// (`FeatureFlagRegistry.configReportExportMaxLocalRows`) and was instead
/// generated entirely server-side by the `exportReportToCsv` Cloud Function,
/// which re-executes the report's aggregation under the caller's own
/// role/tenant scope (never trusting a client-submitted result) before
/// uploading the CSV to Storage. [downloadUrl] is a signed URL restricted to
/// the requesting user and expires at [expiresAt] — the same restriction
/// `storage.rules` enforces independently for any direct SDK read attempt.
final class RemoteReportExportLocation extends ReportExportLocation {
  const RemoteReportExportLocation({
    required this.downloadUrl,
    required this.expiresAt,
  });

  final String downloadUrl;
  final DateTime expiresAt;
}

/// Outcome of `ExportReportToCsv` (TASK-146): the deterministic [fileName]
/// (`ReportExportFileNameBuilder`), how many data rows it contains and where
/// it ended up ([location]).
final class ReportExportSummary {
  const ReportExportSummary({
    required this.fileName,
    required this.rowCount,
    required this.location,
  });

  final String fileName;
  final int rowCount;
  final ReportExportLocation location;

  bool get isRemote => location is RemoteReportExportLocation;

  /// Parses the `exportReportToCsv` Cloud Function's response (TASK-146)
  /// into a [ReportExportSummary] whose [location] is always a
  /// [RemoteReportExportLocation] — the callable only ever runs the
  /// large-volume path.
  factory ReportExportSummary.fromRemoteJson(Map<String, dynamic> json) =>
      ReportExportSummary(
        fileName: json['fileName'] as String,
        rowCount: (json['rowCount'] as num).toInt(),
        location: RemoteReportExportLocation(
          downloadUrl: json['downloadUrl'] as String,
          expiresAt: DateTime.parse(json['expiresAt'] as String),
        ),
      );
}

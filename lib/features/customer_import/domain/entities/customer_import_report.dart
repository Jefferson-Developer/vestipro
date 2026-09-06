import 'package:freezed_annotation/freezed_annotation.dart';

import 'customer_import_row_report.dart';

part 'customer_import_report.freezed.dart';

/// The full report of a finished `CustomerImportJob` (TASK-167) — read from
/// the JSON file `processCustomerImportJob` writes to
/// `organizations/{organizationId}/customerImports/{jobId}/report.json`
/// (`CustomerImportJob.reportStoragePath`), never from Firestore directly:
/// a large import can produce more row entries than comfortably fits a
/// single Firestore document (1 MiB limit), so the detailed, per-row report
/// lives in Storage instead — only the aggregate counts
/// (`CustomerImportJob.importedCount`/`rejectedCount`/`duplicateCount`) are
/// ever written to Firestore.
@freezed
abstract class CustomerImportReport with _$CustomerImportReport {
  const factory CustomerImportReport({
    required int totalRows,
    required int importedCount,
    required int rejectedCount,
    required int duplicateCount,
    required List<CustomerImportRowReport> rows,
  }) = _CustomerImportReport;
}

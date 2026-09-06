import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_import_report.dart';
import '../../domain/entities/customer_import_row_report.dart';
import '../../domain/value_objects/customer_import_row_outcome.dart';

/// Parses the JSON report `processCustomerImportJob` writes to
/// `CustomerImportJob.reportStoragePath` (TASK-167) — see that entity's docs
/// for why the per-row detail lives in Storage rather than Firestore.
@injectable
final class CustomerImportReportMapper {
  const CustomerImportReportMapper();

  CustomerImportReport fromJson(Map<String, dynamic> json) {
    final totalRows = json['totalRows'];
    final importedCount = json['importedCount'];
    final rejectedCount = json['rejectedCount'];
    final duplicateCount = json['duplicateCount'];
    final rows = json['rows'];

    if (totalRows is! int ||
        importedCount is! int ||
        rejectedCount is! int ||
        duplicateCount is! int ||
        rows is! List) {
      throw const ValidationException(
        'Invalid customer import report payload.',
        code: 'invalid_customer_import_report_payload',
      );
    }

    return CustomerImportReport(
      totalRows: totalRows,
      importedCount: importedCount,
      rejectedCount: rejectedCount,
      duplicateCount: duplicateCount,
      rows: rows
          .map((item) => _rowFromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  CustomerImportRowReport _rowFromJson(Map<String, dynamic> json) {
    final rowNumber = json['rowNumber'];
    final outcome = json['outcome'];
    final rawValues = json['rawValues'];

    if (rowNumber is! int || outcome is! String) {
      throw const ValidationException(
        'Invalid customer import report row payload.',
        code: 'invalid_customer_import_report_payload',
      );
    }

    return CustomerImportRowReport(
      rowNumber: rowNumber,
      outcome: CustomerImportRowOutcomeCode.fromCode(outcome),
      reason: json['reason'] as String?,
      createdCustomerId: json['createdCustomerId'] as String?,
      matchedExistingCustomerId: json['matchedExistingCustomerId'] as String?,
      matchedByEmailOnly: json['matchedByEmailOnly'] as bool? ?? false,
      resolution: json['resolution'] as String?,
      rawValues: rawValues == null
          ? const <String, String>{}
          : Map<String, String>.from(rawValues as Map),
    );
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/customer_import_row_outcome.dart';

part 'customer_import_row_report.freezed.dart';

/// The outcome of one spreadsheet row, as written by
/// `processCustomerImportJob` into the job's report file (TASK-167). Every
/// row of the source file gets exactly one of these — including the
/// successfully imported ones — so the report table can show "linhas
/// processadas, importadas com sucesso, rejeitadas (com motivo por linha) e
/// duplicadas" in one place.
@freezed
abstract class CustomerImportRowReport with _$CustomerImportRowReport {
  const factory CustomerImportRowReport({
    /// 1-based position in the source file, counting only data rows (not
    /// the header, when [CustomerImportMapping.hasHeaderRow] is true) — the
    /// same numbering the gestor sees when they open the spreadsheet.
    required int rowNumber,
    required CustomerImportRowOutcome outcome,

    /// Human-readable reason, always present for [CustomerImportRowOutcome
    /// .rejected]/`duplicateInFile`/`duplicateExisting`, always absent for
    /// `imported`.
    String? reason,

    /// The created `Customer.id`, only for [CustomerImportRowOutcome
    /// .imported].
    String? createdCustomerId,

    /// The `Customer.id` this row collided with, only for
    /// [CustomerImportRowOutcome.duplicateExisting] — lets the gestor jump
    /// straight to the existing customer record.
    String? matchedExistingCustomerId,

    /// Whether [matchedExistingCustomerId] matched by e-mail only (not by
    /// document) — the only case `resolveCustomerImportDuplicateRow` accepts
    /// [CustomerImportDuplicateResolution.createAnyway] for.
    @Default(false) bool matchedByEmailOnly,

    /// The gestor's decision for a `duplicateExisting` row, once resolved —
    /// `null` while still pending review.
    String? resolution,

    /// Raw mapped values as read from the spreadsheet (field code -> raw
    /// text), shown in the report row for context without needing the
    /// original file again.
    @Default(<String, String>{}) Map<String, String> rawValues,
  }) = _CustomerImportRowReport;
}

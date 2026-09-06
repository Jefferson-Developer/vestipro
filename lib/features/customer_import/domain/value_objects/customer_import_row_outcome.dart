/// What happened to one spreadsheet row after `processCustomerImportJob`
/// (Cloud Function) validated/processed it (TASK-167). Persisted per row in
/// the import report (`CustomerImportReport.rows`) so the gestor sees a
/// reason for every single line, never just an aggregate count — "Nenhuma
/// linha inválida pode interromper o processamento das demais; erros são
/// coletados por linha" (AGENTS.md).
enum CustomerImportRowOutcome {
  /// A new `Customer` document was created from this row.
  imported,

  /// The row failed validation (missing required field, invalid CNPJ/CPF,
  /// malformed e-mail, ...) — see the row's `reason` for which.
  rejected,

  /// The row's document (or, absent a document collision, its e-mail)
  /// matches another row already in this same file — never imported
  /// automatically.
  duplicateInFile,

  /// The row's document (or e-mail) matches a `Customer` already registered
  /// in this organization — never imported automatically; the gestor
  /// decides via `resolveCustomerImportDuplicateRow` (ignore/merge, or
  /// create-anyway when the match was only by e-mail, never when it was by
  /// document — `Customer.document` uniqueness per organization is a hard
  /// invariant, see `CustomerRepository.existsByDocument`).
  duplicateExisting,
}

extension CustomerImportRowOutcomeCode on CustomerImportRowOutcome {
  String get code {
    return switch (this) {
      CustomerImportRowOutcome.imported => 'imported',
      CustomerImportRowOutcome.rejected => 'rejected',
      CustomerImportRowOutcome.duplicateInFile => 'duplicateInFile',
      CustomerImportRowOutcome.duplicateExisting => 'duplicateExisting',
    };
  }

  static CustomerImportRowOutcome fromCode(String code) {
    return switch (code) {
      'rejected' => CustomerImportRowOutcome.rejected,
      'duplicateInFile' => CustomerImportRowOutcome.duplicateInFile,
      'duplicateExisting' => CustomerImportRowOutcome.duplicateExisting,
      _ => CustomerImportRowOutcome.imported,
    };
  }
}

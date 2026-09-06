/// The outcome of one spreadsheet row, as written by
/// `processProductImportJob` into the job's report file (TASK-168).
///
/// Deliberately a simpler set than `CustomerImportRowOutcome` (TASK-167):
/// a product import never merges/overwrites an existing product — a SKU
/// conflict is always [rejected], never a "resolve later" state — so there
/// is no duplicate-resolution workflow for products (`tasks.md`: "conflito é
/// sempre reportado, nunca sobrescreve produto existente silenciosamente").
enum ProductImportRowOutcome { created, rejected }

extension ProductImportRowOutcomeCode on ProductImportRowOutcome {
  String get code {
    return switch (this) {
      ProductImportRowOutcome.created => 'created',
      ProductImportRowOutcome.rejected => 'rejected',
    };
  }

  static ProductImportRowOutcome fromCode(String code) {
    return switch (code) {
      'rejected' => ProductImportRowOutcome.rejected,
      _ => ProductImportRowOutcome.created,
    };
  }
}

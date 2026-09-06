/// The gestor's decision for one `duplicateExisting` row of a finished
/// `CustomerImportJob` (TASK-167), sent to the
/// `resolveCustomerImportDuplicateRow` Cloud Function.
///
/// [createAnyway] is only ever accepted by the Function when the row's
/// duplicate match was by e-mail alone (never when it was by document): two
/// different `Customer`s legitimately sharing one e-mail is a real business
/// case (e.g. a shared purchasing inbox), but two `Customer`s sharing one
/// CNPJ/CPF inside the same organization is not — that invariant is
/// enforced independently by `CustomerRepository.existsByDocument` and must
/// never be bypassed by an import decision.
enum CustomerImportDuplicateResolution { ignore, merge, createAnyway }

extension CustomerImportDuplicateResolutionCode
    on CustomerImportDuplicateResolution {
  String get code {
    return switch (this) {
      CustomerImportDuplicateResolution.ignore => 'ignore',
      CustomerImportDuplicateResolution.merge => 'merge',
      CustomerImportDuplicateResolution.createAnyway => 'createAnyway',
    };
  }
}

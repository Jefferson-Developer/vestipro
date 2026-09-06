import '../entities/customer_import_mapping.dart';
import '../value_objects/customer_import_field.dart';

/// Validates a [CustomerImportMapping] before an import job can start
/// (TASK-167) — purely a client-side, fail-fast UX check ("o gestor mapeia
/// colunas visualmente" without discovering the mapping is incomplete only
/// after uploading). The Cloud Function re-validates the exact same rules
/// independently before creating the job, since a forged/stale client
/// mapping must never be trusted.
///
/// Returns field-error messages keyed by [CustomerImportField.code], empty
/// when the mapping is valid.
Map<String, String> validateCustomerImportMapping(
  CustomerImportMapping mapping,
) {
  final errors = <String, String>{};

  if (!mapping.mapsDocument) {
    errors[CustomerImportField.document.code] =
        'Mapeie uma coluna para CNPJ/CPF — obrigatório para detectar '
        'duplicidade.';
  }

  if (!mapping.mapsAnyNameField) {
    errors['name'] =
        'Mapeie ao menos uma coluna de nome (razão social, nome fantasia '
        'ou nome completo).';
  }

  final usedColumns = <int, List<CustomerImportField>>{};
  for (final entry in mapping.columnByField.entries) {
    usedColumns
        .putIfAbsent(entry.value, () => <CustomerImportField>[])
        .add(entry.key);
  }
  for (final entry in usedColumns.entries) {
    if (entry.value.length > 1) {
      for (final field in entry.value) {
        errors[field.code] =
            'Esta coluna já está mapeada para '
            '${entry.value.firstWhere((f) => f != field, orElse: () => field).label}.';
      }
    }
  }

  return errors;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'customer_import_mapping.dart';

part 'customer_import_template.freezed.dart';

/// A saved, reusable column-mapping (TASK-167 — "Permitir salvar um
/// template de mapeamento reutilizável por organização, para reimportações
/// futuras do mesmo formato de planilha"). Scoped by [organizationId] only
/// (never by company/user): the whole point is that any gestor in the same
/// organization who receives the same spreadsheet layout (e.g. always from
/// the same distributor/ERP export) can reuse it without remapping columns
/// manually.
@freezed
abstract class CustomerImportTemplate with _$CustomerImportTemplate {
  const factory CustomerImportTemplate({
    required String id,
    required String organizationId,
    required String name,
    required CustomerImportMapping mapping,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _CustomerImportTemplate;
}

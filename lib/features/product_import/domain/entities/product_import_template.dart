import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_import_mapping.dart';

part 'product_import_template.freezed.dart';

/// Reusable, organization-scoped column-mapping template for the product
/// import wizard (TASK-168) — same low-risk, client-writable config shape as
/// `CustomerImportTemplate` (TASK-167): no financial/authorization impact,
/// so the client may create/update/delete it directly (see
/// `firestore.rules`'s `productImportTemplates`).
@freezed
abstract class ProductImportTemplate with _$ProductImportTemplate {
  const factory ProductImportTemplate({
    required String id,
    required String organizationId,
    required String name,
    required ProductImportMapping mapping,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _ProductImportTemplate;
}

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/product.dart';
import '../entities/product_custom_field_value.dart';
import '../repositories/product_repository.dart';
import '../value_objects/ean.dart';
import '../value_objects/product_gender.dart';
import '../value_objects/product_status.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/sku.dart';
import '../value_objects/target_audience.dart';
import 'product_use_case_helpers.dart';

/// Updates an existing Product's editable fields (TASK-065).
///
/// Never changes [Product.status] itself — publishing is
/// `PublishProductUseCase`'s exclusive responsibility, so a caller cannot
/// smuggle a product into [ProductStatus.active] through a plain edit
/// without going through the completeness check.
///
/// "Toda alteração em produto já publicado deve gerar auditoria" (the
/// task's business rule) is enforced here: whenever the product being
/// edited is not (and never was, since the last publish) a
/// [ProductStatus.draft], every changed field is recorded in the central
/// audit log ([AuditAction.productUpdated]) via [AuditLogEntryFactory] —
/// the same direct-repository pattern `AssignRoleToUserUseCase` (TASK-033)
/// already uses, not `RecordAuditLogUseCase`, so this use case does not pay
/// for a second dependency only to rebuild the exact same entry. If the
/// audit write itself fails, that failure is propagated instead of being
/// silently discarded, even though the product mutation already succeeded
/// by then (`AGENTS.md`: "nenhuma dessas ações pode passar em silêncio") —
/// the same documented, not-yet-atomic limitation `AssignRoleToUserUseCase`
/// carries until a Cloud Function/trigger records both together.
@injectable
final class UpdateProductUseCase {
  UpdateProductUseCase(this._repository, this._auditLogRepository);

  final ProductRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String id,
    required String sku,
    required String reference,
    required String name,
    String? shortDescription,
    String? fullDescription,
    String? brand,
    String? collectionId,
    String? seasonId,
    String? line,
    String? categoryId,
    String? subcategoryId,
    ProductGender? gender,
    TargetAudience? targetAudience,
    String? fabric,
    String? composition,
    String? supplierId,
    String? ncm,
    String? ean,
    List<String> tags = const <String>[],
    List<String>? colorIds,
    String? sizeGridTemplateId,
    DateTime? launchDate,
    String? seoTitle,
    String? seoDescription,
    String? seoSlug,
    List<ProductCustomFieldValue>? customFieldValues,
    required String updatedBy,
    required String actorName,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedReference = reference.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final trimmedActorName = actorName.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedReference.isEmpty) {
      fieldErrors['reference'] = 'Informe a referência do produto.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome do produto.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    Sku? parsedSku;
    try {
      parsedSku = Sku.parse(sku);
    } on ValidationException catch (exception) {
      fieldErrors.addAll(
        exception.fieldErrors.isEmpty
            ? <String, String>{'sku': exception.message}
            : exception.fieldErrors,
      );
    }

    Ean? parsedEan;
    final trimmedEan = ean?.trim();
    if (trimmedEan != null && trimmedEan.isNotEmpty) {
      try {
        parsedEan = Ean.parse(trimmedEan);
      } on ValidationException catch (exception) {
        fieldErrors.addAll(
          exception.fieldErrors.isEmpty
              ? <String, String>{'ean': exception.message}
              : exception.fieldErrors,
        );
      }
    }

    if (fieldErrors.isNotEmpty || parsedSku == null) {
      return AppFailure<Product>(
        ValidationFailure(
          'Invalid product update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_update_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<Product>) return currentResult;
    final current = (currentResult as AppSuccess<Product>).value;

    final duplicateResult = await _repository.existsBySku(
      organizationId: trimmedOrganizationId,
      sku: parsedSku,
      excludingProductId: trimmedId,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<Product>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return AppFailure<Product>(
        const ConflictFailure(
          'Product SKU already exists in this organization.',
          code: 'product_sku_already_exists',
        ),
      );
    }

    final updated = current.copyWith(
      sku: parsedSku,
      reference: trimmedReference,
      name: trimmedName,
      shortDescription: normalizeProductOptional(shortDescription),
      fullDescription: normalizeProductOptional(fullDescription),
      brand: normalizeProductOptional(brand),
      collectionId: normalizeProductOptional(collectionId),
      seasonId: normalizeProductOptional(seasonId),
      line: normalizeProductOptional(line),
      categoryId: normalizeProductOptional(categoryId),
      subcategoryId: normalizeProductOptional(subcategoryId),
      gender: gender,
      targetAudience: targetAudience,
      fabric: normalizeProductOptional(fabric),
      composition: normalizeProductOptional(composition),
      supplierId: normalizeProductOptional(supplierId),
      ncm: normalizeProductOptional(ncm),
      ean: parsedEan,
      tags: normalizeProductTags(tags),
      colorIds: colorIds == null ? current.colorIds : _normalizeIds(colorIds),
      sizeGridTemplateId: normalizeProductOptional(sizeGridTemplateId),
      launchDate: launchDate?.toUtc(),
      seoTitle: normalizeProductOptional(seoTitle),
      seoDescription: normalizeProductOptional(seoDescription),
      seoSlug: normalizeProductOptional(seoSlug),
      customFieldValues: customFieldValues ?? current.customFieldValues,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );

    final mutationResult = await _repository.update(product: updated);
    if (mutationResult is AppFailure<Product>) return mutationResult;

    if (current.status != ProductStatus.draft) {
      final diff = _diff(current, updated);
      if (diff.previousValue.isNotEmpty) {
        final auditEntry = AuditLogEntryFactory.build(
          organizationId: trimmedOrganizationId,
          actorUserId: trimmedUpdatedBy,
          actorName: trimmedActorName.isEmpty
              ? trimmedUpdatedBy
              : trimmedActorName,
          action: AuditAction.productUpdated,
          entityType: 'product',
          entityId: trimmedId,
          previousValue: diff.previousValue,
          newValue: diff.newValue,
        );
        final auditResult = await _auditLogRepository.record(auditEntry);
        if (auditResult is AppFailure<AuditLogEntry>) {
          return AppFailure<Product>(auditResult.failure);
        }
      }
    }

    return mutationResult;
  }

  _ProductDiff _diff(Product previous, Product next) {
    final previousValue = <String, Object?>{};
    final newValue = <String, Object?>{};

    void track(String field, Object? previousField, Object? nextField) {
      if (previousField == nextField) return;
      previousValue[field] = previousField;
      newValue[field] = nextField;
    }

    track('sku', previous.sku.value, next.sku.value);
    track('reference', previous.reference, next.reference);
    track('name', previous.name, next.name);
    track('brand', previous.brand, next.brand);
    track('categoryId', previous.categoryId, next.categoryId);
    track('subcategoryId', previous.subcategoryId, next.subcategoryId);
    track('collectionId', previous.collectionId, next.collectionId);
    track('seasonId', previous.seasonId, next.seasonId);
    track('ean', previous.ean?.digits, next.ean?.digits);
    track('colorIds', previous.colorIds.join(','), next.colorIds.join(','));
    track(
      'sizeGridTemplateId',
      previous.sizeGridTemplateId,
      next.sizeGridTemplateId,
    );
    track('ncm', previous.ncm, next.ncm);

    return _ProductDiff(previousValue: previousValue, newValue: newValue);
  }
}

List<String> _normalizeIds(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);

final class _ProductDiff {
  const _ProductDiff({required this.previousValue, required this.newValue});

  final Map<String, Object?> previousValue;
  final Map<String, Object?> newValue;
}

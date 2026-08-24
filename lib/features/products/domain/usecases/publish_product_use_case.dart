import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/product.dart';
import '../product_completeness_validator.dart';
import '../repositories/product_repository.dart';
import '../value_objects/product_status.dart';
import '../value_objects/product_sync_status.dart';

/// Centralizes the Product publication rule (TASK-065's acceptance
/// criteria): the only path from [ProductStatus.draft] to
/// [ProductStatus.active], gated by
/// [validateProductCompletenessForPublish] so a Product can never become
/// active while missing its minimal required fields (name, SKU, reference,
/// category).
///
/// RBAC (`Capability.catalogManage`) is enforced by the caller
/// (`ProductFormBloc`/UI), the same "UI only shows/enables, backend/Cloud
/// Function eventually re-validates" contract every other VestiPro use case
/// follows — this use case re-validates only completeness, the one rule
/// that is this feature's own, never permissions.
///
/// Every successful publish is recorded in the central audit log
/// ([AuditAction.productPublished]) via [AuditLogEntryFactory], the same
/// direct-repository pattern `AssignRoleToUserUseCase`/
/// `UpdateProductUseCase` already use.
@injectable
final class PublishProductUseCase {
  PublishProductUseCase(this._repository, this._auditLogRepository);

  final ProductRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String id,
    required String publishedBy,
    required String actorName,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedPublishedBy = publishedBy.trim();
    final trimmedActorName = actorName.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedPublishedBy.isEmpty) {
      fieldErrors['publishedBy'] = 'PublishedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Product>(
        ValidationFailure(
          'Invalid product publish payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_publish_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<Product>) return currentResult;
    final current = (currentResult as AppSuccess<Product>).value;

    if (current.status != ProductStatus.draft) {
      return AppFailure<Product>(
        const ValidationFailure(
          'Only a draft product can be published.',
          fieldErrors: <String, String>{
            'status': 'Somente um produto em rascunho pode ser publicado.',
          },
          code: 'product_not_in_draft',
        ),
      );
    }

    final completenessErrors = validateProductCompletenessForPublish(
      name: current.name,
      sku: current.sku.value,
      reference: current.reference,
      categoryId: current.categoryId,
    );
    if (completenessErrors.isNotEmpty) {
      return AppFailure<Product>(
        ValidationFailure(
          'Product is not complete enough to be published.',
          fieldErrors: completenessErrors,
          code: 'product_incomplete_for_publish',
        ),
      );
    }

    final updated = current.copyWith(
      status: ProductStatus.active,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedPublishedBy,
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );

    final mutationResult = await _repository.update(product: updated);
    if (mutationResult is AppFailure<Product>) return mutationResult;

    final auditEntry = AuditLogEntryFactory.build(
      organizationId: trimmedOrganizationId,
      actorUserId: trimmedPublishedBy,
      actorName: trimmedActorName.isEmpty
          ? trimmedPublishedBy
          : trimmedActorName,
      action: AuditAction.productPublished,
      entityType: 'product',
      entityId: trimmedId,
      previousValue: const <String, Object?>{'status': 'draft'},
      newValue: const <String, Object?>{'status': 'active'},
    );
    final auditResult = await _auditLogRepository.record(auditEntry);
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<Product>(auditResult.failure);
    }

    return mutationResult;
  }
}

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/product.dart';
import '../entities/product_media.dart';
import '../repositories/product_repository.dart';
import '../value_objects/product_status.dart';
import '../value_objects/product_sync_status.dart';

/// Persists a full replacement of `Product.media` (TASK-068) — the single
/// write path every gallery mutation (`ProductMediaBloc`'s append/reorder/
/// set-principal/remove) goes through, so no caller ever calls
/// `ProductRepository.update` directly with a hand-built media list.
///
/// Mirrors `UpdateProductUseCase`'s already-published-product auditing rule:
/// "toda alteração em produto já publicado deve gerar auditoria" applies to
/// the media gallery exactly like every other section of the form, tracked
/// here as photo/video counts and the principal photo id rather than the
/// full list (a gallery can hold many large URLs — the audit log stores a
/// summary, not a duplicate of the media list itself).
@injectable
final class UpdateProductMediaUseCase {
  UpdateProductMediaUseCase(this._repository, this._auditLogRepository);

  final ProductRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String id,
    required List<ProductMedia> media,
    required String updatedBy,
    required String actorName,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final trimmedActorName = actorName.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Product>(
        ValidationFailure(
          'Invalid product media update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_media_update_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<Product>) return currentResult;
    final current = (currentResult as AppSuccess<Product>).value;

    final updated = current.copyWith(
      media: media,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );

    final mutationResult = await _repository.update(product: updated);
    if (mutationResult is AppFailure<Product>) return mutationResult;

    if (current.status != ProductStatus.draft) {
      final auditEntry = AuditLogEntryFactory.build(
        organizationId: trimmedOrganizationId,
        actorUserId: trimmedUpdatedBy,
        actorName: trimmedActorName.isEmpty
            ? trimmedUpdatedBy
            : trimmedActorName,
        action: AuditAction.productUpdated,
        entityType: 'product',
        entityId: trimmedId,
        previousValue: <String, Object?>{
          'mediaCount': current.media.length,
          'principalPhotoId': current.principalPhoto?.id,
        },
        newValue: <String, Object?>{
          'mediaCount': updated.media.length,
          'principalPhotoId': updated.principalPhoto?.id,
        },
      );
      final auditResult = await _auditLogRepository.record(auditEntry);
      if (auditResult is AppFailure<AuditLogEntry>) {
        return AppFailure<Product>(auditResult.failure);
      }
    }

    return mutationResult;
  }
}

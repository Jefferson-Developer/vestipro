import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/discount_policy.dart';
import '../repositories/discount_policy_repository.dart';
import '../value_objects/discount_policy_status.dart';
import 'create_discount_policy_use_case.dart';

@injectable
final class UpdateDiscountPolicyUseCase {
  UpdateDiscountPolicyUseCase(this._repository, this._auditLogRepository);

  final DiscountPolicyRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<DiscountPolicy>> call({
    required String organizationId,
    required String id,
    required String role,
    required double maxDiscountPercent,
    List<String> priceListIds = const <String>[],
    double? requiresApprovalAbovePercent,
    required DiscountPolicyStatus status,
    required String updatedBy,
    required String actorName,
  }) async {
    final fieldErrors = validateDiscountPolicyFields(
      id: id,
      organizationId: organizationId,
      companyId: 'placeholder',
      role: role,
      maxDiscountPercent: maxDiscountPercent,
      priceListIds: priceListIds,
      requiresApprovalAbovePercent: requiresApprovalAbovePercent,
      userIdKey: 'updatedBy',
      userIdValue: updatedBy,
    )..remove('companyId');
    if (fieldErrors.isNotEmpty) {
      return AppFailure<DiscountPolicy>(
        ValidationFailure(
          'Invalid discount policy update payload.',
          code: 'invalid_discount_policy_update_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
    if (currentResult is AppFailure<DiscountPolicy?>) {
      return AppFailure<DiscountPolicy>(currentResult.failure);
    }
    final current = (currentResult as AppSuccess<DiscountPolicy?>).value;
    if (current == null) {
      return const AppFailure<DiscountPolicy>(
        NotFoundFailure(
          'Discount policy not found.',
          code: 'discount_policy_not_found',
        ),
      );
    }

    final updated = current.copyWith(
      role: role.trim(),
      maxDiscountPercent: maxDiscountPercent,
      priceListIds: normalizeIdList(priceListIds),
      requiresApprovalAbovePercent: requiresApprovalAbovePercent,
      clearRequiresApprovalAbovePercent: requiresApprovalAbovePercent == null,
      status: status,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: current.version + 1,
      syncStatus: 'pending',
    );

    final result = await _repository.update(discountPolicy: updated);
    if (result is AppFailure<DiscountPolicy>) return result;

    final action =
        current.status == DiscountPolicyStatus.active &&
            updated.status == DiscountPolicyStatus.inactive
        ? AuditAction.discountPolicyDeactivated
        : AuditAction.discountPolicyUpdated;

    final auditResult = await _auditLogRepository.record(
      AuditLogEntryFactory.build(
        organizationId: current.organizationId,
        actorUserId: updated.updatedBy,
        actorName: actorName.trim().isEmpty ? updated.updatedBy : actorName,
        action: action,
        entityType: 'discountPolicy',
        entityId: updated.id,
        previousValue: current.toAuditMap(),
        newValue: updated.toAuditMap(),
      ),
    );
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<DiscountPolicy>(auditResult.failure);
    }

    return result;
  }
}

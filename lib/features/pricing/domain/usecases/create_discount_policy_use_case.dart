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

@injectable
final class CreateDiscountPolicyUseCase {
  CreateDiscountPolicyUseCase(this._repository, this._auditLogRepository);

  final DiscountPolicyRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<DiscountPolicy>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String role,
    required double maxDiscountPercent,
    List<String> priceListIds = const <String>[],
    double? requiresApprovalAbovePercent,
    DiscountPolicyStatus status = DiscountPolicyStatus.active,
    required String createdBy,
    required String actorName,
  }) async {
    final fieldErrors = validateDiscountPolicyFields(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      role: role,
      maxDiscountPercent: maxDiscountPercent,
      priceListIds: priceListIds,
      requiresApprovalAbovePercent: requiresApprovalAbovePercent,
      userIdKey: 'createdBy',
      userIdValue: createdBy,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<DiscountPolicy>(
        ValidationFailure(
          'Invalid discount policy creation payload.',
          code: 'invalid_discount_policy_create_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final policy = DiscountPolicy(
      id: id.trim(),
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
      role: role.trim(),
      maxDiscountPercent: maxDiscountPercent,
      priceListIds: normalizeIdList(priceListIds),
      requiresApprovalAbovePercent: requiresApprovalAbovePercent,
      status: status,
      createdAt: now,
      createdBy: createdBy.trim(),
      updatedAt: now,
      updatedBy: createdBy.trim(),
    );

    final result = await _repository.create(discountPolicy: policy);
    if (result is AppFailure<DiscountPolicy>) return result;

    final auditResult = await _auditLogRepository.record(
      AuditLogEntryFactory.build(
        organizationId: policy.organizationId,
        actorUserId: policy.createdBy,
        actorName: actorName.trim().isEmpty ? policy.createdBy : actorName,
        action: AuditAction.discountPolicyCreated,
        entityType: 'discountPolicy',
        entityId: policy.id,
        newValue: policy.toAuditMap(),
      ),
    );
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<DiscountPolicy>(auditResult.failure);
    }

    return result;
  }
}

Map<String, String> validateDiscountPolicyFields({
  required String id,
  required String organizationId,
  required String companyId,
  required String role,
  required double maxDiscountPercent,
  required List<String> priceListIds,
  required double? requiresApprovalAbovePercent,
  required String userIdKey,
  required String userIdValue,
}) {
  final fieldErrors = <String, String>{};
  if (id.trim().isEmpty) fieldErrors['id'] = 'Id is required.';
  if (organizationId.trim().isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (companyId.trim().isEmpty) {
    fieldErrors['companyId'] = 'CompanyId is required.';
  }
  if (role.trim().isEmpty) fieldErrors['role'] = 'Informe o perfil.';
  if (userIdValue.trim().isEmpty) {
    fieldErrors[userIdKey] = '$userIdKey is required.';
  }
  if (maxDiscountPercent.isNaN ||
      maxDiscountPercent.isInfinite ||
      maxDiscountPercent < 0 ||
      maxDiscountPercent > 100) {
    fieldErrors['maxDiscountPercent'] =
        'Informe um limite máximo entre 0% e 100%.';
  }
  if (requiresApprovalAbovePercent != null &&
      (requiresApprovalAbovePercent.isNaN ||
          requiresApprovalAbovePercent.isInfinite ||
          requiresApprovalAbovePercent < 0 ||
          requiresApprovalAbovePercent > maxDiscountPercent)) {
    fieldErrors['requiresApprovalAbovePercent'] =
        'O gatilho de aprovação deve ficar entre 0% e o limite máximo.';
  }

  final normalizedIds = normalizeIdList(priceListIds);
  if (normalizedIds.length !=
      priceListIds.where((id) => id.trim().isNotEmpty).length) {
    fieldErrors['priceListIds'] =
        'Não repita a mesma tabela de preço na política.';
  }
  return fieldErrors;
}

List<String> normalizeIdList(List<String> ids) => ids
    .map((id) => id.trim())
    .where((id) => id.isNotEmpty)
    .toSet()
    .toList(growable: false);

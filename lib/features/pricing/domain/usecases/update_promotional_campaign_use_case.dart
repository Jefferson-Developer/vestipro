import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/promotional_campaign.dart';
import '../repositories/promotional_campaign_repository.dart';
import '../value_objects/promotional_campaign_status.dart';
import '../value_objects/promotional_discount_type.dart';
import 'create_promotional_campaign_use_case.dart';

@injectable
final class UpdatePromotionalCampaignUseCase {
  UpdatePromotionalCampaignUseCase(this._repository, this._auditLogRepository);

  final PromotionalCampaignRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<PromotionalCampaign>> call({
    required String organizationId,
    required String id,
    required String name,
    required DateTime validFrom,
    required DateTime validTo,
    required String customerSegment,
    List<String> productIds = const <String>[],
    List<String> collectionIds = const <String>[],
    List<String> categoryIds = const <String>[],
    required PromotionalDiscountType discountType,
    required double discountValue,
    required bool stackableWithOtherCampaigns,
    required int priority,
    required PromotionalCampaignStatus status,
    required String updatedBy,
    required String actorName,
  }) async {
    final fieldErrors = validatePromotionalCampaignFields(
      id: id,
      organizationId: organizationId,
      companyId: 'placeholder',
      name: name,
      validFrom: validFrom,
      validTo: validTo,
      customerSegment: customerSegment,
      productIds: productIds,
      collectionIds: collectionIds,
      categoryIds: categoryIds,
      discountValue: discountValue,
      priority: priority,
      userIdKey: 'updatedBy',
      userIdValue: updatedBy,
    )..remove('companyId');
    if (fieldErrors.isNotEmpty) {
      return AppFailure<PromotionalCampaign>(
        ValidationFailure(
          'Invalid promotional campaign update payload.',
          code: 'invalid_promotional_campaign_update_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
    if (currentResult is AppFailure<PromotionalCampaign?>) {
      return AppFailure<PromotionalCampaign>(currentResult.failure);
    }
    final current = (currentResult as AppSuccess<PromotionalCampaign?>).value;
    if (current == null) {
      return const AppFailure<PromotionalCampaign>(
        NotFoundFailure(
          'Promotional campaign not found.',
          code: 'promotional_campaign_not_found',
        ),
      );
    }

    final updated = current.copyWith(
      name: name.trim(),
      validFrom: validFrom.toUtc(),
      validTo: validTo.toUtc(),
      customerSegment: customerSegment.trim(),
      productIds: _normalize(productIds),
      collectionIds: _normalize(collectionIds),
      categoryIds: _normalize(categoryIds),
      discountType: discountType,
      discountValue: discountValue,
      stackableWithOtherCampaigns: stackableWithOtherCampaigns,
      priority: priority,
      status: status,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: current.version + 1,
      syncStatus: 'pending',
    );

    final result = await _repository.update(campaign: updated);
    if (result is AppFailure<PromotionalCampaign>) return result;

    final action =
        current.status != PromotionalCampaignStatus.ended &&
            updated.status == PromotionalCampaignStatus.ended
        ? AuditAction.promotionalCampaignEnded
        : AuditAction.promotionalCampaignUpdated;

    final auditResult = await _auditLogRepository.record(
      AuditLogEntryFactory.build(
        organizationId: updated.organizationId,
        actorUserId: updated.updatedBy,
        actorName: actorName.trim().isEmpty ? updated.updatedBy : actorName,
        action: action,
        entityType: 'promotionalCampaign',
        entityId: updated.id,
        previousValue: current.toAuditMap(),
        newValue: updated.toAuditMap(),
      ),
    );
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<PromotionalCampaign>(auditResult.failure);
    }

    return result;
  }
}

List<String> _normalize(List<String> ids) => ids
    .map((id) => id.trim())
    .where((id) => id.isNotEmpty)
    .toSet()
    .toList(growable: false);

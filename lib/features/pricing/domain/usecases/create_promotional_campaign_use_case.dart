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

@injectable
final class CreatePromotionalCampaignUseCase {
  CreatePromotionalCampaignUseCase(this._repository, this._auditLogRepository);

  final PromotionalCampaignRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<PromotionalCampaign>> call({
    required String id,
    required String organizationId,
    required String companyId,
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
    PromotionalCampaignStatus status = PromotionalCampaignStatus.active,
    required String createdBy,
    required String actorName,
  }) async {
    final fieldErrors = validatePromotionalCampaignFields(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      name: name,
      validFrom: validFrom,
      validTo: validTo,
      customerSegment: customerSegment,
      productIds: productIds,
      collectionIds: collectionIds,
      categoryIds: categoryIds,
      discountValue: discountValue,
      priority: priority,
      userIdKey: 'createdBy',
      userIdValue: createdBy,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<PromotionalCampaign>(
        ValidationFailure(
          'Invalid promotional campaign creation payload.',
          code: 'invalid_promotional_campaign_create_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final campaign = PromotionalCampaign(
      id: id.trim(),
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
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
      createdAt: now,
      createdBy: createdBy.trim(),
      updatedAt: now,
      updatedBy: createdBy.trim(),
    );

    final result = await _repository.create(campaign: campaign);
    if (result is AppFailure<PromotionalCampaign>) return result;

    final auditResult = await _auditLogRepository.record(
      AuditLogEntryFactory.build(
        organizationId: campaign.organizationId,
        actorUserId: campaign.createdBy,
        actorName: actorName.trim().isEmpty ? campaign.createdBy : actorName,
        action: AuditAction.promotionalCampaignCreated,
        entityType: 'promotionalCampaign',
        entityId: campaign.id,
        newValue: campaign.toAuditMap(),
      ),
    );
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<PromotionalCampaign>(auditResult.failure);
    }

    return result;
  }
}

Map<String, String> validatePromotionalCampaignFields({
  required String id,
  required String organizationId,
  required String companyId,
  required String name,
  required DateTime validFrom,
  required DateTime validTo,
  required String customerSegment,
  required List<String> productIds,
  required List<String> collectionIds,
  required List<String> categoryIds,
  required double discountValue,
  required int priority,
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
  if (name.trim().isEmpty) fieldErrors['name'] = 'Informe o nome da campanha.';
  if (customerSegment.trim().isEmpty) {
    fieldErrors['customerSegment'] = 'Informe o segmento de cliente.';
  }
  if (validTo.isBefore(validFrom)) {
    fieldErrors['validTo'] = 'A vigência final deve ser posterior ao início.';
  }
  if (discountValue.isNaN || discountValue.isInfinite || discountValue <= 0) {
    fieldErrors['discountValue'] =
        'O valor do desconto deve ser maior que zero.';
  }
  if (priority < 0) {
    fieldErrors['priority'] = 'A prioridade deve ser zero ou maior.';
  }
  if (userIdValue.trim().isEmpty) {
    fieldErrors[userIdKey] = '$userIdKey is required.';
  }

  final hasScope =
      productIds.any((id) => id.trim().isNotEmpty) ||
      collectionIds.any((id) => id.trim().isNotEmpty) ||
      categoryIds.any((id) => id.trim().isNotEmpty);
  if (!hasScope) {
    fieldErrors['productScope'] =
        'Informe ao menos um produto, coleção ou categoria elegível.';
  }
  return fieldErrors;
}

List<String> _normalize(List<String> ids) => ids
    .map((id) => id.trim())
    .where((id) => id.isNotEmpty)
    .toSet()
    .toList(growable: false);

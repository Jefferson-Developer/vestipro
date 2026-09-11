import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/assortment_rule.dart';
import '../entities/commercial_pack.dart';
import '../entities/pack_component.dart';
import '../repositories/commercial_pack_repository.dart';
import '../value_objects/commercial_pack_pricing_policy_type.dart';
import '../value_objects/commercial_pack_status.dart';
import '../value_objects/commercial_pack_stock_policy_type.dart';
import '../value_objects/commercial_pack_sync_status.dart';
import '../value_objects/commercial_pack_type.dart';
import 'validate_commercial_pack_composition_use_case.dart';

/// Directly edits a `CommercialPack` that is still [CommercialPackStatus
/// .draft] (TASK-207, EPIC-32) — the only status this use case ever
/// accepts as the *current* one. Once a pack has been published
/// ([CommercialPackStatus.active]), any further change must go through
/// `ReviseCommercialPackUseCase` instead, which creates a brand-new
/// version rather than mutating the published one in place (TASK-207
/// business rule: "alteração em pacote ativo deve versionar").
///
/// [status] may only move a draft to [CommercialPackStatus.draft]
/// (unpublished edit), [CommercialPackStatus.active] (publish) or
/// [CommercialPackStatus.archived] (retire without ever having been
/// published) — never to [CommercialPackStatus.superseded]
/// (`ReviseCommercialPackUseCase`'s exclusive responsibility) nor
/// [CommercialPackStatus.expired] (a lifecycle job's responsibility, not a
/// direct user edit).
///
/// Only ever grantable to whoever holds `Capability.commercialPackManage`
/// (OWNER/ADMIN/SALES_MANAGER), same RBAC boundary
/// `CreateCommercialPackUseCase` documents.
@injectable
final class UpdateCommercialPackUseCase {
  const UpdateCommercialPackUseCase(this._repository, this._validator);

  final CommercialPackRepository _repository;
  final ValidateCommercialPackCompositionUseCase _validator;

  Future<AppResult<CommercialPack>> call({
    required String organizationId,
    required String id,
    required String name,
    String? description,
    required CommercialPackType packType,
    required CommercialPackStatus status,
    required CommercialPackPricingPolicyType pricingPolicyType,
    double? fixedPrice,
    double? discountPercentage,
    String? bonusComponentId,
    required CommercialPackStockPolicyType stockPolicyType,
    String? dedicatedWarehouseId,
    String? collectionId,
    String? campaignId,
    String? customerSegment,
    String? channel,
    required DateTime validFrom,
    DateTime? validTo,
    List<PackComponent> components = const <PackComponent>[],
    List<AssortmentRule> assortmentRules = const <AssortmentRule>[],
    required String updatedBy,
    PackComponentReferenceResolver? isComponentReferenceValid,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    if (status == CommercialPackStatus.superseded ||
        status == CommercialPackStatus.expired) {
      return AppFailure<CommercialPack>(
        ValidationFailure(
          'Status "${status.name}" can never be set directly through '
          'UpdateCommercialPackUseCase.',
          code: 'commercial_pack_status_not_directly_settable',
          fieldErrors: <String, String>{'status': status.name},
        ),
      );
    }

    final fieldErrors = <String, String>{};
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Name is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (validTo != null && !validTo.toUtc().isAfter(validFrom.toUtc())) {
      fieldErrors['validTo'] = 'ValidTo must be after validFrom.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CommercialPack>(
        ValidationFailure(
          'Invalid commercial pack update payload.',
          code: 'invalid_commercial_pack_update_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<CommercialPack?>) {
      return AppFailure<CommercialPack>(currentResult.failure);
    }
    final current = (currentResult as AppSuccess<CommercialPack?>).value;
    if (current == null) {
      return const AppFailure<CommercialPack>(
        NotFoundFailure(
          'Commercial pack not found.',
          code: 'commercial_pack_not_found',
        ),
      );
    }
    if (current.status != CommercialPackStatus.draft) {
      return const AppFailure<CommercialPack>(
        ValidationFailure(
          'Only a draft commercial pack can be edited directly; an active '
          'pack must be revised into a new version instead '
          '(ReviseCommercialPackUseCase).',
          code: 'commercial_pack_not_draft',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      name: trimmedName,
      description: (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      packType: packType,
      status: status,
      pricingPolicyType: pricingPolicyType,
      fixedPrice: fixedPrice,
      discountPercentage: discountPercentage,
      bonusComponentId: bonusComponentId,
      stockPolicyType: stockPolicyType,
      dedicatedWarehouseId: dedicatedWarehouseId,
      collectionId: collectionId,
      campaignId: campaignId,
      customerSegment: customerSegment,
      channel: channel,
      validFrom: validFrom.toUtc(),
      validTo: validTo?.toUtc(),
      components: components,
      assortmentRules: assortmentRules,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      syncStatus: CommercialPackSyncStatus.pending,
    );

    final existingResult = await _repository.listByOrganization(
      organizationId: updated.organizationId,
    );
    if (existingResult is AppFailure<List<CommercialPack>>) {
      return AppFailure<CommercialPack>(existingResult.failure);
    }
    final existingPacks = (existingResult as AppSuccess<List<CommercialPack>>)
        .value
        .where((pack) => pack.id != updated.id)
        .toList(growable: false);

    final componentsOfPack = _componentsOfPackResolver(existingPacks);
    final validation = _validator(
      pack: updated,
      now: now,
      isComponentReferenceValid: isComponentReferenceValid,
      componentsOfPack: (packId) =>
          packId == updated.id ? updated.components : componentsOfPack(packId),
    );
    if (!validation.isValid) {
      return AppFailure<CommercialPack>(
        ValidationFailure(
          'Invalid commercial pack composition.',
          code: 'invalid_commercial_pack_composition',
          fieldErrors: validation.fieldErrors,
        ),
      );
    }

    return _repository.update(pack: updated);
  }
}

/// Builds a `packId -> its current components` lookup out of [packs] — same
/// shape `CreateCommercialPackUseCase`/`ReviseCommercialPackUseCase` build
/// for `ValidateCommercialPackCompositionUseCase`'s circularity check.
PackComponentsOfPackResolver _componentsOfPackResolver(
  List<CommercialPack> packs,
) {
  final componentsByPackId = <String, List<PackComponent>>{
    for (final pack in packs) pack.id: pack.components,
  };
  return (packId) => componentsByPackId[packId] ?? const <PackComponent>[];
}

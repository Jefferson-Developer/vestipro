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

/// Versions an already-[CommercialPackStatus.active] `CommercialPack`
/// (TASK-207, EPIC-32): the **only** way to change anything about a
/// published pack, since a published version is never mutated in place
/// (TASK-207 business rule: "alteração em pacote ativo deve versionar a
/// configuração para preservar histórico de pedidos antigos").
///
/// Given the current active pack (`currentPackId`), this creates a brand
/// new document (`newPackId`, a caller-supplied id distinct from the
/// current one) carrying the same [CommercialPack.packCode] and
/// `CommercialPack.version` + 1, then flips the current one to
/// [CommercialPackStatus.superseded] with
/// [CommercialPack.supersededByPackId] pointing at the new version — the
/// old document's substantive content (its components, pricing policy,
/// stock policy) is never rewritten, only its lifecycle metadata (`status`,
/// `supersededByPackId`, `updatedAt`/`updatedBy`) changes, so any Order that
/// already references [currentPackId] keeps reading the exact composition
/// it had at the moment that order was placed.
///
/// The new version is always born [CommercialPackStatus.draft] — same
/// "born draft" precedent `CreateCommercialPackUseCase` already follows —
/// so publishing it (draft -> active) is a deliberate, separate step via
/// `UpdateCommercialPackUseCase`, never implicit in this call. This keeps a
/// single responsibility per use case: this one only ever versions/
/// preserves history, it never also decides whether the new version is
/// ready to sell.
///
/// The new document is created *before* the current one is flipped to
/// [CommercialPackStatus.superseded] — if creating the new version fails,
/// nothing changes about the current one (still safely [CommercialPackStatus
/// .active]); if only the supersede step fails after the new version was
/// created, the organization temporarily has two documents for the same
/// [CommercialPack.packCode] that could both resolve as sellable, which is
/// recoverable (retry the supersede step) — the alternative order (supersede
/// first) could instead leave a `packCode` with **no** sellable version at
/// all if creation then failed, which is worse.
///
/// Only ever grantable to whoever holds `Capability.commercialPackManage`
/// (OWNER/ADMIN/SALES_MANAGER), same RBAC boundary
/// `CreateCommercialPackUseCase` documents.
@injectable
final class ReviseCommercialPackUseCase {
  const ReviseCommercialPackUseCase(this._repository, this._validator);

  final CommercialPackRepository _repository;
  final ValidateCommercialPackCompositionUseCase _validator;

  Future<AppResult<CommercialPack>> call({
    required String organizationId,
    required String currentPackId,
    required String newPackId,
    required String name,
    String? description,
    required CommercialPackType packType,
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
    final trimmedCurrentPackId = currentPackId.trim();
    final trimmedNewPackId = newPackId.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedNewPackId.isEmpty) {
      fieldErrors['newPackId'] = 'NewPackId is required.';
    } else if (trimmedNewPackId == trimmedCurrentPackId) {
      fieldErrors['newPackId'] =
          'The revised pack must have a new id, distinct from the current '
          'version.';
    }
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
          'Invalid commercial pack revision payload.',
          code: 'invalid_commercial_pack_revision_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedCurrentPackId,
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
    if (current.status != CommercialPackStatus.active) {
      return const AppFailure<CommercialPack>(
        ValidationFailure(
          'Only an active commercial pack can be revised into a new '
          'version; a draft pack must be edited directly instead '
          '(UpdateCommercialPackUseCase).',
          code: 'commercial_pack_not_active',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final revised = CommercialPack(
      id: trimmedNewPackId,
      organizationId: current.organizationId,
      companyId: current.companyId,
      packCode: current.packCode,
      version: current.version + 1,
      name: trimmedName,
      description: (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      packType: packType,
      status: CommercialPackStatus.draft,
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
      createdAt: now,
      createdBy: trimmedUpdatedBy,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      syncStatus: CommercialPackSyncStatus.pending,
    );

    final existingResult = await _repository.listByOrganization(
      organizationId: current.organizationId,
    );
    if (existingResult is AppFailure<List<CommercialPack>>) {
      return AppFailure<CommercialPack>(existingResult.failure);
    }
    final existingPacks = (existingResult as AppSuccess<List<CommercialPack>>)
        .value
        .where((pack) => pack.id != current.id)
        .toList(growable: false);
    final componentsOfPack = _componentsOfPackResolver(existingPacks);

    final validation = _validator(
      pack: revised,
      now: now,
      isComponentReferenceValid: isComponentReferenceValid,
      componentsOfPack: (packId) =>
          packId == revised.id ? revised.components : componentsOfPack(packId),
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

    final createResult = await _repository.create(pack: revised);
    if (createResult is AppFailure<CommercialPack>) return createResult;

    final supersededCurrent = current.copyWith(
      status: CommercialPackStatus.superseded,
      supersededByPackId: revised.id,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      syncStatus: CommercialPackSyncStatus.pending,
    );
    final supersedeResult = await _repository.update(pack: supersededCurrent);
    if (supersedeResult is AppFailure<CommercialPack>) {
      return AppFailure<CommercialPack>(supersedeResult.failure);
    }

    return createResult;
  }
}

/// Builds a `packId -> its current components` lookup out of [packs] — same
/// shape `CreateCommercialPackUseCase`/`UpdateCommercialPackUseCase` build
/// for `ValidateCommercialPackCompositionUseCase`'s circularity check.
PackComponentsOfPackResolver _componentsOfPackResolver(
  List<CommercialPack> packs,
) {
  final componentsByPackId = <String, List<PackComponent>>{
    for (final pack in packs) pack.id: pack.components,
  };
  return (packId) => componentsByPackId[packId] ?? const <PackComponent>[];
}

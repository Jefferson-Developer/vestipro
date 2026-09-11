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

/// Creates a new `CommercialPack` (TASK-207, EPIC-32).
///
/// Mirrors `CreatePriceListUseCase`: every `CommercialPack` is born
/// [CommercialPackStatus.draft], `version` 1 — this use case never accepts
/// a status parameter, so a pack can never be created already
/// [CommercialPackStatus.active]. Publishing a draft (or editing one) is
/// `UpdateCommercialPackUseCase`'s job; revising an already-[active] pack
/// into a new version is `ReviseCommercialPackUseCase`'s.
///
/// Only ever grantable to whoever holds `Capability.commercialPackManage`
/// (OWNER/ADMIN/SALES_MANAGER) — a `SALES_REP` never calls this directly,
/// same RBAC boundary `firestore.rules`/`RolePermissionMatrix` enforce
/// independently server-side.
@injectable
final class CreateCommercialPackUseCase {
  const CreateCommercialPackUseCase(this._repository, this._validator);

  final CommercialPackRepository _repository;
  final ValidateCommercialPackCompositionUseCase _validator;

  Future<AppResult<CommercialPack>> call({
    required String id,
    required String organizationId,
    String? companyId,
    String? packCode,
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
    required String createdBy,
    PackComponentReferenceResolver? isComponentReferenceValid,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId?.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) {
      fieldErrors['id'] = 'Id is required.';
    }
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Name is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (validTo != null && !validTo.toUtc().isAfter(validFrom.toUtc())) {
      fieldErrors['validTo'] = 'ValidTo must be after validFrom.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<CommercialPack>(
        ValidationFailure(
          'Invalid commercial pack creation payload.',
          code: 'invalid_commercial_pack_create_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final candidate = CommercialPack(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: (trimmedCompanyId == null || trimmedCompanyId.isEmpty)
          ? null
          : trimmedCompanyId,
      packCode: (packCode == null || packCode.trim().isEmpty)
          ? trimmedId
          : packCode.trim(),
      version: 1,
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
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      syncStatus: CommercialPackSyncStatus.pending,
    );

    final existingResult = await _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
    );
    if (existingResult is AppFailure<List<CommercialPack>>) {
      return AppFailure<CommercialPack>(existingResult.failure);
    }
    final existingPacks =
        (existingResult as AppSuccess<List<CommercialPack>>).value;

    final validation = _validator(
      pack: candidate,
      now: now,
      isComponentReferenceValid: isComponentReferenceValid,
      componentsOfPack: _componentsOfPackResolver(existingPacks),
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

    return _repository.create(pack: candidate);
  }
}

/// Builds a `packId -> its current components` lookup out of [packs] —
/// shared shape every use case in this feature passes to
/// `ValidateCommercialPackCompositionUseCase`'s circularity check.
PackComponentsOfPackResolver _componentsOfPackResolver(
  List<CommercialPack> packs,
) {
  final componentsByPackId = <String, List<PackComponent>>{
    for (final pack in packs) pack.id: pack.components,
  };
  return (packId) => componentsByPackId[packId] ?? const <PackComponent>[];
}

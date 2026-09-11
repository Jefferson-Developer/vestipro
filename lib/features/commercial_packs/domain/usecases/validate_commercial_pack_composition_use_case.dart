import 'package:injectable/injectable.dart';

import '../entities/commercial_pack.dart';
import '../entities/pack_component.dart';
import '../value_objects/assortment_rule_type.dart';
import '../value_objects/commercial_pack_pricing_policy_type.dart';
import '../value_objects/commercial_pack_stock_policy_type.dart';
import '../value_objects/pack_component_composition_type.dart';
import '../value_objects/pack_component_scope_type.dart';

/// Outcome of [ValidateCommercialPackCompositionUseCase] — never throws,
/// same "field errors map" shape every creation/update use case in this
/// codebase already returns via `ValidationFailure.fieldErrors`, so callers
/// can surface every problem found at once instead of only the first one.
final class CommercialPackCompositionValidationResult {
  const CommercialPackCompositionValidationResult({
    required this.isValid,
    required this.fieldErrors,
  });

  final bool isValid;
  final Map<String, String> fieldErrors;
}

/// Resolves whether [component]'s [PackComponent.scopeReferenceId] is
/// currently alive/valid for commercial use — e.g. an active
/// `ProductVariant`, a non-deleted `Product`, or a `Collection` that
/// belongs to the same organization (TASK-207 business rule: "pacote não
/// pode referenciar variante inativa, produto excluído ou coleção fora do
/// escopo da organização").
///
/// This is a **contract only**: [ValidateCommercialPackCompositionUseCase]
/// never implements the actual catalog lookup itself — resolving a
/// [PackComponentScopeType] reference all the way down to sellable
/// `ProductVariant`s (and checking each one's liveness/tenant) is TASK-208
/// scope. A caller that already has access to the relevant catalog
/// repositories supplies this as a closure; omitting it (`null`) simply
/// skips this particular check, exactly as TASK-207 asks.
typedef PackComponentReferenceResolver = bool Function(PackComponent component);

/// Resolves every current [PackComponent] of the `CommercialPack` [packId]
/// — the hook [ValidateCommercialPackCompositionUseCase] walks to detect a
/// circular composition (TASK-207 business rule: "não permitir composição
/// circular"), without depending on a concrete repository itself. A caller
/// that already has the full set of packs for the organization loaded
/// (e.g. via `CommercialPackRepository.listByOrganization`) supplies this as
/// a simple map lookup; omitting it (`null`) simply skips the circularity
/// check.
typedef PackComponentsOfPackResolver =
    List<PackComponent> Function(String packId);

/// Validates the internal composition of a `CommercialPack` (TASK-207,
/// EPIC-32): a pure domain function, deliberately independent from any
/// repository, that never calculates a price nor reserves stock —
/// `CreateCommercialPackUseCase`/`UpdateCommercialPackUseCase`/
/// `ReviseCommercialPackUseCase` all call this before ever persisting a
/// pack.
@injectable
final class ValidateCommercialPackCompositionUseCase {
  const ValidateCommercialPackCompositionUseCase();

  CommercialPackCompositionValidationResult call({
    required CommercialPack pack,
    required DateTime now,
    PackComponentReferenceResolver? isComponentReferenceValid,
    PackComponentsOfPackResolver? componentsOfPack,
  }) {
    final fieldErrors = <String, String>{};

    if (pack.components.isEmpty) {
      fieldErrors['components'] =
          'A commercial pack must have at least one component.';
    }

    for (var index = 0; index < pack.components.length; index++) {
      final component = pack.components[index];
      final prefix = 'components[$index]';

      if (component.scopeReferenceId.trim().isEmpty) {
        fieldErrors['$prefix.scopeReferenceId'] =
            'Component reference must not be empty.';
      } else if (isComponentReferenceValid != null &&
          !isComponentReferenceValid(component)) {
        fieldErrors['$prefix.scopeReferenceId'] =
            'Component reference is not a currently valid, in-tenant target '
            '(e.g. an inactive variant, a deleted product or a collection '
            'outside the organization).';
      }

      switch (component.compositionType) {
        case PackComponentCompositionType.fixed:
          if (component.quantity == null || component.quantity! <= 0) {
            fieldErrors['$prefix.quantity'] =
                'Fixed component quantity must be greater than zero.';
          }
        case PackComponentCompositionType.flexible:
          final minQuantity = component.minQuantity;
          final maxQuantity = component.maxQuantity;
          if (minQuantity == null || minQuantity <= 0) {
            fieldErrors['$prefix.minQuantity'] =
                'Flexible component minQuantity must be greater than zero.';
          }
          if (maxQuantity == null || maxQuantity <= 0) {
            fieldErrors['$prefix.maxQuantity'] =
                'Flexible component maxQuantity must be greater than zero.';
          }
          if (minQuantity != null &&
              maxQuantity != null &&
              minQuantity > maxQuantity) {
            fieldErrors['$prefix.maxQuantity'] =
                'maxQuantity must be greater than or equal to minQuantity.';
          }
        case PackComponentCompositionType.gridProportion:
          final proportion = component.proportion;
          if (proportion == null || proportion <= 0 || proportion > 1) {
            fieldErrors['$prefix.proportion'] =
                'Grid proportion must be greater than zero and at most 1.';
          }
      }
    }

    for (var index = 0; index < pack.assortmentRules.length; index++) {
      final rule = pack.assortmentRules[index];
      final prefix = 'assortmentRules[$index]';

      switch (rule.type) {
        case AssortmentRuleType.minPercentagePerColor:
          if (rule.colorId == null || rule.colorId!.trim().isEmpty) {
            fieldErrors['$prefix.colorId'] =
                'colorId is required for minPercentagePerColor.';
          }
          final minPercentage = rule.minPercentage;
          if (minPercentage == null ||
              minPercentage <= 0 ||
              minPercentage > 1) {
            fieldErrors['$prefix.minPercentage'] =
                'minPercentage must be greater than zero and at most 1.';
          }
        case AssortmentRuleType.minQuantityPerSize:
          if (rule.sizeId == null || rule.sizeId!.trim().isEmpty) {
            fieldErrors['$prefix.sizeId'] =
                'sizeId is required for minQuantityPerSize.';
          }
          if (rule.minQuantity == null || rule.minQuantity! <= 0) {
            fieldErrors['$prefix.minQuantity'] =
                'minQuantity must be greater than zero.';
          }
        case AssortmentRuleType.minDistinctColors:
        case AssortmentRuleType.minDistinctSizes:
          if (rule.minQuantity == null || rule.minQuantity! <= 0) {
            fieldErrors['$prefix.minQuantity'] =
                'minQuantity must be greater than zero.';
          }
      }
    }

    switch (pack.pricingPolicyType) {
      case CommercialPackPricingPolicyType.componentSum:
        break;
      case CommercialPackPricingPolicyType.fixedPrice:
        if (pack.fixedPrice == null || pack.fixedPrice! <= 0) {
          fieldErrors['fixedPrice'] =
              'fixedPrice is required for the fixedPrice pricing policy.';
        }
      case CommercialPackPricingPolicyType.packDiscount:
        final discountPercentage = pack.discountPercentage;
        if (discountPercentage == null ||
            discountPercentage <= 0 ||
            discountPercentage > 1) {
          fieldErrors['discountPercentage'] =
              'discountPercentage must be greater than zero and at most 1 '
              'for the packDiscount pricing policy.';
        }
      case CommercialPackPricingPolicyType.bonusItem:
        final bonusComponentId = pack.bonusComponentId;
        if (bonusComponentId == null || bonusComponentId.trim().isEmpty) {
          fieldErrors['bonusComponentId'] =
              'bonusComponentId is required for the bonusItem pricing '
              'policy.';
        } else if (!pack.components.any(
          (component) => component.id == bonusComponentId,
        )) {
          fieldErrors['bonusComponentId'] =
              'bonusComponentId must reference one of this pack\'s own '
              'components.';
        }
    }

    if (pack.stockPolicyType == CommercialPackStockPolicyType.dedicatedStock &&
        (pack.dedicatedWarehouseId == null ||
            pack.dedicatedWarehouseId!.trim().isEmpty)) {
      fieldErrors['dedicatedWarehouseId'] =
          'dedicatedWarehouseId is required for the dedicatedStock stock '
          'policy.';
    }

    if (pack.validTo != null && pack.validTo!.toUtc().isBefore(now.toUtc())) {
      fieldErrors['validTo'] = 'Pack validity has already expired.';
    }

    if (componentsOfPack != null) {
      final circularPackId = _findCircularReference(
        pack: pack,
        componentsOfPack: componentsOfPack,
      );
      if (circularPackId != null) {
        fieldErrors['components'] =
            'Circular pack composition detected: pack "$circularPackId" '
            'directly or indirectly contains itself.';
      }
    }

    return CommercialPackCompositionValidationResult(
      isValid: fieldErrors.isEmpty,
      fieldErrors: fieldErrors,
    );
  }

  /// Walks the composition graph starting from [pack], following only
  /// [PackComponentScopeType.commercialPack] components, looking for a path
  /// back to [pack.id] — a pack can never (directly or transitively)
  /// contain itself. [componentsOfPack] is a caller-supplied resolver so
  /// this stays a pure domain function.
  ///
  /// Returns [pack.id] when a cycle through it is found, `null` otherwise.
  /// `visited` guards against re-walking an already-visited pack id, so an
  /// unrelated diamond-shaped (but acyclic) composition never causes
  /// exponential re-work or an infinite loop.
  String? _findCircularReference({
    required CommercialPack pack,
    required PackComponentsOfPackResolver componentsOfPack,
  }) {
    final visited = <String>{pack.id};

    bool leadsBackToRoot(List<PackComponent> components) {
      for (final component in components) {
        if (component.scopeType != PackComponentScopeType.commercialPack) {
          continue;
        }
        final referencedPackId = component.scopeReferenceId;
        if (referencedPackId == pack.id) return true;
        if (!visited.add(referencedPackId)) continue;
        if (leadsBackToRoot(componentsOfPack(referencedPackId))) return true;
      }
      return false;
    }

    return leadsBackToRoot(pack.components) ? pack.id : null;
  }
}

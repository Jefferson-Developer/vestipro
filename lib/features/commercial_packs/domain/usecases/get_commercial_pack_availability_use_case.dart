import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/variant_inventory_availability.dart';
import '../../../inventory/domain/repositories/variant_stock_balance_repository.dart';
import '../entities/commercial_pack.dart';
import '../entities/commercial_pack_availability.dart';
import '../entities/resolved_pack_line.dart';
import '../services/commercial_pack_composer.dart';
import '../services/pack_component_variant_resolver.dart';
import '../value_objects/commercial_pack_stock_policy_type.dart';
import '../value_objects/pack_component_scope_type.dart';

/// Estimates how many instances of [CommercialPack] are currently
/// fulfillable, given its [CommercialPack.stockPolicyType] (TASK-207,
/// TASK-208, EPIC-32/EPIC-12) — a client-side, non-authoritative signal
/// (`CommercialPackAvailability`'s own docs): it lets the seller/UI explain
/// why a pack looks unavailable *before* attempting to add it, but the real
/// stock check/decrement only ever happens server-side at `submitOrder`.
///
/// [PackComponentScopeType.commercialPack] (nested pack) components are
/// deliberately excluded from this estimate — recursively resolving a nested
/// pack's own availability is `ExpandCommercialPackToOrderItemsUseCase`'s
/// concern (`lib/features/orders`) when actually placing the order, not this
/// lightweight pre-check. A pack composed *only* of nested components always
/// reports [CommercialPackAvailability.availableInstances] as `0`
/// (`unknownAvailabilityForNestedOnlyPack`) rather than guessing.
@injectable
final class GetCommercialPackAvailabilityUseCase {
  const GetCommercialPackAvailabilityUseCase(
    this._resolver,
    this._variantStockBalanceRepository,
  );

  final PackComponentVariantResolver _resolver;
  final VariantStockBalanceRepository _variantStockBalanceRepository;

  Future<AppResult<CommercialPackAvailability>> call({
    required CommercialPack pack,
    int? totalGridQuantity,
  }) async {
    if (pack.stockPolicyType == CommercialPackStockPolicyType.dedicatedStock) {
      return _dedicatedStockAvailability(pack);
    }
    return _componentBalancesAvailability(
      pack,
      totalGridQuantity: totalGridQuantity,
    );
  }

  Future<AppResult<CommercialPackAvailability>> _dedicatedStockAvailability(
    CommercialPack pack,
  ) async {
    final result = await _variantStockBalanceRepository.getAvailability(
      organizationId: pack.organizationId,
      // The pre-assembled pack's own balance is tracked under its own id, a
      // deliberate reuse of the same `variantId`-keyed store `ProductVariant`
      // balances already use — a `CommercialPack` never becomes a real
      // `ProductVariant`, but the balance record shape is identical (a
      // physical unit count in one warehouse).
      variantId: pack.id,
      warehouseId: pack.dedicatedWarehouseId,
    );
    return switch (result) {
      AppSuccess<VariantInventoryAvailability>(value: final availability) =>
        AppSuccess<CommercialPackAvailability>(
          CommercialPackAvailability(
            packId: pack.id,
            availableInstances: availability.totalSellableQuantity < 0
                ? 0
                : availability.totalSellableQuantity,
          ),
        ),
      AppFailure<VariantInventoryAvailability>(failure: final failure) =>
        failure is NotFoundFailure
            ? AppSuccess<CommercialPackAvailability>(
                CommercialPackAvailability(
                  packId: pack.id,
                  availableInstances: 0,
                ),
              )
            : AppFailure<CommercialPackAvailability>(failure),
    };
  }

  Future<AppResult<CommercialPackAvailability>> _componentBalancesAvailability(
    CommercialPack pack, {
    int? totalGridQuantity,
  }) async {
    final normalComponents = pack.components
        .where(
          (component) =>
              component.scopeType != PackComponentScopeType.commercialPack,
        )
        .toList(growable: false);
    if (normalComponents.isEmpty) {
      return AppSuccess<CommercialPackAvailability>(
        CommercialPackAvailability(packId: pack.id, availableInstances: 0),
      );
    }

    final resolvedVariantsByComponent =
        <String, List<ResolvedComponentVariant>>{};
    for (final component in normalComponents) {
      final resolved = await _resolver.resolveSellableVariants(
        organizationId: pack.organizationId,
        companyId: pack.companyId,
        scopeType: component.scopeType,
        scopeReferenceId: component.scopeReferenceId,
      );
      if (resolved case AppFailure<List<ResolvedComponentVariant>>(
        failure: final failure,
      )) {
        return AppFailure<CommercialPackAvailability>(failure);
      }
      resolvedVariantsByComponent[component.id] =
          (resolved as AppSuccess<List<ResolvedComponentVariant>>).value;
    }

    final composed = CommercialPackComposer.compose(
      components: normalComponents,
      resolvedVariantsByComponent: resolvedVariantsByComponent,
      totalGridQuantity: totalGridQuantity,
    );
    if (composed case AppFailure<List<ResolvedPackLine>>(
      failure: final failure,
    )) {
      return AppFailure<CommercialPackAvailability>(failure);
    }
    final lines = (composed as AppSuccess<List<ResolvedPackLine>>).value;

    // Same variant can appear from more than one component (e.g. a "brinde"
    // component and a normal component both resolving to the same SKU) —
    // required quantities per instance are summed so availability is never
    // double-counted against the same physical stock twice.
    final requiredQuantityByVariant = <String, int>{};
    final componentIdByVariant = <String, String>{};
    for (final line in lines) {
      requiredQuantityByVariant.update(
        line.variantId,
        (value) => value + line.quantity,
        ifAbsent: () => line.quantity,
      );
      componentIdByVariant[line.variantId] = line.componentId;
    }

    final shortfallCandidates = <CommercialPackComponentShortfall>[];
    var availableInstances = 1 << 30; // effectively "unbounded" seed value.
    for (final entry in requiredQuantityByVariant.entries) {
      final variantId = entry.key;
      final requiredQuantity = entry.value;
      final availabilityResult = await _variantStockBalanceRepository
          .getAvailability(
            organizationId: pack.organizationId,
            variantId: variantId,
          );
      final sellableQuantity = switch (availabilityResult) {
        AppSuccess<VariantInventoryAvailability>(value: final availability) =>
          availability.totalSellableQuantity,
        AppFailure<VariantInventoryAvailability>(failure: final failure) =>
          failure is NotFoundFailure ? 0 : null,
      };
      if (sellableQuantity == null) {
        return AppFailure<CommercialPackAvailability>(
          (availabilityResult as AppFailure<VariantInventoryAvailability>)
              .failure,
        );
      }

      final shortfall = CommercialPackComponentShortfall(
        componentId: componentIdByVariant[variantId]!,
        variantId: variantId,
        requiredQuantityPerInstance: requiredQuantity,
        availableQuantity: sellableQuantity < 0 ? 0 : sellableQuantity,
      );
      shortfallCandidates.add(shortfall);
      if (shortfall.fulfillableInstances < availableInstances) {
        availableInstances = shortfall.fulfillableInstances;
      }
    }

    final bottlenecks = shortfallCandidates
        .where(
          (shortfall) => shortfall.fulfillableInstances == availableInstances,
        )
        .toList(growable: false);

    return AppSuccess<CommercialPackAvailability>(
      CommercialPackAvailability(
        packId: pack.id,
        availableInstances: availableInstances < 0 ? 0 : availableInstances,
        shortfalls: bottlenecks,
      ),
    );
  }
}

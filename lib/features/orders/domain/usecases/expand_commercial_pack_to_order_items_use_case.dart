import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../commercial_packs/domain/entities/commercial_pack.dart';
import '../../../commercial_packs/domain/entities/pack_component.dart';
import '../../../commercial_packs/domain/entities/resolved_pack_line.dart';
import '../../../commercial_packs/domain/repositories/commercial_pack_repository.dart';
import '../../../commercial_packs/domain/services/commercial_pack_composer.dart';
import '../../../commercial_packs/domain/services/pack_component_variant_resolver.dart';
import '../../../commercial_packs/domain/value_objects/pack_component_composition_type.dart';
import '../../../commercial_packs/domain/value_objects/pack_component_scope_type.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../pricing/domain/usecases/resolve_price_for_variant_use_case.dart';
import '../entities/order_item.dart';

/// Turns one `CommercialPack` (TASK-207) into the exact `OrderItem`s an
/// order draft needs to represent it (TASK-208, EPIC-32) — "ao adicionar um
/// pacote, expandir a composição para `OrderItem`s vinculados por
/// `packGroupId`, preservando o nome/versão do pacote no snapshot do
/// pedido" (`tasks.md`).
///
/// Every price captured here (`ResolvePriceForVariantUseCase`, the same
/// client-side estimate `OrderDraftBloc`/`OrderProductAdditionPage` already
/// use for plain catalog items) is deliberately a **local, non-authoritative
/// estimate**: this use case never applies `CommercialPack.pricingPolicyType`
/// (`fixedPrice`/`packDiscount`/`bonusItem`) itself — the server-side pricing
/// engine (`calculatePricing`/`submitOrder`, `functions/src/pricing/`)
/// always recomputes the definitive total once `OrderItem.packId`/
/// [OrderItem.packGroupId] are sent, per this task's own "a UI nunca calcula
/// preço final do pacote como fonte de verdade" rule. Similarly, real stock
/// availability is `GetCommercialPackAvailabilityUseCase`'s job (a
/// pre-check), never this use case's — expansion only ever fails when the
/// composition itself cannot be resolved (e.g. a component with zero
/// currently sellable variants), never on a stock shortfall.
@injectable
final class ExpandCommercialPackToOrderItemsUseCase {
  const ExpandCommercialPackToOrderItemsUseCase(
    this._resolver,
    this._packRepository,
    this._resolvePriceForVariant,
    this._uuid,
  );

  final PackComponentVariantResolver _resolver;
  final CommercialPackRepository _packRepository;
  final ResolvePriceForVariantUseCase _resolvePriceForVariant;
  final Uuid _uuid;

  /// How many nested `commercialPack` components may be walked before this
  /// use case gives up and reports a `ValidationFailure` — a defense-in-depth
  /// backstop alongside the circularity check already enforced at
  /// create/revise time (TASK-207's `ValidateCommercialPackCompositionUseCase`):
  /// that check only ever runs against packs already persisted through this
  /// codebase's own use cases, so this guard is what protects expansion
  /// itself against any pack document that reached Firestore some other way.
  static const int _maxNestingDepth = 5;

  Future<AppResult<List<OrderItem>>> call({
    required CommercialPack pack,
    required String organizationId,
    required String companyId,
    String? customerChannel,
    String? customerSegment,
    Map<String, int>? quantityOverridesByComponent,
    int? totalGridQuantity,
    DateTime? now,
  }) {
    return _expand(
      pack: pack,
      organizationId: organizationId,
      companyId: companyId,
      customerChannel: customerChannel,
      customerSegment: customerSegment,
      quantityOverridesByComponent: quantityOverridesByComponent,
      totalGridQuantity: totalGridQuantity,
      now: now ?? DateTime.now(),
      packGroupId: _uuid.v4(),
      instanceMultiplier: 1,
      visitedPackIds: <String>{},
      depth: 0,
    );
  }

  Future<AppResult<List<OrderItem>>> _expand({
    required CommercialPack pack,
    required String organizationId,
    required String companyId,
    String? customerChannel,
    String? customerSegment,
    Map<String, int>? quantityOverridesByComponent,
    int? totalGridQuantity,
    required DateTime now,
    required String packGroupId,
    required int instanceMultiplier,
    required Set<String> visitedPackIds,
    required int depth,
  }) async {
    if (depth > _maxNestingDepth) {
      return AppFailure<List<OrderItem>>(
        ValidationFailure(
          'This pack nests too many levels deep to expand safely.',
          code: 'commercial_pack_expansion_max_depth_exceeded',
        ),
      );
    }
    if (visitedPackIds.contains(pack.id)) {
      return AppFailure<List<OrderItem>>(
        ValidationFailure(
          'Circular pack composition detected while expanding "${pack.id}".',
          code: 'commercial_pack_expansion_circular_composition',
        ),
      );
    }
    if (!pack.isApplicableAt(now)) {
      return AppFailure<List<OrderItem>>(
        ValidationFailure(
          'This pack is no longer sellable (expired, inactive or a stale '
          'version) — refresh it before adding it to the order.',
          code: 'commercial_pack_not_sellable',
          fieldErrors: <String, String>{'pack': pack.id},
        ),
      );
    }

    final nextVisited = <String>{...visitedPackIds, pack.id};
    final normalComponents = <PackComponent>[];
    final nestedComponents = <PackComponent>[];
    for (final component in pack.components) {
      if (component.scopeType == PackComponentScopeType.commercialPack) {
        nestedComponents.add(component);
      } else {
        normalComponents.add(component);
      }
    }

    final items = <OrderItem>[];

    if (normalComponents.isNotEmpty) {
      final resolvedVariantsByComponent =
          <String, List<ResolvedComponentVariant>>{};
      for (final component in normalComponents) {
        final resolved = await _resolver.resolveSellableVariants(
          organizationId: organizationId,
          companyId: companyId,
          scopeType: component.scopeType,
          scopeReferenceId: component.scopeReferenceId,
        );
        if (resolved case AppFailure<List<ResolvedComponentVariant>>(
          failure: final failure,
        )) {
          return AppFailure<List<OrderItem>>(failure);
        }
        resolvedVariantsByComponent[component.id] =
            (resolved as AppSuccess<List<ResolvedComponentVariant>>).value;
      }

      final composed = CommercialPackComposer.compose(
        components: normalComponents,
        resolvedVariantsByComponent: resolvedVariantsByComponent,
        quantityOverridesByComponent: quantityOverridesByComponent,
        totalGridQuantity: totalGridQuantity,
      );
      if (composed case AppFailure<List<ResolvedPackLine>>(
        failure: final failure,
      )) {
        return AppFailure<List<OrderItem>>(failure);
      }
      final lines = (composed as AppSuccess<List<ResolvedPackLine>>).value;

      for (final line in lines) {
        final priceResult = await _resolvePriceForVariant(
          organizationId: organizationId,
          companyId: companyId,
          productId: line.productId,
          variantId: line.variantId,
          customerChannel: customerChannel,
          customerSegment: customerSegment,
        );
        if (priceResult case AppFailure<ResolvedVariantPrice>(
          failure: final failure,
        )) {
          return AppFailure<List<OrderItem>>(failure);
        }
        final resolvedPrice =
            (priceResult as AppSuccess<ResolvedVariantPrice>).value;
        if (!resolvedPrice.hasPrice) {
          return AppFailure<List<OrderItem>>(
            ValidationFailure(
              'No price available for one of this pack\'s components.',
              code: 'commercial_pack_component_price_unavailable',
              fieldErrors: <String, String>{
                'components[${line.componentId}]': line.variantId,
              },
            ),
          );
        }
        final quantity = line.quantity * instanceMultiplier;
        final unitPrice = resolvedPrice.price!;
        items.add(
          OrderItem(
            id: _uuid.v4(),
            variantId: line.variantId,
            productId: line.productId,
            quantity: quantity,
            unitPrice: unitPrice,
            subtotal: quantity * unitPrice,
            packId: pack.id,
            packCode: pack.packCode,
            packVersion: pack.version,
            packGroupId: packGroupId,
            packName: pack.name,
          ),
        );
      }
    }

    for (final component in nestedComponents) {
      final nestedMultiplierResult = _resolveNestedMultiplier(
        component,
        quantityOverridesByComponent: quantityOverridesByComponent,
        totalGridQuantity: totalGridQuantity,
      );
      if (nestedMultiplierResult case AppFailure<int>(failure: final failure)) {
        return AppFailure<List<OrderItem>>(failure);
      }
      final nestedMultiplier =
          (nestedMultiplierResult as AppSuccess<int>).value;

      final nestedPackResult = await _packRepository.getById(
        organizationId: organizationId,
        id: component.scopeReferenceId,
      );
      if (nestedPackResult case AppFailure<CommercialPack?>(
        failure: final failure,
      )) {
        return AppFailure<List<OrderItem>>(failure);
      }
      final nestedPack =
          (nestedPackResult as AppSuccess<CommercialPack?>).value;
      if (nestedPack == null) {
        return AppFailure<List<OrderItem>>(
          ValidationFailure(
            'Nested pack "${component.scopeReferenceId}" no longer exists.',
            code: 'commercial_pack_nested_not_found',
          ),
        );
      }

      final nestedResult = await _expand(
        pack: nestedPack,
        organizationId: organizationId,
        companyId: companyId,
        customerChannel: customerChannel,
        customerSegment: customerSegment,
        // Overrides/totalGridQuantity are keyed by *this level's* component
        // ids — a nested pack's own flexible/gridProportion components (if
        // any) are always resolved at their own default (minQuantity) rather
        // than reusing the outer request's map, since the ids live in
        // different namespaces.
        now: now,
        packGroupId: packGroupId,
        instanceMultiplier: instanceMultiplier * nestedMultiplier,
        visitedPackIds: nextVisited,
        depth: depth + 1,
      );
      if (nestedResult case AppFailure<List<OrderItem>>(
        failure: final failure,
      )) {
        return AppFailure<List<OrderItem>>(failure);
      }
      items.addAll((nestedResult as AppSuccess<List<OrderItem>>).value);
    }

    if (items.isEmpty) {
      return AppFailure<List<OrderItem>>(
        const ValidationFailure(
          'This pack has no component that could be resolved to a '
          'sellable item.',
          code: 'commercial_pack_expansion_empty',
        ),
      );
    }

    return AppSuccess<List<OrderItem>>(List<OrderItem>.unmodifiable(items));
  }

  AppResult<int> _resolveNestedMultiplier(
    PackComponent component, {
    Map<String, int>? quantityOverridesByComponent,
    int? totalGridQuantity,
  }) {
    switch (component.compositionType) {
      case PackComponentCompositionType.fixed:
        final quantity = component.quantity ?? 0;
        if (quantity <= 0) {
          return AppFailure<int>(
            ValidationFailure(
              'Nested pack component "${component.id}" has no valid '
              'quantity.',
              code: 'commercial_pack_nested_component_invalid_quantity',
            ),
          );
        }
        return AppSuccess<int>(quantity);
      case PackComponentCompositionType.flexible:
        final minQuantity = component.minQuantity ?? 0;
        final maxQuantity = component.maxQuantity ?? 0;
        final requested =
            quantityOverridesByComponent?[component.id] ?? minQuantity;
        if (minQuantity <= 0 ||
            maxQuantity <= 0 ||
            minQuantity > maxQuantity ||
            requested < minQuantity ||
            requested > maxQuantity) {
          return AppFailure<int>(
            ValidationFailure(
              'Nested pack component "${component.id}" quantity must stay '
              'between $minQuantity and $maxQuantity.',
              code: 'commercial_pack_nested_component_invalid_quantity',
            ),
          );
        }
        return AppSuccess<int>(requested);
      case PackComponentCompositionType.gridProportion:
        final proportion = component.proportion;
        if (proportion == null ||
            proportion <= 0 ||
            proportion > 1 ||
            totalGridQuantity == null ||
            totalGridQuantity <= 0) {
          return AppFailure<int>(
            ValidationFailure(
              'Nested pack component "${component.id}" needs a valid grid '
              'proportion and totalGridQuantity.',
              code: 'commercial_pack_nested_component_invalid_proportion',
            ),
          );
        }
        final absoluteQuantity = (proportion * totalGridQuantity).round();
        if (absoluteQuantity <= 0) {
          return AppFailure<int>(
            ValidationFailure(
              'Nested pack component "${component.id}" proportion rounds to '
              'zero units.',
              code: 'commercial_pack_nested_component_invalid_proportion',
            ),
          );
        }
        return AppSuccess<int>(absoluteQuantity);
    }
  }
}

import '../../../../core/utils/utils.dart';
import '../value_objects/pack_component_scope_type.dart';

/// One sellable `ProductVariant` a [PackComponentVariantResolver] resolved a
/// component's scope to — just enough to build a `ResolvedPackLine`/
/// `OrderItem` without a second product lookup.
typedef ResolvedComponentVariant = ({String variantId, String productId});

/// Resolves a `PackComponent.scopeType`/`scopeReferenceId` (TASK-207) down to
/// the concrete, currently sellable `ProductVariant`s it represents *right
/// now* (TASK-208, EPIC-32) — the piece `ValidateCommercialPackCompositionUseCase`
/// (TASK-207) and this pack's own order-time expansion both left as a
/// contract only.
///
/// [PackComponentScopeType.commercialPack] is deliberately never resolved
/// here: nesting one `CommercialPack` inside another needs the *nested
/// pack's own composition* (recursively expanded, its own quantities
/// multiplied by the outer component's), not a flat list of variant ids —
/// that recursion is `ExpandCommercialPackToOrderItemsUseCase`'s job
/// (`lib/features/orders`), the only caller allowed to depend on this
/// feature going the other way for order-building purposes.
abstract interface class PackComponentVariantResolver {
  /// Every currently sellable variant [scopeType]/[scopeReferenceId]
  /// represents, scoped to [organizationId] (and, when given, [companyId]).
  /// An empty (successful) list means the reference resolves to *nothing*
  /// sellable right now (e.g. every variant of that color is inactive) —
  /// callers must treat that as "this component cannot be fulfilled",
  /// never silently skip it.
  Future<AppResult<List<ResolvedComponentVariant>>> resolveSellableVariants({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  });

  /// Whether [scopeType]/[scopeReferenceId] still points at something alive
  /// and in-tenant right now — the exact check
  /// `ValidateCommercialPackCompositionUseCase.isComponentReferenceValid`
  /// (TASK-207) left as a contract. `commercialPack` scope is supported here
  /// (unlike [resolveSellableVariants]): it only needs an existence/liveness
  /// check, never the nested composition itself.
  Future<AppResult<bool>> isReferenceValid({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  });
}

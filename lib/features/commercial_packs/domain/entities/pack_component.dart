import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/pack_component_composition_type.dart';
import '../value_objects/pack_component_scope_type.dart';

part 'pack_component.freezed.dart';

/// A single item that composes a `CommercialPack` (TASK-207, EPIC-32).
///
/// [scopeType]/[scopeReferenceId] together identify *what* this component
/// is (a specific variant, a whole product, a color, a size, a category, a
/// collection, or another `CommercialPack` for nested kits) — always
/// resolvable to one or more sellable `ProductVariant`s before any
/// commercial calculation, though that resolution itself is TASK-208 scope,
/// never implemented here.
///
/// [compositionType] decides which of [quantity]/[minQuantity]/
/// [maxQuantity]/[proportion] actually apply — see
/// [PackComponentCompositionType] for the exact shape each one requires.
/// `ValidateCommercialPackCompositionUseCase` is the only place that
/// enforces those shapes; this entity itself stays a plain, unchecked data
/// holder, same precedent `OrderItem`/`PriceListItem` already follow.
///
/// [isBonusItem] flags this component as the one given away for free when
/// the owning `CommercialPack.pricingPolicyType` is
/// `CommercialPackPricingPolicyType.bonusItem` (matched against
/// `CommercialPack.bonusComponentId`) — never applies any price by itself.
@freezed
abstract class PackComponent with _$PackComponent {
  const factory PackComponent({
    required String id,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
    required PackComponentCompositionType compositionType,
    int? quantity,
    int? minQuantity,
    int? maxQuantity,
    double? proportion,
    @Default(false) bool isBonusItem,
  }) = _PackComponent;
}

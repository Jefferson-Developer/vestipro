import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/assortment_rule_type.dart';

part 'assortment_rule.freezed.dart';

/// An additional grade-composition constraint attached to a `CommercialPack`
/// (TASK-207, EPIC-32), beyond whatever its own `PackComponent`s already
/// require — e.g. "no mínimo 30% da cor azul" or "no mínimo 2 unidades por
/// tamanho".
///
/// Which of [colorId]/[sizeId]/[minPercentage]/[minQuantity] apply depends
/// on [type] — see [AssortmentRuleType] for the exact shape each one
/// requires. `ValidateCommercialPackCompositionUseCase` is the only place
/// that enforces those shapes; this entity itself stays a plain, unchecked
/// data holder, same precedent [PackComponent] already follows.
@freezed
abstract class AssortmentRule with _$AssortmentRule {
  const factory AssortmentRule({
    required String id,
    required AssortmentRuleType type,
    String? colorId,
    String? sizeId,
    double? minPercentage,
    int? minQuantity,
  }) = _AssortmentRule;
}

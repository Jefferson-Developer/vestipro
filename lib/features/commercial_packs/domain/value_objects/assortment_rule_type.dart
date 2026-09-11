/// Which grade-composition constraint an [AssortmentRule] expresses
/// (TASK-207, EPIC-32) — additional to whatever `PackComponent.quantity`/
/// `minQuantity`/`maxQuantity`/`proportion` already require, used to shape
/// an "ideal sortimento" beyond a plain component list (e.g. "no mínimo 30%
/// da cor azul" or "no mínimo 2 unidades por tamanho").
///
/// - [minPercentagePerColor]: at least `AssortmentRule.minPercentage` of the
///   pack's total quantity must be `AssortmentRule.colorId`.
/// - [minQuantityPerSize]: at least `AssortmentRule.minQuantity` units of
///   `AssortmentRule.sizeId` must be present.
/// - [minDistinctColors]: at least `AssortmentRule.minQuantity` distinct
///   colors must be represented across the pack's resolved components.
/// - [minDistinctSizes]: at least `AssortmentRule.minQuantity` distinct
///   sizes must be represented across the pack's resolved components.
enum AssortmentRuleType {
  minPercentagePerColor,
  minQuantityPerSize,
  minDistinctColors,
  minDistinctSizes,
}

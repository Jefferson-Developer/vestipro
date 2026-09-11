/// Which pricing strategy a [CommercialPack] declares for the pricing
/// engine (TASK-088, EPIC-11) to apply — a **contract only**: this enum and
/// the parameters it gates (`CommercialPack.fixedPrice`,
/// `CommercialPack.discountPercentage`, `CommercialPack.bonusComponentId`)
/// never compute a final sellable price by themselves anywhere in this
/// feature (TASK-207 business rule: "a modelagem não calcula preço final").
///
/// - [componentSum]: the pack's price is the sum of whatever the pricing
///   engine resolves for each component's own resolved variant(s) at order
///   time — no additional parameter needed on [CommercialPack] itself.
/// - [fixedPrice]: the whole pack sells for a single closed price
///   (`CommercialPack.fixedPrice`), regardless of what its components would
///   individually cost.
/// - [packDiscount]: the pack sells for the sum of its components' resolved
///   prices minus `CommercialPack.discountPercentage` (a fraction between 0
///   exclusive and 1 inclusive).
/// - [bonusItem]: every component sells at its own resolved price except
///   the one identified by `CommercialPack.bonusComponentId`
///   (`PackComponent.isBonusItem` on that same component), which is given
///   to the customer at no charge — the pricing engine decides how,
///   this contract only names which component is the bonus.
enum CommercialPackPricingPolicyType {
  componentSum,
  fixedPrice,
  packDiscount,
  bonusItem,
}

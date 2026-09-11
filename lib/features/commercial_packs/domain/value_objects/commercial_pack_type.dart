/// What kind of sellable grouping a [CommercialPack] represents (TASK-207,
/// EPIC-32).
///
/// - [kit]: a fixed, closed grouping of components sold and priced as a
///   single sellable unit (e.g. "kit 3 camisetas básicas").
/// - [pack]: a grouping meant to be resold as-is at the point of sale (e.g.
///   a pre-boxed multi-pack), closer to a single SKU than a composition of
///   independent products.
/// - [assortment]: a broader, often flexible/proportional grouping meant to
///   guide an ideal buy across a grade (cor/tamanho) or collection (e.g.
///   "sortimento ideal da coleção verão"), usually paired with one or more
///   [AssortmentRule]s.
///
/// This distinction is informational/commercial only — every
/// [CommercialPack], regardless of [CommercialPackType], follows the exact
/// same pricing/stock/versioning contract; nothing in this codebase branches
/// business rules on it.
enum CommercialPackType { kit, pack, assortment }

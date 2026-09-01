/// The commercial dimension a [Target] (meta comercial) is set against
/// (`tasks.md`, EPIC-15/VESTI-085): who or what the goal applies to.
///
/// [dimensionId] on the owning `Target` must be resolved against the entity
/// matching this type: [salesRep] → a user id, [team] → a `Team.id`,
/// [company] → a `Company.id`, [collection] → a `Collection.id`, [category] →
/// a `Category.id`.
enum TargetDimensionType { salesRep, team, company, collection, category }

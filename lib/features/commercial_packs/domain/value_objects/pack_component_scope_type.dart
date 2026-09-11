/// What kind of catalog entity a [PackComponent.scopeReferenceId] points at
/// (TASK-207, EPIC-32) — always resolvable to one or more sellable
/// `ProductVariant`s before any commercial calculation, though that
/// resolution itself is TASK-208 scope (`tasks.md`), not this one.
///
/// - [variant]: a single, specific `ProductVariant` id — the narrowest,
///   unambiguous reference.
/// - [product]: a whole `Product` id — every one of its currently sellable
///   variants is a candidate.
/// - [color]: a `ProductColor`/color id — every sellable variant of that
///   color, across whichever product(s) the resolver considers in scope.
/// - [size]: a size code/id (from a `SizeGridTemplate`) — every sellable
///   variant of that size.
/// - [category]: a `Category` id — every sellable variant of every product
///   in that category.
/// - [collection]: a `Collection` id — every sellable variant of every
///   product in that collection.
/// - [commercialPack]: another [CommercialPack] id, nesting one pack inside
///   another (e.g. a "combo" pack made of two smaller kits). This is the
///   only scope `ValidateCommercialPackCompositionUseCase`'s circularity
///   check ever walks — a component of any other [scopeType] can never be
///   part of a composition cycle by construction.
enum PackComponentScopeType {
  variant,
  product,
  color,
  size,
  category,
  collection,
  commercialPack,
}

/// One filterable dimension of `CatalogFilter` (TASK-082), identifying which
/// active filter chip an individual "x" (remove) tap refers to — a set-typed
/// dimension (e.g. [color]/[size]/[tag]) removes only the one value passed
/// alongside this key, never the whole dimension at once.
enum CatalogFilterKey {
  collection,
  season,
  brand,
  category,
  color,
  size,
  availability,
  launch,
  tag,
  material,
}

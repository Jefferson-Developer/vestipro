/// How many units of a [PackComponent] a single unit of its owning
/// [CommercialPack] requires (TASK-207, EPIC-32).
///
/// - [fixed]: exactly `PackComponent.quantity` units, every time — a closed
///   kit composition (e.g. "2 camisetas P + 1 bermuda P").
/// - [flexible]: any quantity between `PackComponent.minQuantity` and
///   `PackComponent.maxQuantity` (inclusive), left to whoever assembles the
///   order within that range — an open/negotiated composition.
/// - [gridProportion]: `PackComponent.proportion` (a fraction between 0
///   exclusive and 1 inclusive) of the pack's own total quantity, used for
///   grade-by-color/size assortments (e.g. "30% da cor azul") rather than a
///   fixed absolute count.
enum PackComponentCompositionType { fixed, flexible, gridProportion }

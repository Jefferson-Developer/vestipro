import 'target_dimension_type.dart';

/// The commercial dimension a positivação snapshot (TASK-117, EPIC-15/
/// VESTI-087) is computed for: "quantos clientes da carteira de um vendedor
/// (ou equipe, ou empresa) compraram no período".
///
/// Deliberately narrower than [TargetDimensionType]: positivação is a
/// property of a *customer portfolio* (vendedor/equipe/empresa), never of a
/// `collection`/`category` — a product collection has no "carteira de
/// clientes" to positivar.
enum PositivacaoDimensionType {
  salesRep,
  team,
  company;

  /// Maps to the equivalent [TargetDimensionType] so positivação can reuse
  /// `TargetVisibilityService`/`TargetVisibilityFilter` (TASK-116) for RBAC
  /// instead of duplicating that dimension-visibility logic.
  TargetDimensionType get asTargetDimensionType => switch (this) {
    PositivacaoDimensionType.salesRep => TargetDimensionType.salesRep,
    PositivacaoDimensionType.team => TargetDimensionType.team,
    PositivacaoDimensionType.company => TargetDimensionType.company,
  };
}

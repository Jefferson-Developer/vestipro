import 'target_dimension_type.dart';

/// The commercial dimension a ranking comercial (TASK-118, EPIC-15) compares
/// peers by: "vendedor individual vs. equipe", per the task's own scope.
///
/// Deliberately narrower than [TargetDimensionType]: a ranking only ever
/// makes sense between peers of the same kind competing for the same kind of
/// goal — comparing a `company`/`collection`/`category` target against its
/// peers has no natural "who is ahead of whom" reading the way vendedores or
/// equipes do, and the task's own scope only ever asks for these two.
enum RankingDimensionType {
  salesRep,
  team;

  /// Maps to the equivalent [TargetDimensionType] so ranking can reuse
  /// `TargetRepository`/`TargetVisibilityFilter` (TASK-116) instead of
  /// duplicating that dimension modeling — same technique
  /// `PositivacaoDimensionType.asTargetDimensionType` (TASK-117) already
  /// established.
  TargetDimensionType get asTargetDimensionType => switch (this) {
    RankingDimensionType.salesRep => TargetDimensionType.salesRep,
    RankingDimensionType.team => TargetDimensionType.team,
  };
}

/// The standard NPS categorization of a 0-10 score (TASK-202, EPIC-30) —
/// mirrors `npsCategoryOf` in `functions/src/nps/nps-shared.ts`, the single
/// definition every NPS computation in this codebase uses (`tasks.md`:
/// "fórmula única e documentada").
enum NpsScoreCategory { promoter, passive, detractor }

extension NpsScoreCategoryOf on int {
  /// `promoter` for 9-10, `passive` for 7-8, `detractor` for 0-6.
  NpsScoreCategory get npsCategory {
    if (this >= 9) return NpsScoreCategory.promoter;
    if (this >= 7) return NpsScoreCategory.passive;
    return NpsScoreCategory.detractor;
  }
}

/// Lifecycle status of a [Branch] (TASK-027).
///
/// Independent from `deletedAt` (soft delete): a [suspended] Branch is not
/// deleted, and a deleted Branch keeps whatever status it had right before
/// removal — [deletedAt] alone marks it as gone.
enum BranchStatus { active, suspended }

/// Lifecycle status of a [Company] (TASK-027).
///
/// Independent from `deletedAt` (soft delete): a [suspended] Company is not
/// deleted, and a deleted Company keeps whatever status it had right before
/// removal — [deletedAt] alone marks it as gone.
enum CompanyStatus { active, suspended }

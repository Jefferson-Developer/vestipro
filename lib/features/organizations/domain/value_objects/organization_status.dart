/// Lifecycle status of an [Organization] (TASK-026).
///
/// Independent from `deletedAt` (soft delete): a [suspended] organization is
/// not deleted, and a deleted organization keeps whatever status it had
/// right before removal — [deletedAt] alone marks it as gone.
enum OrganizationStatus { active, suspended }

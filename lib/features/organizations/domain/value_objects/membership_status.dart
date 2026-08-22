/// Whether a [Membership] (user-organization-role link) currently grants
/// access or has been deactivated (e.g. collaborator left, access revoked)
/// without deleting its history (`tasks.md`, seção 3.3).
///
/// Independent from `deletedAt` (soft delete): an [inactive] Membership is
/// not deleted, and a deleted Membership keeps whatever status it had right
/// before removal — [Membership.deletedAt] alone marks it as gone.
enum MembershipStatus { active, inactive }

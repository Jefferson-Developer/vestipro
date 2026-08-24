/// Lifecycle of a `Collection` (TASK-066).
///
/// Closing a Collection ([closed]) never deletes the Products associated
/// with it — it only stops the Collection from being offered as a target for
/// *new* Product associations and flags it as encerrada in catalog filters
/// (EPIC-10), mirroring how [ProductStatus.discontinued]/[deletedAt] never
/// erase a Product's own history.
enum CollectionStatus { active, closed }

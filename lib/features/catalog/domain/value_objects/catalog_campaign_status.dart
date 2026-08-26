/// The lifecycle status of a `CatalogCampaign` (TASK-080), always derived —
/// never stored as its own field — from `active`/`startAt`/`endAt`/
/// `deletedAt` at read time (`CatalogCampaign.statusAt`). Deriving it on
/// every read is what lets a campaign expire or start without depending on
/// a background job or the client forcing a refresh (TASK-080: "expiração
/// não depende de o cliente forçar um refresh manual").
enum CatalogCampaignStatus {
  /// Deactivated by an admin (`active == false`) or soft-deleted — never
  /// shown anywhere in the catalog, regardless of its date window.
  inactive,

  /// Active and within its date window right now (or has no window at all).
  active,

  /// Active, but `startAt` is still in the future.
  scheduled,

  /// Active, but `endAt` has already passed.
  expired,
}

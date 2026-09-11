/// Commercial lifecycle of a [CommercialPack] (TASK-207, EPIC-32).
///
/// - [draft]: still being configured, never sellable, always freely editable
///   directly (`UpdateCommercialPackUseCase`) — mirrors
///   `PriceListStatus.draft`.
/// - [active]: published and sellable. Once here, a [CommercialPack] can
///   never be edited directly again — any change must go through
///   `ReviseCommercialPackUseCase`, which creates a brand-new version
///   (new id, `CommercialPack.version` + 1, same `CommercialPack.packCode`)
///   and flips this exact version to [superseded], never mutating it in
///   place (TASK-207 business rule: "alteração em pacote ativo deve
///   versionar").
/// - [expired]: past its own `CommercialPack.validTo` — set explicitly (by
///   an administrator today, by a scheduled lifecycle job in the future),
///   same independence-from-date precedent `PriceListStatus.active` already
///   documents: `CommercialPack.isApplicableAt` always checks the validity
///   window independently, never this flag alone.
/// - [archived]: manually retired by an administrator/comercial user,
///   without ever having been revised into a newer version.
/// - [superseded]: this specific version was replaced by a newer one via
///   `ReviseCommercialPackUseCase` (`CommercialPack.supersededByPackId`
///   points at the version that replaced it). Deliberately distinct from
///   [archived] — a [superseded] pack was retired *because* something
///   newer took its place, never by direct administrative choice; an old
///   Order that still references this version keeps reading the exact same
///   composition/pricing/stock policy it had when the order was placed,
///   since this version's content is never rewritten, only this status
///   (and `supersededByPackId`) ever changes on it again.
enum CommercialPackStatus { draft, active, expired, archived, superseded }

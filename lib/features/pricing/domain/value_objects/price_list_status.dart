/// Commercial lifecycle of a Price List (EPIC-11, TASK-083).
///
/// [PriceListStatus] is set explicitly (by an administrator today, by a
/// scheduled lifecycle job in the future) and is deliberately independent
/// from whether the table is currently inside its own validity window
/// (`PriceList.validFrom`/`PriceList.validTo`): a table can still be flagged
/// [active] after its `validTo` has passed, until an operator (or that
/// future job) advances it to [expired]. Applicability resolution
/// (`ResolveApplicablePriceListsUseCase`) always checks both independently,
/// never [PriceListStatus.active] alone — see `PriceList.isApplicableAt`.
enum PriceListStatus { draft, active, expired, archived }

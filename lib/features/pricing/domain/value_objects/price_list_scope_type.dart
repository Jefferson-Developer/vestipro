/// Which dimension narrows a Price List's applicability beyond its own
/// `PriceList.companyId` (EPIC-11, TASK-083).
///
/// - [company]: applies to every customer of the company, with no further
///   narrowing — `PriceList.scopeValue` must be null.
/// - [channel]: applies only to customers whose `Customer.originChannel`
///   equals `PriceList.scopeValue`, which must be set.
/// - [segment]: applies only to customers whose `Customer.segment` equals
///   `PriceList.scopeValue`, which must be set.
enum PriceListScopeType { company, channel, segment }

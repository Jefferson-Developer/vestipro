/// Which stock strategy a [CommercialPack] declares for the order/inventory
/// flow (EPIC-12/EPIC-13) to apply — a **contract only**: this enum and the
/// parameter it gates (`CommercialPack.dedicatedWarehouseId`) never reserve
/// or debit real stock anywhere in this feature (TASK-207 business rule:
/// "a modelagem não... reserva estoque").
///
/// - [consumeComponentBalances]: selling one pack consumes the stock
///   balance of each resolved component variant directly (e.g.
///   `VariantStockBalance`, EPIC-12) — the pack itself never carries its
///   own stock.
/// - [dedicatedStock]: the pack was physically pre-assembled ahead of time
///   and carries its own separate stock balance, tracked in
///   `CommercialPack.dedicatedWarehouseId`, independent from its
///   components' own balances.
enum CommercialPackStockPolicyType { consumeComponentBalances, dedicatedStock }

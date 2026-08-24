/// Commercial lifecycle of a Product catalog entry.
///
/// `deletedAt` is independent from this status: a discontinued or inactive
/// product is still visible in historical orders/reports, while `deletedAt`
/// marks a soft deletion.
enum ProductStatus { draft, active, inactive, discontinued }

/// Commercial lifecycle of a Customer.
///
/// `deletedAt` is independent from this status: an inactive or blocked
/// customer is still visible/history-preserving, while `deletedAt` marks a
/// soft deletion.
enum CustomerStatus { active, inactive, prospect, blocked }

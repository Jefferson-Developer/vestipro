/// A time-limited exception to an otherwise-blocking `CustomerCreditProfile`
/// (TASK-212) — the only bypass `evaluateOrderCredit`/`submitOrder` ever
/// honor for a manual block/overdue/limite-excedido condition. Only ever set
/// by `grantCreditOverride` (`finance.manage`), never by the seller/customer
/// themselves.
final class CustomerCreditOverride {
  const CustomerCreditOverride({
    required this.active,
    this.reason,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.expiresAt,
  });

  final bool active;
  final String? reason;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  /// Mirrors the server's own `isOverrideActive` (`credit-shared.ts`) —
  /// [active] alone is not enough, an override with no [expiresAt] or one
  /// already in the past never bypasses anything.
  bool isValidAt(DateTime now) =>
      active && expiresAt != null && now.isBefore(expiresAt!);

  @override
  bool operator ==(Object other) =>
      other is CustomerCreditOverride &&
      other.active == active &&
      other.reason == reason &&
      other.approvedBy == approvedBy &&
      other.approvedByName == approvedByName &&
      other.approvedAt == approvedAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(
    active,
    reason,
    approvedBy,
    approvedByName,
    approvedAt,
    expiresAt,
  );
}

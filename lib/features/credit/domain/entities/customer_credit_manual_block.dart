/// A manual, finance-decided block on a `CustomerCreditProfile` (TASK-212) —
/// independent of the automatic overdue/limite rules, e.g. fraude suspeita
/// ou decisão administrativa. Set/cleared only via `updateCreditProfile`
/// (`finance.manage`).
final class CustomerCreditManualBlock {
  const CustomerCreditManualBlock({
    required this.active,
    this.reason,
    this.by,
    this.at,
  });

  final bool active;
  final String? reason;
  final String? by;
  final DateTime? at;

  @override
  bool operator ==(Object other) =>
      other is CustomerCreditManualBlock &&
      other.active == active &&
      other.reason == reason &&
      other.by == by &&
      other.at == at;

  @override
  int get hashCode => Object.hash(active, reason, by, at);
}

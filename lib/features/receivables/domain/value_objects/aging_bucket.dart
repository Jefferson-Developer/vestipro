/// Aging bucket for one título a receber's outstanding balance (TASK-213's
/// own "aging resumido") — computed client-side from [Receivable.dueDate]/
/// [Receivable.status] purely for display grouping, never a stored value:
/// mirrors the server's own `computeAgingBucket`
/// (`functions/src/receivables/receivables-shared.ts`) exactly, so the same
/// título always lands in the same bucket regardless of who computed it.
enum AgingBucket {
  current,
  d1to30,
  d31to60,
  d61to90,
  d90plus;

  String get label => switch (this) {
    AgingBucket.current => 'Em dia',
    AgingBucket.d1to30 => '1-30 dias',
    AgingBucket.d31to60 => '31-60 dias',
    AgingBucket.d61to90 => '61-90 dias',
    AgingBucket.d90plus => '90+ dias',
  };
}

AgingBucket agingBucketFor({
  required DateTime dueDate,
  required bool isSettled,
  required DateTime now,
}) {
  if (isSettled) return AgingBucket.current;
  final daysPastDue = now.difference(dueDate).inDays;
  if (daysPastDue <= 0) return AgingBucket.current;
  if (daysPastDue <= 30) return AgingBucket.d1to30;
  if (daysPastDue <= 60) return AgingBucket.d31to60;
  if (daysPastDue <= 90) return AgingBucket.d61to90;
  return AgingBucket.d90plus;
}

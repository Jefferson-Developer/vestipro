enum CommissionEntryStatus {
  provisioned,
  approved,
  paid,
  reversed;

  static CommissionEntryStatus fromCode(String code) => switch (code) {
    'approved' => CommissionEntryStatus.approved,
    'paid' => CommissionEntryStatus.paid,
    'reversed' => CommissionEntryStatus.reversed,
    _ => CommissionEntryStatus.provisioned,
  };

  String get code => switch (this) {
    CommissionEntryStatus.provisioned => 'provisioned',
    CommissionEntryStatus.approved => 'approved',
    CommissionEntryStatus.paid => 'paid',
    CommissionEntryStatus.reversed => 'reversed',
  };
}

final class CommissionEntry {
  const CommissionEntry({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.sellerId,
    this.sellerName,
    required this.ruleId,
    required this.baseAmount,
    required this.commissionAmount,
    required this.currency,
    required this.status,
    required this.periodKey,
    required this.sourceEventId,
    required this.sourceEventType,
    required this.occurredAt,
    required this.calculationTrace,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String sellerId;
  final String? sellerName;
  final String? ruleId;
  final double baseAmount;
  final double commissionAmount;
  final String currency;
  final CommissionEntryStatus status;
  final String periodKey;
  final String sourceEventId;
  final String sourceEventType;
  final DateTime occurredAt;
  final Map<String, Object?> calculationTrace;

  bool get isReversal => status == CommissionEntryStatus.reversed;

  String get sellerLabel =>
      sellerName?.trim().isNotEmpty == true ? sellerName!.trim() : sellerId;
}

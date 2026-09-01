final class InsightCustomerSnapshot {
  const InsightCustomerSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.customerStatus,
    this.segment,
    this.lastOrderAt,
    this.lastOrderValue,
    this.averageTicket,
    this.responsibleSellerId,
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;
  final String customerStatus;
  final String? segment;
  final DateTime? lastOrderAt;
  final double? lastOrderValue;
  final double? averageTicket;
  final String? responsibleSellerId;

  bool get isAdministrativelyInactive =>
      customerStatus.trim().toLowerCase() == 'inactive';
}

/// Contract intentionally created ahead of order approval tasks so discount
/// validations can already return a stable payload for approval workflows.
final class DiscountApprovalRequest {
  const DiscountApprovalRequest({
    required this.organizationId,
    required this.companyId,
    required this.requestedByUserId,
    required this.requestedByRole,
    required this.discountPolicyId,
    required this.requestedDiscountPercent,
    required this.approvalThresholdPercent,
    required this.maxDiscountPercent,
    required this.priceListId,
    required this.createdAt,
    this.orderId,
    this.orderDraftId,
  });

  final String organizationId;
  final String companyId;
  final String requestedByUserId;
  final String requestedByRole;
  final String discountPolicyId;
  final double requestedDiscountPercent;
  final double approvalThresholdPercent;
  final double maxDiscountPercent;
  final String priceListId;
  final DateTime createdAt;
  final String? orderId;
  final String? orderDraftId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'organizationId': organizationId,
      'companyId': companyId,
      'requestedByUserId': requestedByUserId,
      'requestedByRole': requestedByRole,
      'discountPolicyId': discountPolicyId,
      'requestedDiscountPercent': requestedDiscountPercent,
      'approvalThresholdPercent': approvalThresholdPercent,
      'maxDiscountPercent': maxDiscountPercent,
      'priceListId': priceListId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'orderId': orderId,
      'orderDraftId': orderDraftId,
    };
  }
}

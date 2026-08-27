import 'discount_approval_request.dart';
import 'discount_policy.dart';

abstract base class DiscountValidationResult {
  const DiscountValidationResult({
    required this.requestedDiscountPercent,
    required this.policy,
  });

  final double requestedDiscountPercent;
  final DiscountPolicy? policy;
}

final class DiscountAllowed extends DiscountValidationResult {
  const DiscountAllowed({
    required super.requestedDiscountPercent,
    required super.policy,
  });
}

final class DiscountRequiresApproval extends DiscountValidationResult {
  const DiscountRequiresApproval({
    required super.requestedDiscountPercent,
    required super.policy,
    required this.approvalRequest,
  });

  final DiscountApprovalRequest approvalRequest;
}

final class DiscountBlocked extends DiscountValidationResult {
  const DiscountBlocked({
    required super.requestedDiscountPercent,
    required super.policy,
    required this.reason,
  });

  final String reason;
}

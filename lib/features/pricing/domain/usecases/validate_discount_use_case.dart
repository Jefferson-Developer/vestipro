import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/discount_approval_request.dart';
import '../entities/discount_policy.dart';
import '../entities/discount_validation_result.dart';
import '../repositories/discount_policy_repository.dart';

@injectable
final class ValidateDiscountUseCase {
  const ValidateDiscountUseCase(this._repository);

  final DiscountPolicyRepository _repository;

  Future<AppResult<DiscountValidationResult>> call({
    required String organizationId,
    required String companyId,
    required String role,
    required double requestedDiscountPercent,
    required String priceListId,
    required String requestedByUserId,
    String? orderId,
    String? orderDraftId,
    DateTime? now,
  }) async {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (role.trim().isEmpty) fieldErrors['role'] = 'Role is required.';
    if (priceListId.trim().isEmpty) {
      fieldErrors['priceListId'] = 'PriceListId is required.';
    }
    if (requestedByUserId.trim().isEmpty) {
      fieldErrors['requestedByUserId'] = 'requestedByUserId is required.';
    }
    if (requestedDiscountPercent.isNaN ||
        requestedDiscountPercent.isInfinite ||
        requestedDiscountPercent < 0 ||
        requestedDiscountPercent > 100) {
      fieldErrors['requestedDiscountPercent'] =
          'Discount must be between 0% and 100%.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<DiscountValidationResult>(
        ValidationFailure(
          'Invalid discount validation payload.',
          code: 'invalid_discount_validation_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final policiesResult = await _repository.listByCompany(
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
    );
    if (policiesResult is AppFailure<List<DiscountPolicy>>) {
      return AppFailure<DiscountValidationResult>(policiesResult.failure);
    }

    final policies = (policiesResult as AppSuccess<List<DiscountPolicy>>).value;
    final matchingPolicy = policies.where((policy) {
      return policy.isActive &&
          policy.role == role.trim() &&
          policy.appliesToPriceList(priceListId.trim());
    }).firstOrNull;

    if (matchingPolicy == null) {
      return AppSuccess<DiscountValidationResult>(
        DiscountBlocked(
          requestedDiscountPercent: requestedDiscountPercent,
          policy: null,
          reason:
              'Nenhuma política de desconto ativa foi cadastrada para este perfil e tabela.',
        ),
      );
    }

    if (requestedDiscountPercent <=
        matchingPolicy.approvalThresholdPercent + 0.0001) {
      return AppSuccess<DiscountValidationResult>(
        DiscountAllowed(
          requestedDiscountPercent: requestedDiscountPercent,
          policy: matchingPolicy,
        ),
      );
    }

    if (requestedDiscountPercent <=
        matchingPolicy.maxDiscountPercent + 0.0001) {
      return AppSuccess<DiscountValidationResult>(
        DiscountRequiresApproval(
          requestedDiscountPercent: requestedDiscountPercent,
          policy: matchingPolicy,
          approvalRequest: DiscountApprovalRequest(
            organizationId: matchingPolicy.organizationId,
            companyId: matchingPolicy.companyId,
            requestedByUserId: requestedByUserId.trim(),
            requestedByRole: matchingPolicy.role,
            discountPolicyId: matchingPolicy.id,
            requestedDiscountPercent: requestedDiscountPercent,
            approvalThresholdPercent: matchingPolicy.approvalThresholdPercent,
            maxDiscountPercent: matchingPolicy.maxDiscountPercent,
            priceListId: priceListId.trim(),
            createdAt: (now ?? DateTime.now()).toUtc(),
            orderId: orderId,
            orderDraftId: orderDraftId,
          ),
        ),
      );
    }

    return AppSuccess<DiscountValidationResult>(
      DiscountBlocked(
        requestedDiscountPercent: requestedDiscountPercent,
        policy: matchingPolicy,
        reason:
            'O desconto solicitado excede o limite máximo permitido para este perfil.',
      ),
    );
  }
}

import '../dtos/credit_check_result_dto.dart';

/// Every credit mutation/preview (TASK-212) goes through this Cloud
/// Functions surface — never a direct Firestore write, mirroring the
/// `CloudFunctionsBuyerCollaborationWriteDataSource` (TASK-211) contract.
abstract interface class CreditWriteDataSource {
  Future<CreditCheckResultDto> validateOrderCredit({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double orderTotal,
  });

  Future<void> updateProfile({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double creditLimit,
    required double openBalance,
    required double overdueBalance,
    required String blockPolicy,
    double? financialScore,
    required String dataSource,
    required bool manualBlockActive,
    String? manualBlockReason,
  });

  Future<void> grantOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required String expiresAt,
  });

  Future<void> revokeOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
  });
}

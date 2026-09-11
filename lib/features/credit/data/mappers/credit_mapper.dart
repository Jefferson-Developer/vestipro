import '../../domain/entities/credit_check_result.dart';
import '../../domain/entities/customer_credit_manual_block.dart';
import '../../domain/entities/customer_credit_override.dart';
import '../../domain/entities/customer_credit_profile.dart';
import '../../domain/value_objects/credit_block_policy.dart';
import '../../domain/value_objects/credit_status.dart';
import '../dtos/credit_check_result_dto.dart';
import '../dtos/customer_credit_profile_dto.dart';

extension CreditCheckResultDtoMapper on CreditCheckResultDto {
  CreditCheckResult toDomain() => CreditCheckResult(
    status: CreditStatus.fromCode(status),
    blocked: blocked,
    approvalRequired: approvalRequired,
    message: message,
    dataStale: dataStale,
    sensitive: sensitive == null
        ? null
        : CreditCheckSensitiveDetail(
            creditLimit: sensitive!.creditLimit,
            openBalance: sensitive!.openBalance,
            overdueBalance: sensitive!.overdueBalance,
            financialScore: sensitive!.financialScore,
            dataUpdatedAt: sensitive!.dataUpdatedAt,
          ),
  );
}

extension CustomerCreditProfileDtoMapper on CustomerCreditProfileDto {
  CustomerCreditProfile toDomain() => CustomerCreditProfile(
    customerId: id,
    organizationId: organizationId,
    companyId: companyId,
    creditLimit: creditLimit,
    openBalance: openBalance,
    overdueBalance: overdueBalance,
    blockPolicy: CreditBlockPolicy.fromCode(blockPolicy),
    financialScore: financialScore,
    dataSource: dataSource,
    dataUpdatedAt: dataUpdatedAt,
    manualBlock: CustomerCreditManualBlock(
      active: manualBlock.active,
      reason: manualBlock.reason,
      by: manualBlock.by,
      at: manualBlock.at,
    ),
    creditOverride: CustomerCreditOverride(
      active: creditOverride.active,
      reason: creditOverride.reason,
      approvedBy: creditOverride.approvedBy,
      approvedByName: creditOverride.approvedByName,
      approvedAt: creditOverride.approvedAt,
      expiresAt: creditOverride.expiresAt,
    ),
    updatedAt: updatedAt,
    version: version,
  );
}

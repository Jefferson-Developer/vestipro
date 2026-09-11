import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/credit_check_result.dart';
import '../entities/customer_credit_profile.dart';
import '../repositories/credit_repository.dart';
import '../value_objects/credit_block_policy.dart';

/// Read-only preview of TASK-212's credit rule — used both by the "novo
/// pedido" screen's pre-submit validation (`OrderSubmissionValidationCubit`)
/// and by the customer 360º screen's masked status badge for callers without
/// `finance.view`.
@injectable
final class ValidateOrderCreditUseCase {
  const ValidateOrderCreditUseCase(this._repository);
  final CreditRepository _repository;

  Future<AppResult<CreditCheckResult>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double orderTotal,
  }) => _repository.validateOrderCredit(
    organizationId: organizationId,
    companyId: companyId,
    customerId: customerId,
    orderTotal: orderTotal,
  );
}

/// Live full-detail `CustomerCreditProfile` — the customer 360º screen's
/// financially-authorized (`finance.view`) panel.
@injectable
final class WatchCustomerCreditProfileUseCase {
  const WatchCustomerCreditProfileUseCase(this._repository);
  final CreditRepository _repository;

  Stream<AppResult<CustomerCreditProfile?>> call({
    required String organizationId,
    required String customerId,
  }) => _repository.watchProfile(
    organizationId: organizationId,
    customerId: customerId,
  );
}

/// Creates/edits a `CustomerCreditProfile` — `finance.manage` only.
@injectable
final class UpdateCreditProfileUseCase {
  const UpdateCreditProfileUseCase(this._repository);
  final CreditRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double creditLimit,
    required double openBalance,
    required double overdueBalance,
    required CreditBlockPolicy blockPolicy,
    double? financialScore,
    String dataSource = 'manual',
    bool manualBlockActive = false,
    String? manualBlockReason,
  }) => _repository.updateProfile(
    organizationId: organizationId,
    companyId: companyId,
    customerId: customerId,
    creditLimit: creditLimit,
    openBalance: openBalance,
    overdueBalance: overdueBalance,
    blockPolicy: blockPolicy,
    financialScore: financialScore,
    dataSource: dataSource,
    manualBlockActive: manualBlockActive,
    manualBlockReason: manualBlockReason,
  );
}

/// Grants a time-limited exception to an otherwise-blocking profile —
/// `finance.manage` only.
@injectable
final class GrantCreditOverrideUseCase {
  const GrantCreditOverrideUseCase(this._repository);
  final CreditRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required DateTime expiresAt,
  }) => _repository.grantOverride(
    organizationId: organizationId,
    companyId: companyId,
    customerId: customerId,
    reason: reason,
    expiresAt: expiresAt,
  );
}

/// Revokes an override already granted, before its own expiry —
/// `finance.manage` only.
@injectable
final class RevokeCreditOverrideUseCase {
  const RevokeCreditOverrideUseCase(this._repository);
  final CreditRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) => _repository.revokeOverride(
    organizationId: organizationId,
    companyId: companyId,
    customerId: customerId,
  );
}

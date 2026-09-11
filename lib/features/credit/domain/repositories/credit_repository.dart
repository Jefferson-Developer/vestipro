import '../../../../core/utils/utils.dart';
import '../entities/credit_check_result.dart';
import '../entities/customer_credit_profile.dart';
import '../value_objects/credit_block_policy.dart';

abstract interface class CreditRepository {
  /// Read-only preview of TASK-212's credit rule for [customerId] and
  /// [orderTotal] — callable by any active member; [sensitive] on the
  /// result is only ever populated for a financially-authorized caller
  /// (resolved server-side, never trusted from any local role guess).
  Future<AppResult<CreditCheckResult>> validateOrderCredit({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double orderTotal,
  });

  /// Live, full-detail `CustomerCreditProfile` — only ever resolves for a
  /// caller whose Membership actually holds `finance.view`
  /// (`firestore.rules`'s `creditProfiles` match block denies the read
  /// outright for anyone else, so this stream fails/stays empty for a
  /// seller, it never silently succeeds with sensitive data).
  Stream<AppResult<CustomerCreditProfile?>> watchProfile({
    required String organizationId,
    required String customerId,
  });

  /// Creates (first call) or edits an existing `CustomerCreditProfile` —
  /// `finance.manage` only, always audited server-side.
  Future<AppResult<void>> updateProfile({
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
  });

  /// Grants a time-limited exception to an otherwise-blocking profile —
  /// `finance.manage` only, always requires [reason] and a future
  /// [expiresAt].
  Future<AppResult<void>> grantOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required DateTime expiresAt,
  });

  /// Revokes an override already granted, before its own [expiresAt] —
  /// `finance.manage` only.
  Future<AppResult<void>> revokeOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
  });
}

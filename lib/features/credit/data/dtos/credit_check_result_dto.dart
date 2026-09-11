import '../../../../core/errors/errors.dart';

final class CreditCheckSensitiveDetailDto {
  const CreditCheckSensitiveDetailDto({
    required this.creditLimit,
    required this.openBalance,
    required this.overdueBalance,
    this.financialScore,
    required this.dataUpdatedAt,
  });

  factory CreditCheckSensitiveDetailDto.fromJson(Map<String, dynamic> json) {
    final creditLimit = json['creditLimit'];
    final openBalance = json['openBalance'];
    final overdueBalance = json['overdueBalance'];
    final dataUpdatedAt = json['dataUpdatedAt'];
    if (creditLimit is! num ||
        openBalance is! num ||
        overdueBalance is! num ||
        dataUpdatedAt is! String) {
      throw const ValidationException(
        'Invalid credit check sensitive detail payload.',
        code: 'invalid_credit_check_sensitive_payload',
      );
    }
    final financialScore = json['financialScore'];
    return CreditCheckSensitiveDetailDto(
      creditLimit: creditLimit.toDouble(),
      openBalance: openBalance.toDouble(),
      overdueBalance: overdueBalance.toDouble(),
      financialScore: financialScore is num ? financialScore.toDouble() : null,
      dataUpdatedAt: DateTime.parse(dataUpdatedAt),
    );
  }

  final double creditLimit;
  final double openBalance;
  final double overdueBalance;
  final double? financialScore;
  final DateTime dataUpdatedAt;
}

/// Response shape of the `validateOrderCredit` callable (TASK-212) —
/// mirrors `ValidateOrderCreditResponse` (`functions/src/credit/validate-order-credit.ts`)
/// field for field.
final class CreditCheckResultDto {
  const CreditCheckResultDto({
    required this.status,
    required this.blocked,
    required this.approvalRequired,
    required this.message,
    required this.dataStale,
    this.sensitive,
  });

  factory CreditCheckResultDto.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final blocked = json['blocked'];
    final approvalRequired = json['approvalRequired'];
    final message = json['message'];
    final dataStale = json['dataStale'];
    if (status is! String ||
        blocked is! bool ||
        approvalRequired is! bool ||
        message is! String ||
        dataStale is! bool) {
      throw const ValidationException(
        'Invalid credit check result payload.',
        code: 'invalid_credit_check_result_payload',
      );
    }
    final sensitive = json['sensitive'];
    return CreditCheckResultDto(
      status: status,
      blocked: blocked,
      approvalRequired: approvalRequired,
      message: message,
      dataStale: dataStale,
      sensitive: sensitive is Map<String, dynamic>
          ? CreditCheckSensitiveDetailDto.fromJson(sensitive)
          : null,
    );
  }

  final String status;
  final bool blocked;
  final bool approvalRequired;
  final String message;
  final bool dataStale;
  final CreditCheckSensitiveDetailDto? sensitive;
}

import '../value_objects/credit_block_policy.dart';
import 'customer_credit_manual_block.dart';
import 'customer_credit_override.dart';

/// `organizations/{organizationId}/creditProfiles/{customerId}` (TASK-212,
/// EPIC-32) — limite de crédito, saldo em aberto, saldo vencido, política de
/// bloqueio, score financeiro e a última exceção concedida para um cliente.
/// Dado financeiro sensível: só resolvido pela camada de dados quando o
/// chamador tem `finance.view` (`firestore.rules`' `creditProfiles` match
/// block já nega a leitura direta para qualquer outro perfil).
final class CustomerCreditProfile {
  const CustomerCreditProfile({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.creditLimit,
    required this.openBalance,
    required this.overdueBalance,
    required this.blockPolicy,
    this.financialScore,
    required this.dataSource,
    required this.dataUpdatedAt,
    required this.manualBlock,
    required this.creditOverride,
    required this.updatedAt,
    required this.version,
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final double creditLimit;
  final double openBalance;
  final double overdueBalance;
  final CreditBlockPolicy blockPolicy;
  final double? financialScore;
  final String dataSource;
  final DateTime dataUpdatedAt;
  final CustomerCreditManualBlock manualBlock;
  final CustomerCreditOverride creditOverride;
  final DateTime updatedAt;
  final int version;

  double get availableCredit => creditLimit - openBalance;

  /// Mirrors the server's own `isCreditDataStale` (`credit-shared.ts`) —
  /// kept in Dart only for display purposes (e.g. "atualizado há 42 dias"),
  /// never to decide blocking: that decision is always the server's.
  bool isDataStaleAt(
    DateTime now, {
    Duration threshold = const Duration(days: 30),
  }) => now.difference(dataUpdatedAt) > threshold;

  @override
  bool operator ==(Object other) =>
      other is CustomerCreditProfile &&
      other.customerId == customerId &&
      other.organizationId == organizationId &&
      other.companyId == companyId &&
      other.creditLimit == creditLimit &&
      other.openBalance == openBalance &&
      other.overdueBalance == overdueBalance &&
      other.blockPolicy == blockPolicy &&
      other.financialScore == financialScore &&
      other.dataSource == dataSource &&
      other.dataUpdatedAt == dataUpdatedAt &&
      other.manualBlock == manualBlock &&
      other.creditOverride == creditOverride &&
      other.updatedAt == updatedAt &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    customerId,
    organizationId,
    companyId,
    creditLimit,
    openBalance,
    overdueBalance,
    blockPolicy,
    financialScore,
    dataSource,
    dataUpdatedAt,
    manualBlock,
    creditOverride,
    Object.hash(updatedAt, version),
  );
}

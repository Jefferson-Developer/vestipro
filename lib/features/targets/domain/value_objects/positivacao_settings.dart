import '../../../organizations/organizations.dart';
import 'target_period_granularity.dart';

/// Organization-configurable positivação rule (TASK-117, EPIC-15/VESTI-087):
/// which period cadence, which `OrderStatus` codes and which minimum order
/// value make a customer count as "positivado" (bought in the period).
///
/// Persisted on `OrganizationSettings.positivacao*` (never hardcoded in this
/// feature) so different organizations/brands can each configure their own
/// rule — see that value object's own docs for why the raw fields live
/// there instead of here.
final class PositivacaoSettings {
  const PositivacaoSettings({
    required this.periodGranularity,
    required this.eligibleOrderStatusCodes,
    this.minOrderValue,
  });

  /// Parses [OrganizationSettings.positivacaoPeriodGranularity] into a
  /// [TargetPeriodGranularity], falling back to
  /// [TargetPeriodGranularity.monthly] for a value this feature does not
  /// recognize (e.g. a stale/corrupted document) instead of throwing —
  /// positivação must always be computable with *some* period, even a
  /// degraded default.
  factory PositivacaoSettings.fromOrganizationSettings(
    OrganizationSettings settings,
  ) {
    return PositivacaoSettings(
      periodGranularity: TargetPeriodGranularity.values.firstWhere(
        (value) => value.name == settings.positivacaoPeriodGranularity,
        orElse: () => TargetPeriodGranularity.monthly,
      ),
      eligibleOrderStatusCodes: settings.positivacaoEligibleOrderStatuses
          .toSet(),
      minOrderValue: settings.positivacaoMinOrderValue,
    );
  }

  final TargetPeriodGranularity periodGranularity;

  /// Raw `OrderStatus.name` codes that count as "the customer bought" — kept
  /// as strings (never `OrderStatus` itself) so this domain value object
  /// never needs to import the `orders` feature; `PositivacaoCalculationService`
  /// is the one caller that compares them against a real order's status code.
  final Set<String> eligibleOrderStatusCodes;

  /// Minimum order total for it to count, or `null` for no minimum.
  final double? minOrderValue;

  /// Whether [orderStatusCode] counts towards positivação under this rule.
  bool isEligibleStatus(String orderStatusCode) =>
      eligibleOrderStatusCodes.contains(orderStatusCode);

  /// Whether an order of [orderTotal] clears [minOrderValue] — always `true`
  /// when no minimum is configured.
  bool meetsMinimumValue(double orderTotal) =>
      minOrderValue == null || orderTotal >= minOrderValue!;
}

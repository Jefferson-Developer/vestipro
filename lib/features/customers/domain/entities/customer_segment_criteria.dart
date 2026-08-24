import 'customer_portfolio_filters.dart';
import '../value_objects/customer_status.dart';

/// Combinable, AND-only filter criteria behind a saved [CustomerSegment]
/// (TASK-053).
///
/// [portfolioFilters] reuses the exact filters already implemented for the
/// carteira in TASK-051 (status, region/UF, potential and last purchase).
/// [purchasedCategoryCodes] is the "categoria de produto comprada" dynamic
/// criterion required by TASK-053's scope: it is persisted today, but is
/// intentionally NOT enforced yet by [toPortfolioFilters] — purchase history
/// per product category does not exist until the order history epics
/// (EPIC-08/13) are implemented. Once that data source exists, segments
/// created today will start being restricted by it automatically; this is a
/// documented limitation, not a bug.
///
/// This version only supports combining criteria via AND; there is no
/// support for OR, per TASK-053's "Regras de negócio e restrições".
final class CustomerSegmentCriteria {
  const CustomerSegmentCriteria({
    this.portfolioFilters = CustomerPortfolioFilters.empty,
    this.purchasedCategoryCodes = const <String>{},
  });

  final CustomerPortfolioFilters portfolioFilters;
  final Set<String> purchasedCategoryCodes;

  static const empty = CustomerSegmentCriteria();

  bool get isEmpty =>
      portfolioFilters.isEmpty && purchasedCategoryCodes.isEmpty;

  /// Number of distinct filter facets combined in this criteria (status,
  /// region, potential, last purchase and purchased category). Used to
  /// confirm three-or-more facets are being combined simultaneously.
  int get combinedFacetCount {
    var count = 0;
    if (portfolioFilters.statuses.isNotEmpty) count += 1;
    if (portfolioFilters.stateCodes.isNotEmpty) count += 1;
    if (portfolioFilters.potentials.isNotEmpty) count += 1;
    if (portfolioFilters.lastPurchase != CustomerLastPurchaseFilter.any) {
      count += 1;
    }
    if (purchasedCategoryCodes.isNotEmpty) count += 1;
    return count;
  }

  CustomerSegmentCriteria normalized() {
    return CustomerSegmentCriteria(
      portfolioFilters: portfolioFilters.normalized(),
      purchasedCategoryCodes: Set<String>.unmodifiable(
        purchasedCategoryCodes
            .map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty),
      ),
    );
  }

  CustomerSegmentCriteria copyWith({
    CustomerPortfolioFilters? portfolioFilters,
    Set<String>? purchasedCategoryCodes,
  }) {
    return CustomerSegmentCriteria(
      portfolioFilters: portfolioFilters ?? this.portfolioFilters,
      purchasedCategoryCodes:
          purchasedCategoryCodes ?? this.purchasedCategoryCodes,
    ).normalized();
  }

  /// Filters to apply when this segment is used as a quick filter in the
  /// carteira. See the class doc: [purchasedCategoryCodes] is intentionally
  /// not translated into a restriction yet.
  CustomerPortfolioFilters toPortfolioFilters() => portfolioFilters;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'statuses': portfolioFilters.statuses
          .map((status) => status.name)
          .toList(growable: false),
      'stateCodes': portfolioFilters.stateCodes.toList(growable: false),
      'potentials': portfolioFilters.potentials.toList(growable: false),
      'lastPurchase': portfolioFilters.lastPurchase.code,
      'purchasedCategoryCodes': purchasedCategoryCodes.toList(growable: false),
    };
  }

  factory CustomerSegmentCriteria.fromJson(Map<String, dynamic> json) {
    return CustomerSegmentCriteria(
      portfolioFilters: CustomerPortfolioFilters(
        statuses: _statusSetFromJson(json['statuses']),
        stateCodes: _stringSetFromJson(json['stateCodes']),
        potentials: _stringSetFromJson(json['potentials']),
        lastPurchase: CustomerLastPurchaseFilterCode.fromCode(
          json['lastPurchase'] as String?,
        ),
      ),
      purchasedCategoryCodes: _stringSetFromJson(
        json['purchasedCategoryCodes'],
      ),
    ).normalized();
  }

  static Set<String> _stringSetFromJson(Object? value) {
    if (value is! List<dynamic>) return const <String>{};
    return value.whereType<String>().toSet();
  }

  static Set<CustomerStatus> _statusSetFromJson(Object? value) {
    final names = _stringSetFromJson(value);
    return <CustomerStatus>{
      for (final status in CustomerStatus.values)
        if (names.contains(status.name)) status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerSegmentCriteria &&
        other.portfolioFilters == portfolioFilters &&
        _setEquals(other.purchasedCategoryCodes, purchasedCategoryCodes);
  }

  @override
  int get hashCode => Object.hash(
    portfolioFilters,
    Object.hashAll(purchasedCategoryCodes.toList()..sort()),
  );

  static bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }
}

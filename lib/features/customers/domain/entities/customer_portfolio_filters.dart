import '../value_objects/customer_status.dart';

enum CustomerLastPurchaseFilter {
  any,
  never,
  last30Days,
  last60Days,
  last90Days,
  olderThan90Days,
}

extension CustomerLastPurchaseFilterCode on CustomerLastPurchaseFilter {
  String get code {
    return switch (this) {
      CustomerLastPurchaseFilter.any => 'any',
      CustomerLastPurchaseFilter.never => 'never',
      CustomerLastPurchaseFilter.last30Days => 'last30',
      CustomerLastPurchaseFilter.last60Days => 'last60',
      CustomerLastPurchaseFilter.last90Days => 'last90',
      CustomerLastPurchaseFilter.olderThan90Days => 'older90',
    };
  }

  String get label {
    return switch (this) {
      CustomerLastPurchaseFilter.any => 'Qualquer compra',
      CustomerLastPurchaseFilter.never => 'Sem compra',
      CustomerLastPurchaseFilter.last30Days => 'Ultimos 30 dias',
      CustomerLastPurchaseFilter.last60Days => 'Ultimos 60 dias',
      CustomerLastPurchaseFilter.last90Days => 'Ultimos 90 dias',
      CustomerLastPurchaseFilter.olderThan90Days => 'Mais de 90 dias',
    };
  }

  static CustomerLastPurchaseFilter fromCode(String? code) {
    return switch (code) {
      'never' => CustomerLastPurchaseFilter.never,
      'last30' => CustomerLastPurchaseFilter.last30Days,
      'last60' => CustomerLastPurchaseFilter.last60Days,
      'last90' => CustomerLastPurchaseFilter.last90Days,
      'older90' => CustomerLastPurchaseFilter.olderThan90Days,
      _ => CustomerLastPurchaseFilter.any,
    };
  }
}

final class CustomerPortfolioFilters {
  const CustomerPortfolioFilters({
    this.statuses = const <CustomerStatus>{},
    this.stateCodes = const <String>{},
    this.potentials = const <String>{},
    this.lastPurchase = CustomerLastPurchaseFilter.any,
  });

  final Set<CustomerStatus> statuses;
  final Set<String> stateCodes;
  final Set<String> potentials;
  final CustomerLastPurchaseFilter lastPurchase;

  static const empty = CustomerPortfolioFilters();

  bool get isEmpty =>
      statuses.isEmpty &&
      stateCodes.isEmpty &&
      potentials.isEmpty &&
      lastPurchase == CustomerLastPurchaseFilter.any;

  CustomerPortfolioFilters normalized() {
    return CustomerPortfolioFilters(
      statuses: Set<CustomerStatus>.unmodifiable(statuses),
      stateCodes: Set<String>.unmodifiable(
        stateCodes
            .map((state) => state.trim().toUpperCase())
            .where((state) => state.isNotEmpty),
      ),
      potentials: Set<String>.unmodifiable(
        potentials
            .map((potential) => potential.trim())
            .where((potential) => potential.isNotEmpty),
      ),
      lastPurchase: lastPurchase,
    );
  }

  CustomerPortfolioFilters copyWith({
    Set<CustomerStatus>? statuses,
    Set<String>? stateCodes,
    Set<String>? potentials,
    CustomerLastPurchaseFilter? lastPurchase,
  }) {
    return CustomerPortfolioFilters(
      statuses: statuses ?? this.statuses,
      stateCodes: stateCodes ?? this.stateCodes,
      potentials: potentials ?? this.potentials,
      lastPurchase: lastPurchase ?? this.lastPurchase,
    ).normalized();
  }

  Map<String, String> toQueryParameters({String search = ''}) {
    return <String, String>{
      if (search.trim().isNotEmpty) 'q': search.trim(),
      if (statuses.isNotEmpty)
        'status': statuses.map((status) => status.name).join(','),
      if (stateCodes.isNotEmpty) 'uf': stateCodes.join(','),
      if (potentials.isNotEmpty) 'potential': potentials.join(','),
      if (lastPurchase != CustomerLastPurchaseFilter.any)
        'lastPurchase': lastPurchase.code,
    };
  }

  static CustomerPortfolioFilters fromQueryParameters(
    Map<String, String> query,
  ) {
    return CustomerPortfolioFilters(
      statuses: _statusSet(query['status']),
      stateCodes: _csvSet(
        query['uf'],
      ).map((state) => state.toUpperCase()).toSet(),
      potentials: _csvSet(query['potential']),
      lastPurchase: CustomerLastPurchaseFilterCode.fromCode(
        query['lastPurchase'],
      ),
    ).normalized();
  }

  static Set<String> _csvSet(String? value) {
    if (value == null || value.trim().isEmpty) return const <String>{};
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Set<CustomerStatus> _statusSet(String? value) {
    final names = _csvSet(value);
    return <CustomerStatus>{
      for (final status in CustomerStatus.values)
        if (names.contains(status.name)) status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerPortfolioFilters &&
        _setEquals(other.statuses, statuses) &&
        _setEquals(other.stateCodes, stateCodes) &&
        _setEquals(other.potentials, potentials) &&
        other.lastPurchase == lastPurchase;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(statuses.map((status) => status.index).toList()..sort()),
    Object.hashAll(stateCodes.toList()..sort()),
    Object.hashAll(potentials.toList()..sort()),
    lastPurchase,
  );

  static bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }
}

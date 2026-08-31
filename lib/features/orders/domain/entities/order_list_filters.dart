import '../value_objects/order_status.dart';

/// Combinable filters for [ListOrdersUseCase] (TASK-102): status, período,
/// cliente and vendedor — mirroring `LeadListFilters`/`CustomerPortfolioFilters`.
///
/// [sellerIds] is never populated directly by UI text input: it is always
/// resolved by `OrderVisibilityService` from the caller's own RBAC scope
/// (plus, optionally, one explicit seller the UI narrowed to, when the
/// caller is allowed to see more than their own orders) — never trusted
/// from a raw client value alone.
final class OrderListFilters {
  const OrderListFilters({
    this.status,
    this.customerId,
    this.orderNumber,
    this.sellerIds = const <String>{},
    this.from,
    this.to,
  });

  final OrderStatus? status;
  final String? customerId;
  final String? orderNumber;
  final Set<String> sellerIds;
  final DateTime? from;
  final DateTime? to;

  static const empty = OrderListFilters();

  bool get isEmpty =>
      status == null &&
      (customerId == null || customerId!.isEmpty) &&
      (orderNumber == null || orderNumber!.isEmpty) &&
      sellerIds.isEmpty &&
      from == null &&
      to == null;

  OrderListFilters normalized() {
    final trimmedCustomerId = customerId?.trim();
    final trimmedOrderNumber = orderNumber?.trim();
    return OrderListFilters(
      status: status,
      customerId: (trimmedCustomerId == null || trimmedCustomerId.isEmpty)
          ? null
          : trimmedCustomerId,
      orderNumber: (trimmedOrderNumber == null || trimmedOrderNumber.isEmpty)
          ? null
          : trimmedOrderNumber,
      sellerIds: Set<String>.unmodifiable(
        sellerIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      ),
      from: from,
      to: to,
    );
  }

  OrderListFilters copyWith({
    OrderStatus? status,
    bool clearStatus = false,
    String? customerId,
    String? orderNumber,
    Set<String>? sellerIds,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return OrderListFilters(
      status: clearStatus ? null : status ?? this.status,
      customerId: customerId ?? this.customerId,
      orderNumber: orderNumber ?? this.orderNumber,
      sellerIds: sellerIds ?? this.sellerIds,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
    ).normalized();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderListFilters &&
        other.status == status &&
        other.customerId == customerId &&
        other.orderNumber == orderNumber &&
        other.from == from &&
        other.to == to &&
        _setEquals(other.sellerIds, sellerIds);
  }

  @override
  int get hashCode => Object.hash(
    status,
    customerId,
    orderNumber,
    from,
    to,
    Object.hashAll(sellerIds.toList()..sort()),
  );

  bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }

  /// Flutter Web deep-link representation (`tasks.md`'s own "filtros
  /// aplicados devem ser preserváveis na URL"), mirroring
  /// `CustomerPortfolioFilters.toQueryParameters`/`.fromQueryParameters`.
  /// [sellerIds] is deliberately excluded: it always reflects
  /// `OrderVisibilityService`'s own RBAC resolution (plus, at most, one
  /// explicit UI pick already carried by the page's own "vendedor" text
  /// filter state, not this object) — round-tripping it through a URL a
  /// caller could hand-edit would let them widen their own visible scope.
  Map<String, String> toQueryParameters({String search = ''}) {
    return <String, String>{
      if (search.trim().isNotEmpty) 'q': search.trim(),
      if (status != null) 'status': status!.name,
      if (customerId != null && customerId!.isNotEmpty)
        'customerId': customerId!,
      if (from != null) 'from': _dateOnly(from!),
      if (to != null) 'to': _dateOnly(to!),
    };
  }

  static OrderListFilters fromQueryParameters(Map<String, String> query) {
    return OrderListFilters(
      status: _statusFromCode(query['status']),
      customerId: query['customerId'],
      from: _parseDateOnly(query['from']),
      to: _parseDateOnly(query['to']),
    ).normalized();
  }

  static OrderStatus? _statusFromCode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final status in OrderStatus.values) {
      if (status.name == value.trim()) return status;
    }
    return null;
  }

  static String _dateOnly(DateTime date) {
    final utc = date.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static DateTime? _parseDateOnly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime.utc(year, month, day);
  }
}

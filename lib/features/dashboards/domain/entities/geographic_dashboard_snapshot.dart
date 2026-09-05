enum GeographicDashboardLevel { region, state, city }

final class GeographicProductHighlight {
  const GeographicProductHighlight({
    required this.name,
    required this.quantity,
  });
  final String name;
  final int quantity;
}

final class GeographicDashboardRow {
  const GeographicDashboardRow({
    required this.id,
    required this.label,
    required this.level,
    required this.revenue,
    required this.orderCount,
    required this.activeCustomerCount,
    required this.itemQuantity,
    this.topProducts = const <GeographicProductHighlight>[],
    this.customerIds = const <String>[],
    this.orderIds = const <String>[],
    this.children = const <GeographicDashboardRow>[],
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final GeographicDashboardLevel level;
  final double revenue;
  final int orderCount;
  final int activeCustomerCount;
  final int itemQuantity;
  final List<GeographicProductHighlight> topProducts;
  final List<String> customerIds;
  final List<String> orderIds;
  final List<GeographicDashboardRow> children;
  final double? latitude;
  final double? longitude;

  double get averageTicket => orderCount == 0 ? 0 : revenue / orderCount;
  bool get hasCoordinates => latitude != null && longitude != null;
}

final class GeographicDashboardSnapshot {
  const GeographicDashboardSnapshot({
    required this.regions,
    required this.generatedAt,
    required this.isFromLocalCache,
  });

  final List<GeographicDashboardRow> regions;
  final DateTime? generatedAt;
  final bool isFromLocalCache;

  double get revenue => regions.fold(0, (sum, row) => sum + row.revenue);
  int get orderCount => regions.fold(0, (sum, row) => sum + row.orderCount);
  int get activeCustomerCount =>
      regions.fold(0, (sum, row) => sum + row.activeCustomerCount);
  double get averageTicket => orderCount == 0 ? 0 : revenue / orderCount;
  bool get hasMapData => regions.any(
    (region) => region.children.any(
      (state) => state.children.any((city) => city.hasCoordinates),
    ),
  );
}

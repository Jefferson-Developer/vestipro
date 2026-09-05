enum ReportSortDirection { ascending, descending }

enum ReportComparisonPeriod { none, previousPeriod, previousYear }

final class ReportFilter {
  const ReportFilter({
    required this.fieldId,
    required this.operatorId,
    required this.value,
  });

  final String fieldId;
  final String operatorId;
  final String value;

  Map<String, Object?> toJson() => <String, Object?>{
    'fieldId': fieldId,
    'operator': operatorId,
    'value': value,
  };

  factory ReportFilter.fromJson(Map<String, dynamic> json) => ReportFilter(
    fieldId: json['fieldId'] as String,
    operatorId: json['operator'] as String,
    value: json['value'] as String,
  );
}

final class ReportSort {
  const ReportSort({required this.fieldId, required this.direction});

  final String fieldId;
  final ReportSortDirection direction;

  Map<String, Object?> toJson() => <String, Object?>{
    'fieldId': fieldId,
    'direction': direction.name,
  };

  factory ReportSort.fromJson(Map<String, dynamic> json) => ReportSort(
    fieldId: json['fieldId'] as String,
    direction: ReportSortDirection.values.byName(json['direction'] as String),
  );
}

/// Reusable query definition shared by the report builder and TASK-145..149.
/// Tenant scope is explicit and immutable; authorization is revalidated by
/// the callable backend and never inferred from a filter selected in the UI.
final class ReportDefinition {
  const ReportDefinition({
    required this.organizationId,
    required this.companyId,
    this.dimensions = const <String>[],
    this.metrics = const <String>[],
    this.filters = const <ReportFilter>[],
    this.groupBy = const <String>[],
    this.sortBy,
    this.comparisonPeriod = ReportComparisonPeriod.none,
  });

  final String organizationId;
  final String companyId;
  final List<String> dimensions;
  final List<String> metrics;
  final List<ReportFilter> filters;
  final List<String> groupBy;
  final ReportSort? sortBy;
  final ReportComparisonPeriod comparisonPeriod;

  ReportDefinition copyWith({
    List<String>? dimensions,
    List<String>? metrics,
    List<ReportFilter>? filters,
    List<String>? groupBy,
    ReportSort? sortBy,
    bool clearSort = false,
    ReportComparisonPeriod? comparisonPeriod,
  }) => ReportDefinition(
    organizationId: organizationId,
    companyId: companyId,
    dimensions: dimensions ?? this.dimensions,
    metrics: metrics ?? this.metrics,
    filters: filters ?? this.filters,
    groupBy: groupBy ?? this.groupBy,
    sortBy: clearSort ? null : sortBy ?? this.sortBy,
    comparisonPeriod: comparisonPeriod ?? this.comparisonPeriod,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'organizationId': organizationId,
    'companyId': companyId,
    'dimensions': dimensions,
    'metrics': metrics,
    'filters': filters.map((item) => item.toJson()).toList(growable: false),
    'groupBy': groupBy,
    if (sortBy != null) 'sortBy': sortBy!.toJson(),
    'comparisonPeriod': comparisonPeriod.name,
  };

  factory ReportDefinition.fromJson(
    Map<String, dynamic> json,
  ) => ReportDefinition(
    organizationId: json['organizationId'] as String,
    companyId: json['companyId'] as String,
    dimensions: List<String>.from(json['dimensions'] as List? ?? const []),
    metrics: List<String>.from(json['metrics'] as List? ?? const []),
    filters: (json['filters'] as List? ?? const [])
        .map(
          (item) =>
              ReportFilter.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    groupBy: List<String>.from(json['groupBy'] as List? ?? const []),
    sortBy: json['sortBy'] == null
        ? null
        : ReportSort.fromJson(Map<String, dynamic>.from(json['sortBy'] as Map)),
    comparisonPeriod: ReportComparisonPeriod.values.byName(
      json['comparisonPeriod'] as String? ?? ReportComparisonPeriod.none.name,
    ),
  );
}

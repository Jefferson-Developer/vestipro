import '../value_objects/insight_severity.dart';
import '../value_objects/insight_sort_by.dart';
import '../value_objects/insight_type.dart';

/// Filter/sort state of the Central de Oportunidades (TASK-132), fully
/// owned by `OpportunityCenterBloc`/`OpportunityCenterState` and mirrored
/// into the route's query parameters so a Flutter Web reload/share link
/// restores exactly the same view — same contract
/// `CustomerPortfolioFilters`/`OrderListFilters` already set.
final class OpportunityCenterFilters {
  const OpportunityCenterFilters({
    this.types = const <InsightType>{},
    this.severities = const <InsightSeverity>{},
    this.periodStart,
    this.periodEnd,
    this.sortBy = InsightSortBy.estimatedImpact,
  });

  static const empty = OpportunityCenterFilters();

  /// Empty means "every type".
  final Set<InsightType> types;

  /// Empty means "every severity" — used as the pragmatic proxy for "faixa
  /// de impacto" (TASK-132): `Insight.estimatedImpact` is a currency
  /// amount/percentage with no canonical tier boundary modeled anywhere
  /// else in the domain, while `InsightSeverity` (low/medium/high/critical)
  /// is already the impact tier every insight rule (TASK-122 a TASK-131)
  /// assigns deterministically.
  final Set<InsightSeverity> severities;

  /// Only insights generated on/after this instant are shown, when set.
  final DateTime? periodStart;

  /// Only insights generated on/before this instant are shown, when set.
  final DateTime? periodEnd;

  final InsightSortBy sortBy;

  bool matches({
    required InsightType type,
    required InsightSeverity severity,
    required DateTime generatedAt,
  }) {
    if (types.isNotEmpty && !types.contains(type)) return false;
    if (severities.isNotEmpty && !severities.contains(severity)) return false;
    final start = periodStart;
    if (start != null && generatedAt.isBefore(start)) return false;
    final end = periodEnd;
    if (end != null && generatedAt.isAfter(end)) return false;
    return true;
  }

  OpportunityCenterFilters copyWith({
    Set<InsightType>? types,
    Set<InsightSeverity>? severities,
    DateTime? periodStart,
    bool clearPeriodStart = false,
    DateTime? periodEnd,
    bool clearPeriodEnd = false,
    InsightSortBy? sortBy,
  }) {
    return OpportunityCenterFilters(
      types: types ?? this.types,
      severities: severities ?? this.severities,
      periodStart: clearPeriodStart ? null : (periodStart ?? this.periodStart),
      periodEnd: clearPeriodEnd ? null : (periodEnd ?? this.periodEnd),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same filter/sort state on a Flutter Web reload/share link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      if (types.isNotEmpty) 'types': types.map((t) => t.name).join(','),
      if (severities.isNotEmpty)
        'severities': severities.map((s) => s.name).join(','),
      if (periodStart != null) 'periodStart': periodStart!.toIso8601String(),
      if (periodEnd != null) 'periodEnd': periodEnd!.toIso8601String(),
      if (sortBy != InsightSortBy.estimatedImpact) 'sortBy': sortBy.name,
    };
  }

  factory OpportunityCenterFilters.fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    Set<T> parseEnumSet<T extends Enum>(String key, List<T> values) {
      final raw = queryParameters[key];
      if (raw == null || raw.trim().isEmpty) return <T>{};
      return raw
          .split(',')
          .map(
            (code) =>
                values.where((value) => value.name == code.trim()).firstOrNull,
          )
          .whereType<T>()
          .toSet();
    }

    DateTime? parseDate(String key) {
      final raw = queryParameters[key];
      if (raw == null || raw.trim().isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return OpportunityCenterFilters(
      types: parseEnumSet('types', InsightType.values),
      severities: parseEnumSet('severities', InsightSeverity.values),
      periodStart: parseDate('periodStart'),
      periodEnd: parseDate('periodEnd'),
      sortBy:
          InsightSortBy.values
              .where((value) => value.name == queryParameters['sortBy'])
              .firstOrNull ??
          InsightSortBy.estimatedImpact,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpportunityCenterFilters &&
        _setEquals(types, other.types) &&
        _setEquals(severities, other.severities) &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        sortBy == other.sortBy;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(severities),
    periodStart,
    periodEnd,
    sortBy,
  );

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

import '../value_objects/sales_dashboard_comparison_mode.dart';
import '../value_objects/sales_dashboard_group_dimension.dart';
import '../value_objects/sales_dashboard_sort_field.dart';

/// Filter/view state of the Sales Dashboard (TASK-135, EPIC-17): which
/// company, which team (optional), which reference month, which grouping
/// breakdown of the drill-down table and which prior period it is compared
/// against — mirrored into the route's query parameters so a Flutter Web
/// reload/share link restores exactly the same view, same contract
/// `ExecutiveDashboardFilters` already sets.
///
/// Deliberately month-granular for the exact same reason
/// `ExecutiveDashboardFilters` already documents: every monthly TASK-133
/// aggregation dimension (`customerMonthly`/`productMonthly`/
/// `sellerMonthly`) is itself month-grained, so anchoring every filter to a
/// single calendar month lets every KPI/row reuse the exact snapshot grain
/// already written, with no client-side re-bucketing.
final class SalesDashboardFilters {
  const SalesDashboardFilters({
    required this.companyId,
    this.teamId,
    required this.year,
    required this.month,
    this.groupDimension = SalesDashboardGroupDimension.seller,
    this.comparisonMode = SalesDashboardComparisonMode.previousMonth,
    this.sortField = SalesDashboardSortField.revenue,
    this.sortDescending = true,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12.');

  /// Builds the filters for the current calendar month (UTC) — the landing
  /// default every caller sees before touching a filter.
  factory SalesDashboardFilters.currentMonth({
    required String companyId,
    String? teamId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return SalesDashboardFilters(
      companyId: companyId,
      teamId: teamId,
      year: reference.year,
      month: reference.month,
    );
  }

  final String companyId;

  /// `null` means "toda a empresa" (no team narrowing) — same semantics as
  /// `ExecutiveDashboardFilters.teamId`.
  final String? teamId;

  final int year;
  final int month;
  final SalesDashboardGroupDimension groupDimension;
  final SalesDashboardComparisonMode comparisonMode;
  final SalesDashboardSortField sortField;
  final bool sortDescending;

  /// `YYYY-MM`, the exact `periodKey` grain every monthly aggregation
  /// dimension (TASK-133) uses.
  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Inclusive start / exclusive end of [year]/[month], always UTC so every
  /// downstream `periodKey` comparison is timezone-stable.
  DateTime get periodStart => DateTime.utc(year, month);

  DateTime get periodEnd => DateTime.utc(year, month + 1);

  /// The same calendar month one year before — the "crescimento YoY"
  /// comparison period.
  SalesDashboardFilters get previousYear => copyWith(year: year - 1);

  /// The immediately preceding calendar month — the "crescimento MoM"/
  /// "comparação com o período anterior" comparison period.
  SalesDashboardFilters get previousMonth {
    final previous = DateTime.utc(year, month - 1);
    return copyWith(year: previous.year, month: previous.month);
  }

  /// The comparison period the drill-down table's "Crescimento" column
  /// actually uses, per [comparisonMode].
  SalesDashboardFilters get comparisonPeriod => switch (comparisonMode) {
    SalesDashboardComparisonMode.previousMonth => previousMonth,
    SalesDashboardComparisonMode.previousYear => previousYear,
  };

  /// Whether [year]/[month] is strictly after the month [now] falls in — the
  /// UI never lets the caller navigate the month picker into the future.
  bool isAfter(DateTime now) {
    final reference = now.toUtc();
    return year > reference.year ||
        (year == reference.year && month > reference.month);
  }

  SalesDashboardFilters copyWith({
    String? companyId,
    String? teamId,
    bool clearTeamId = false,
    int? year,
    int? month,
    SalesDashboardGroupDimension? groupDimension,
    SalesDashboardComparisonMode? comparisonMode,
    SalesDashboardSortField? sortField,
    bool? sortDescending,
  }) {
    return SalesDashboardFilters(
      companyId: companyId ?? this.companyId,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      year: year ?? this.year,
      month: month ?? this.month,
      groupDimension: groupDimension ?? this.groupDimension,
      comparisonMode: comparisonMode ?? this.comparisonMode,
      sortField: sortField ?? this.sortField,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same company/team/month/grouping/comparison on a Flutter Web
  /// reload/share link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      if (teamId != null && teamId!.trim().isNotEmpty) 'teamId': teamId!,
      'month': monthKey,
      'groupBy': groupDimension.code,
      'compare': comparisonMode.code,
      'sortBy': sortField.code,
      'sortDir': sortDescending ? 'desc' : 'asc',
    };
  }

  factory SalesDashboardFilters.fromQueryParameters(
    Map<String, String> queryParameters, {
    required String defaultCompanyId,
    DateTime? now,
  }) {
    final companyId = queryParameters['companyId']?.trim();
    final teamId = queryParameters['teamId']?.trim();
    final monthRaw = queryParameters['month']?.trim();
    final parsedMonth = monthRaw != null && monthRaw.isNotEmpty
        ? RegExp(r'^(\d{4})-(\d{2})$').firstMatch(monthRaw)
        : null;

    final resolvedCompanyId = (companyId == null || companyId.isEmpty)
        ? defaultCompanyId
        : companyId;
    final resolvedTeamId = (teamId == null || teamId.isEmpty) ? null : teamId;
    final groupDimension = SalesDashboardGroupDimensionMapping.fromCode(
      queryParameters['groupBy'],
    );
    final comparisonMode = SalesDashboardComparisonModeMapping.fromCode(
      queryParameters['compare'],
    );
    final sortField = SalesDashboardSortFieldMapping.fromCode(
      queryParameters['sortBy'],
    );
    final sortDescending = queryParameters['sortDir'] != 'asc';

    if (parsedMonth == null) {
      final current = SalesDashboardFilters.currentMonth(
        companyId: resolvedCompanyId,
        teamId: resolvedTeamId,
        now: now,
      );
      return current.copyWith(
        groupDimension: groupDimension,
        comparisonMode: comparisonMode,
        sortField: sortField,
        sortDescending: sortDescending,
      );
    }

    return SalesDashboardFilters(
      companyId: resolvedCompanyId,
      teamId: resolvedTeamId,
      year: int.parse(parsedMonth.group(1)!),
      month: int.parse(parsedMonth.group(2)!).clamp(1, 12),
      groupDimension: groupDimension,
      comparisonMode: comparisonMode,
      sortField: sortField,
      sortDescending: sortDescending,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SalesDashboardFilters &&
        companyId == other.companyId &&
        teamId == other.teamId &&
        year == other.year &&
        month == other.month &&
        groupDimension == other.groupDimension &&
        comparisonMode == other.comparisonMode &&
        sortField == other.sortField &&
        sortDescending == other.sortDescending;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    teamId,
    year,
    month,
    groupDimension,
    comparisonMode,
    sortField,
    sortDescending,
  );
}

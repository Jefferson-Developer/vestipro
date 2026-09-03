import '../value_objects/customer_dashboard_sort_field.dart';

/// Filter/view state of the Customer Dashboard (TASK-136, EPIC-17): which
/// company, which team (optional), which reference month, which customer
/// segment narrows the ranking table (optional, reusing the `segment` label
/// TASK-133's `customerMonthly` dimension already denormalizes, TASK-053's
/// segmentation concept) and which column/direction the ranking is sorted
/// by — mirrored into the route's query parameters so a Flutter Web
/// reload/share link restores exactly the same view, same contract
/// `SalesDashboardFilters` already sets.
///
/// Deliberately month-granular for the exact same reason
/// `SalesDashboardFilters`/`ExecutiveDashboardFilters` already document:
/// `customerMonthly` (TASK-133) is itself month-grained.
final class CustomerDashboardFilters {
  const CustomerDashboardFilters({
    required this.companyId,
    this.teamId,
    required this.year,
    required this.month,
    this.segment,
    this.sortField = CustomerDashboardSortField.revenue,
    this.sortDescending = true,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12.');

  /// Builds the filters for the current calendar month (UTC) — the landing
  /// default every caller sees before touching a filter.
  factory CustomerDashboardFilters.currentMonth({
    required String companyId,
    String? teamId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return CustomerDashboardFilters(
      companyId: companyId,
      teamId: teamId,
      year: reference.year,
      month: reference.month,
    );
  }

  final String companyId;

  /// `null` means "toda a empresa" (no team narrowing) — same semantics as
  /// `SalesDashboardFilters.teamId`. See `LoadCustomerDashboardSnapshotUseCase`
  /// and `CustomerDashboardBloc`'s own docs for which KPIs/rows this can
  /// actually narrow, given `customerMonthly` carries no seller/team label.
  final String? teamId;

  final int year;
  final int month;

  /// Narrows the ranking table to customers whose denormalized
  /// `AggregationSnapshot.labels['segment']` matches (case-insensitive),
  /// `null`/empty meaning "todos os segmentos".
  final String? segment;

  final CustomerDashboardSortField sortField;
  final bool sortDescending;

  /// `YYYY-MM`, the exact `periodKey` grain `customerMonthly` (TASK-133)
  /// uses.
  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Inclusive start / exclusive end of [year]/[month], always UTC so every
  /// downstream `periodKey` comparison is timezone-stable.
  DateTime get periodStart => DateTime.utc(year, month);

  DateTime get periodEnd => DateTime.utc(year, month + 1);

  /// The immediately preceding calendar month — the "comparação com o
  /// período anterior" every KPI/positivação read compares against.
  CustomerDashboardFilters get previousMonth {
    final previous = DateTime.utc(year, month - 1);
    return copyWith(year: previous.year, month: previous.month);
  }

  /// Whether [year]/[month] is strictly after the month [now] falls in — the
  /// UI never lets the caller navigate the month picker into the future.
  bool isAfter(DateTime now) {
    final reference = now.toUtc();
    return year > reference.year ||
        (year == reference.year && month > reference.month);
  }

  CustomerDashboardFilters copyWith({
    String? companyId,
    String? teamId,
    bool clearTeamId = false,
    int? year,
    int? month,
    String? segment,
    bool clearSegment = false,
    CustomerDashboardSortField? sortField,
    bool? sortDescending,
  }) {
    return CustomerDashboardFilters(
      companyId: companyId ?? this.companyId,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      year: year ?? this.year,
      month: month ?? this.month,
      segment: clearSegment ? null : (segment ?? this.segment),
      sortField: sortField ?? this.sortField,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same company/team/month/segment/sort on a Flutter Web reload/share
  /// link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      if (teamId != null && teamId!.trim().isNotEmpty) 'teamId': teamId!,
      'month': monthKey,
      if (segment != null && segment!.trim().isNotEmpty) 'segment': segment!,
      'sortBy': sortField.code,
      'sortDir': sortDescending ? 'desc' : 'asc',
    };
  }

  factory CustomerDashboardFilters.fromQueryParameters(
    Map<String, String> queryParameters, {
    required String defaultCompanyId,
    DateTime? now,
  }) {
    final companyId = queryParameters['companyId']?.trim();
    final teamId = queryParameters['teamId']?.trim();
    final segment = queryParameters['segment']?.trim();
    final monthRaw = queryParameters['month']?.trim();
    final parsedMonth = monthRaw != null && monthRaw.isNotEmpty
        ? RegExp(r'^(\d{4})-(\d{2})$').firstMatch(monthRaw)
        : null;

    final resolvedCompanyId = (companyId == null || companyId.isEmpty)
        ? defaultCompanyId
        : companyId;
    final resolvedTeamId = (teamId == null || teamId.isEmpty) ? null : teamId;
    final resolvedSegment = (segment == null || segment.isEmpty)
        ? null
        : segment;
    final sortField = CustomerDashboardSortFieldMapping.fromCode(
      queryParameters['sortBy'],
    );
    final sortDescending = queryParameters['sortDir'] != 'asc';

    if (parsedMonth == null) {
      final current = CustomerDashboardFilters.currentMonth(
        companyId: resolvedCompanyId,
        teamId: resolvedTeamId,
        now: now,
      );
      return current.copyWith(
        segment: resolvedSegment,
        sortField: sortField,
        sortDescending: sortDescending,
      );
    }

    return CustomerDashboardFilters(
      companyId: resolvedCompanyId,
      teamId: resolvedTeamId,
      year: int.parse(parsedMonth.group(1)!),
      month: int.parse(parsedMonth.group(2)!).clamp(1, 12),
      segment: resolvedSegment,
      sortField: sortField,
      sortDescending: sortDescending,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerDashboardFilters &&
        companyId == other.companyId &&
        teamId == other.teamId &&
        year == other.year &&
        month == other.month &&
        segment == other.segment &&
        sortField == other.sortField &&
        sortDescending == other.sortDescending;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    teamId,
    year,
    month,
    segment,
    sortField,
    sortDescending,
  );
}

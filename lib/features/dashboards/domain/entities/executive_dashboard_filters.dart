/// Filter state of the Executive Dashboard (TASK-134, EPIC-17): which
/// company, which team (optional) and which reference month the caller is
/// looking at — mirrored into the route's query parameters so a Flutter Web
/// reload/share link restores exactly the same view, same contract
/// `OpportunityCenterFilters`/`OrderListFilters` already set.
///
/// Deliberately month-granular (not an arbitrary date range): four of the
/// five aggregation dimensions TASK-133 pre-computes
/// (`customerMonthly`/`productMonthly`/`sellerMonthly`/`regionMonthly`) are
/// monthly snapshots, and the fifth (`salesDaily`) is read here as a
/// within-month range for the trend sparkline — so anchoring every filter to
/// a single calendar month lets every KPI reuse the exact snapshot grain
/// TASK-133 already writes, with no client-side re-bucketing of daily data
/// into arbitrary ranges.
final class ExecutiveDashboardFilters {
  const ExecutiveDashboardFilters({
    required this.companyId,
    this.teamId,
    required this.year,
    required this.month,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12.');

  /// Builds the filters for the current calendar month (UTC) — the landing
  /// default every caller sees before touching a filter.
  factory ExecutiveDashboardFilters.currentMonth({
    required String companyId,
    String? teamId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return ExecutiveDashboardFilters(
      companyId: companyId,
      teamId: teamId,
      year: reference.year,
      month: reference.month,
    );
  }

  final String companyId;

  /// `null` means "toda a empresa" (no team narrowing) — see
  /// `LoadExecutiveDashboardSnapshotUseCase`'s own docs for exactly which
  /// KPIs a team filter can/cannot narrow, given TASK-133 never modeled a
  /// `team` aggregation dimension.
  final String? teamId;

  final int year;
  final int month;

  /// `YYYY-MM`, the exact `periodKey` grain every monthly aggregation
  /// dimension (TASK-133) uses.
  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Inclusive start / exclusive end of [year]/[month], always UTC so every
  /// downstream `periodKey` comparison is timezone-stable.
  DateTime get periodStart => DateTime.utc(year, month);

  DateTime get periodEnd => DateTime.utc(year, month + 1);

  /// The same calendar month one year before — the "crescimento YoY"
  /// comparison period.
  ExecutiveDashboardFilters get previousYear => ExecutiveDashboardFilters(
    companyId: companyId,
    teamId: teamId,
    year: year - 1,
    month: month,
  );

  /// The immediately preceding calendar month — the "crescimento MoM"/
  /// "comparação com o período anterior" comparison period.
  ExecutiveDashboardFilters get previousMonth {
    final previous = DateTime.utc(year, month - 1);
    return ExecutiveDashboardFilters(
      companyId: companyId,
      teamId: teamId,
      year: previous.year,
      month: previous.month,
    );
  }

  /// Whether [year]/[month] is strictly after the month [now] falls in — the
  /// UI never lets the caller navigate the month picker into the future.
  bool isAfter(DateTime now) {
    final reference = now.toUtc();
    return year > reference.year ||
        (year == reference.year && month > reference.month);
  }

  ExecutiveDashboardFilters copyWith({
    String? companyId,
    String? teamId,
    bool clearTeamId = false,
    int? year,
    int? month,
  }) {
    return ExecutiveDashboardFilters(
      companyId: companyId ?? this.companyId,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same company/team/month on a Flutter Web reload/share link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      if (teamId != null && teamId!.trim().isNotEmpty) 'teamId': teamId!,
      'month': monthKey,
    };
  }

  factory ExecutiveDashboardFilters.fromQueryParameters(
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

    if (parsedMonth == null) {
      return ExecutiveDashboardFilters.currentMonth(
        companyId: (companyId == null || companyId.isEmpty)
            ? defaultCompanyId
            : companyId,
        teamId: (teamId == null || teamId.isEmpty) ? null : teamId,
        now: now,
      );
    }

    final year = int.parse(parsedMonth.group(1)!);
    final month = int.parse(parsedMonth.group(2)!);
    return ExecutiveDashboardFilters(
      companyId: (companyId == null || companyId.isEmpty)
          ? defaultCompanyId
          : companyId,
      teamId: (teamId == null || teamId.isEmpty) ? null : teamId,
      year: year,
      month: month.clamp(1, 12),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExecutiveDashboardFilters &&
        companyId == other.companyId &&
        teamId == other.teamId &&
        year == other.year &&
        month == other.month;
  }

  @override
  int get hashCode => Object.hash(companyId, teamId, year, month);
}

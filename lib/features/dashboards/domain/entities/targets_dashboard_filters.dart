final class TargetsDashboardFilters {
  const TargetsDashboardFilters({
    required this.companyId,
    required this.year,
    required this.month,
    this.teamId,
    this.sellerId,
  });

  final String companyId;
  final int year;
  final int month;
  final String? teamId;
  final String? sellerId;

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  DateTime get periodStart => DateTime.utc(year, month);
  DateTime get periodEnd => DateTime.utc(year, month + 1);

  Map<String, String> toQueryParameters() => <String, String>{
    'year': '$year',
    'month': '$month',
    'teamId': ?teamId,
    'sellerId': ?sellerId,
  };

  factory TargetsDashboardFilters.fromQueryParameters(
    Map<String, String> parameters, {
    required String fallbackCompanyId,
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).toUtc();
    final parsedMonth = int.tryParse(parameters['month'] ?? '');
    return TargetsDashboardFilters(
      companyId: fallbackCompanyId,
      year: int.tryParse(parameters['year'] ?? '') ?? today.year,
      month: parsedMonth != null && parsedMonth >= 1 && parsedMonth <= 12
          ? parsedMonth
          : today.month,
      teamId: parameters['teamId'],
      sellerId: parameters['sellerId'],
    );
  }

  TargetsDashboardFilters copyWith({
    String? companyId,
    int? year,
    int? month,
    String? teamId,
    bool clearTeamId = false,
    String? sellerId,
    bool clearSellerId = false,
  }) => TargetsDashboardFilters(
    companyId: companyId ?? this.companyId,
    year: year ?? this.year,
    month: month ?? this.month,
    teamId: clearTeamId ? null : teamId ?? this.teamId,
    sellerId: clearSellerId ? null : sellerId ?? this.sellerId,
  );
}

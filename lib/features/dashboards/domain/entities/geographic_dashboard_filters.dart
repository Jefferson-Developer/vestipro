final class GeographicDashboardFilters {
  const GeographicDashboardFilters({
    required this.companyId,
    required this.monthKey,
  });

  final String companyId;
  final String monthKey;

  Map<String, String> toQueryParameters() => <String, String>{
    'companyId': companyId,
    'month': monthKey,
  };

  factory GeographicDashboardFilters.fromQueryParameters(
    Map<String, String> query, {
    required String fallbackCompanyId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    final fallbackMonth =
        '${reference.year}-${reference.month.toString().padLeft(2, '0')}';
    final candidate = query['month'] ?? fallbackMonth;
    return GeographicDashboardFilters(
      companyId: query['companyId'] ?? fallbackCompanyId,
      monthKey: RegExp(r'^\d{4}-\d{2}$').hasMatch(candidate)
          ? candidate
          : fallbackMonth,
    );
  }
}

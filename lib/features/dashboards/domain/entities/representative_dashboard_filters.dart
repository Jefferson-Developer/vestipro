final class RepresentativeDashboardFilters {
  const RepresentativeDashboardFilters({
    required this.companyId,
    required this.sellerId,
    required this.year,
    required this.month,
  });

  final String companyId;
  final String sellerId;
  final int year;
  final int month;

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';
  DateTime get periodStart => DateTime.utc(year, month);
  DateTime get periodEnd => DateTime.utc(year, month + 1);

  Map<String, String> toQueryParameters() => <String, String>{
    'month': monthKey,
  };

  factory RepresentativeDashboardFilters.fromQueryParameters(
    Map<String, String> query, {
    required String defaultCompanyId,
    required String defaultSellerId,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final parts = query['month']?.split('-') ?? const <String>[];
    final parsedYear = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final parsedMonth = parts.length == 2 ? int.tryParse(parts[1]) : null;
    return RepresentativeDashboardFilters(
      companyId: defaultCompanyId,
      sellerId: defaultSellerId,
      year: parsedYear ?? current.year,
      month: parsedMonth != null && parsedMonth >= 1 && parsedMonth <= 12
          ? parsedMonth
          : current.month,
    );
  }

  RepresentativeDashboardFilters copyWith({
    String? companyId,
    String? sellerId,
    int? year,
    int? month,
  }) {
    return RepresentativeDashboardFilters(
      companyId: companyId ?? this.companyId,
      sellerId: sellerId ?? this.sellerId,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

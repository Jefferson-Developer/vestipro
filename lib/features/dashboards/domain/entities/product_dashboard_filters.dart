import '../value_objects/product_dashboard_sort_field.dart';

/// Filter/view state of the Product Dashboard (TASK-137, EPIC-17): which
/// company, which reference month, which coleção/categoria narrows the
/// ranking table (both optional, reusing the `collectionId`/`categoryId`
/// labels TASK-133's `productMonthly` dimension already denormalizes) and
/// which column/direction the ranking is sorted by — mirrored into the
/// route's query parameters so a Flutter Web reload/share link restores
/// exactly the same view, same contract `CustomerDashboardFilters`/
/// `SalesDashboardFilters` already set.
///
/// Deliberately no `teamId` (unlike `CustomerDashboardFilters`/
/// `SalesDashboardFilters`): `productMonthly` carries no seller/team label
/// at all, and no TASK-116/TASK-117-equivalent per-team product snapshot
/// exists to fall back on, so a team filter here would have literally
/// nothing to narrow — this task's own "nunca fabricar um filtro que não
/// filtra nada" precedent (see `CustomerDashboardFilters.teamId`'s own,
/// partial version of this same limitation).
///
/// Deliberately no `color`/`size` filter either: TASK-133's aggregation
/// layer aggregates `productMonthly` at the product level only — it carries
/// no variant/color/size dimension to filter by. Building one would require
/// a new server-side aggregation dimension, out of this task's scope
/// técnico (`AggregationRepository`'s own read-only contract). Documented in
/// `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`.
///
/// Deliberately month-granular for the exact same reason
/// `CustomerDashboardFilters`/`SalesDashboardFilters` already document:
/// `productMonthly` (TASK-133) is itself month-grained.
final class ProductDashboardFilters {
  const ProductDashboardFilters({
    required this.companyId,
    required this.year,
    required this.month,
    this.collectionId,
    this.categoryId,
    this.sortField = ProductDashboardSortField.quantitySold,
    this.sortDescending = true,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12.');

  /// Builds the filters for the current calendar month (UTC) — the landing
  /// default every caller sees before touching a filter.
  factory ProductDashboardFilters.currentMonth({
    required String companyId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return ProductDashboardFilters(
      companyId: companyId,
      year: reference.year,
      month: reference.month,
    );
  }

  final String companyId;
  final int year;
  final int month;

  /// Narrows the ranking table to products whose denormalized
  /// `AggregationSnapshot.labels['collectionId']` matches, `null` meaning
  /// "todas as coleções".
  final String? collectionId;

  /// Narrows the ranking table to products whose denormalized
  /// `AggregationSnapshot.labels['categoryId']` matches, `null` meaning
  /// "todas as categorias".
  final String? categoryId;

  final ProductDashboardSortField sortField;
  final bool sortDescending;

  /// `YYYY-MM`, the exact `periodKey` grain `productMonthly` (TASK-133)
  /// uses.
  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Inclusive start / exclusive end of [year]/[month], always UTC so every
  /// downstream `periodKey`/turnover-period comparison is timezone-stable.
  DateTime get periodStart => DateTime.utc(year, month);

  DateTime get periodEnd => DateTime.utc(year, month + 1);

  /// The immediately preceding calendar month.
  ProductDashboardFilters get previousMonth {
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

  ProductDashboardFilters copyWith({
    String? companyId,
    int? year,
    int? month,
    String? collectionId,
    bool clearCollectionId = false,
    String? categoryId,
    bool clearCategoryId = false,
    ProductDashboardSortField? sortField,
    bool? sortDescending,
  }) {
    return ProductDashboardFilters(
      companyId: companyId ?? this.companyId,
      year: year ?? this.year,
      month: month ?? this.month,
      collectionId: clearCollectionId
          ? null
          : (collectionId ?? this.collectionId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      sortField: sortField ?? this.sortField,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same company/month/coleção/categoria/sort on a Flutter Web
  /// reload/share link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      'month': monthKey,
      if (collectionId != null && collectionId!.trim().isNotEmpty)
        'collectionId': collectionId!,
      if (categoryId != null && categoryId!.trim().isNotEmpty)
        'categoryId': categoryId!,
      'sortBy': sortField.code,
      'sortDir': sortDescending ? 'desc' : 'asc',
    };
  }

  factory ProductDashboardFilters.fromQueryParameters(
    Map<String, String> queryParameters, {
    required String defaultCompanyId,
    DateTime? now,
  }) {
    final companyId = queryParameters['companyId']?.trim();
    final collectionId = queryParameters['collectionId']?.trim();
    final categoryId = queryParameters['categoryId']?.trim();
    final monthRaw = queryParameters['month']?.trim();
    final parsedMonth = monthRaw != null && monthRaw.isNotEmpty
        ? RegExp(r'^(\d{4})-(\d{2})$').firstMatch(monthRaw)
        : null;

    final resolvedCompanyId = (companyId == null || companyId.isEmpty)
        ? defaultCompanyId
        : companyId;
    final resolvedCollectionId = (collectionId == null || collectionId.isEmpty)
        ? null
        : collectionId;
    final resolvedCategoryId = (categoryId == null || categoryId.isEmpty)
        ? null
        : categoryId;
    final sortField = ProductDashboardSortFieldMapping.fromCode(
      queryParameters['sortBy'],
    );
    final sortDescending = queryParameters['sortDir'] != 'asc';

    if (parsedMonth == null) {
      final current = ProductDashboardFilters.currentMonth(
        companyId: resolvedCompanyId,
        now: now,
      );
      return current.copyWith(
        collectionId: resolvedCollectionId,
        categoryId: resolvedCategoryId,
        sortField: sortField,
        sortDescending: sortDescending,
      );
    }

    return ProductDashboardFilters(
      companyId: resolvedCompanyId,
      year: int.parse(parsedMonth.group(1)!),
      month: int.parse(parsedMonth.group(2)!).clamp(1, 12),
      collectionId: resolvedCollectionId,
      categoryId: resolvedCategoryId,
      sortField: sortField,
      sortDescending: sortDescending,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDashboardFilters &&
        companyId == other.companyId &&
        year == other.year &&
        month == other.month &&
        collectionId == other.collectionId &&
        categoryId == other.categoryId &&
        sortField == other.sortField &&
        sortDescending == other.sortDescending;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    year,
    month,
    collectionId,
    categoryId,
    sortField,
    sortDescending,
  );
}

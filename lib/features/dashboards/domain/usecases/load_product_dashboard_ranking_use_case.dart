import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../pricing/domain/entities/price_list.dart';
import '../../../pricing/domain/entities/price_list_item.dart';
import '../../../pricing/domain/repositories/price_list_item_repository.dart';
import '../../../pricing/domain/usecases/resolve_applicable_price_lists_use_case.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/product_dashboard_filters.dart';
import '../entities/product_dashboard_ranking_row.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';
import '../value_objects/product_dashboard_sort_field.dart';

/// Builds the Product Dashboard's ranking table (TASK-137, seção 12.1/12.3
/// de `tasks.md`: "análise de mix, giro e desempenho por produto") for one
/// [ProductDashboardFilters], reading exclusively from TASK-133's
/// [AggregationRepository] (`productMonthly`) — one bounded `listByPeriod`
/// read for the filtered month, never a raw `orders`/`products` scan (this
/// task's own "nunca calculada ad-hoc no cliente" rule).
///
/// **Regra de negócio: apenas produtos vigentes na tabela de preço ativa.**
/// Before filtering by [ProductDashboardFilters.collectionId]/`.categoryId`,
/// this use case restricts the `productMonthly` rows to the product ids
/// present in at least one company-wide [PriceList] currently applicable to
/// [ProductDashboardFilters.companyId] (resolved the same way
/// `ResolveApplicablePriceListsUseCase` already resolves for the pricing
/// engine, with no customer channel/segment narrowing — the broadest
/// "vigente para a empresa" set). **Best-effort, never blocking**: when no
/// Price List has been configured yet (a brand-new organization) or the
/// resolution/read fails, the restriction is skipped entirely rather than
/// zeroing out the whole ranking — same "um KPI/leitura falha e o resto
/// continua exibido" precedent every other EPIC-17 dashboard already sets
/// for a secondary, best-effort read.
///
/// **Mix por linha, calculado antes do filtro de coleção/categoria.**
/// [ProductDashboardRankingRow.mixPercentage] is each row's `revenueNet`
/// share of the *price-list-restricted* set's total — computed before
/// [ProductDashboardFilters.collectionId]/`.categoryId` narrows which rows
/// are returned, so "mix" always reads as "participação no faturamento
/// total da empresa no período", never a percentage relative to an
/// already-filtered subset (which would silently re-baseline to 100% once a
/// single coleção is selected).
@injectable
final class LoadProductDashboardRankingUseCase {
  const LoadProductDashboardRankingUseCase(
    this._aggregationRepository,
    this._resolveApplicablePriceLists,
    this._priceListItemRepository,
  );

  final AggregationRepository _aggregationRepository;
  final ResolveApplicablePriceListsUseCase _resolveApplicablePriceLists;
  final PriceListItemRepository _priceListItemRepository;

  /// Same bound `LoadSalesDashboardGroupRowsUseCase._rowLimit`/
  /// `LoadCustomerDashboardRankingUseCase._rowLimit` already accept for a
  /// single monthly aggregation read.
  static const int _rowLimit = 500;

  Future<AppResult<List<ProductDashboardRankingRow>>> call({
    required String organizationId,
    required ProductDashboardFilters filters,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = filters.companyId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<ProductDashboardRankingRow>>(
        ValidationFailure(
          'Invalid product dashboard ranking payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_dashboard_ranking_payload',
        ),
      );
    }

    final snapshotsResult = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: AggregationDimension.productMonthly,
      companyId: trimmedCompanyId,
      periodKey: filters.monthKey,
      limit: _rowLimit,
    );
    if (snapshotsResult case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      return AppFailure<List<ProductDashboardRankingRow>>(failure);
    }
    final allSnapshots =
        (snapshotsResult as AppSuccess<List<AggregationSnapshot>>).value;

    final activeProductIds = await _resolveActivePriceListProductIds(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
    );
    final restrictedSnapshots = activeProductIds == null
        ? allSnapshots
        : allSnapshots
              .where((snapshot) => activeProductIds.contains(snapshot.scopeId))
              .toList(growable: false);

    final totalRevenueNet = restrictedSnapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.revenueNet,
    );

    final normalizedCollectionId = filters.collectionId?.trim();
    final normalizedCategoryId = filters.categoryId?.trim();
    final filteredSnapshots = restrictedSnapshots.where((snapshot) {
      if (normalizedCollectionId != null &&
          normalizedCollectionId.isNotEmpty &&
          snapshot.labels['collectionId']?.trim() != normalizedCollectionId) {
        return false;
      }
      if (normalizedCategoryId != null &&
          normalizedCategoryId.isNotEmpty &&
          snapshot.labels['categoryId']?.trim() != normalizedCategoryId) {
        return false;
      }
      return true;
    });

    final rows = <ProductDashboardRankingRow>[
      for (final snapshot in filteredSnapshots)
        ProductDashboardRankingRow(
          productId: snapshot.scopeId,
          productName: snapshot.labels['productName']?.trim().isNotEmpty == true
              ? snapshot.labels['productName']!.trim()
              : snapshot.scopeId,
          categoryId: _nonEmpty(snapshot.labels['categoryId']),
          categoryName: _nonEmpty(snapshot.labels['categoryName']),
          collectionId: _nonEmpty(snapshot.labels['collectionId']),
          collectionName: _nonEmpty(snapshot.labels['collectionName']),
          quantitySold: snapshot.itemQuantity,
          revenueGross: snapshot.revenueGross,
          revenueNet: snapshot.revenueNet,
          discountAmount: snapshot.discountAmount,
          orderCount: snapshot.orderCount,
          mixPercentage: totalRevenueNet == 0
              ? 0
              : (snapshot.revenueNet / totalRevenueNet) * 100,
        ),
    ];

    return AppSuccess<List<ProductDashboardRankingRow>>(
      _sort(rows, field: filters.sortField, descending: filters.sortDescending),
    );
  }

  /// Union of product ids present in every currently-applicable,
  /// company-wide [PriceList] of [companyId] — `null` (never an empty set)
  /// when no restriction should be applied (see this class's own docs:
  /// no Price List configured yet, or the resolution/read failed).
  Future<Set<String>?> _resolveActivePriceListProductIds({
    required String organizationId,
    required String companyId,
  }) async {
    final priceListsResult = await _resolveApplicablePriceLists(
      organizationId: organizationId,
      companyId: companyId,
    );
    if (priceListsResult case AppFailure<List<PriceList>>()) return null;
    final priceLists = (priceListsResult as AppSuccess<List<PriceList>>).value;
    if (priceLists.isEmpty) return null;

    final productIds = <String>{};
    for (final priceList in priceLists) {
      final itemsResult = await _priceListItemRepository.listByPriceList(
        organizationId: organizationId,
        companyId: companyId,
        priceListId: priceList.id,
      );
      if (itemsResult case AppSuccess<List<PriceListItem>>(
        value: final items,
      )) {
        productIds.addAll(items.map((item) => item.productId));
      }
      // Best-effort: a failed read for one price list never blocks the
      // others, and never turns into a failure of the whole ranking.
    }
    return productIds.isEmpty ? null : productIds;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  List<ProductDashboardRankingRow> _sort(
    List<ProductDashboardRankingRow> rows, {
    required ProductDashboardSortField field,
    required bool descending,
  }) {
    final sorted = List<ProductDashboardRankingRow>.of(rows)
      ..sort((a, b) {
        final comparison = switch (field) {
          ProductDashboardSortField.quantitySold => a.quantitySold.compareTo(
            b.quantitySold,
          ),
          ProductDashboardSortField.revenue => a.revenueNet.compareTo(
            b.revenueNet,
          ),
          ProductDashboardSortField.mix => a.mixPercentage.compareTo(
            b.mixPercentage,
          ),
          ProductDashboardSortField.discount => a.discountPercentage.compareTo(
            b.discountPercentage,
          ),
        };
        return descending ? -comparison : comparison;
      });
    return sorted;
  }
}

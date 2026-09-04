import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_scope.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../../inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import '../../../inventory/domain/value_objects/stock_coverage_status.dart';
import '../../../inventory/domain/value_objects/stock_turnover_scope_type.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../entities/inventory_dashboard_filters.dart';
import '../entities/inventory_dashboard_stalled_product_page.dart';
import '../entities/inventory_dashboard_stalled_product_row.dart';

/// Builds one bounded page of "produtos parados" (TASK-139, seção 12.1 de
/// `tasks.md`: "produtos parados") — giro baixo e/ou cobertura acima do
/// `InventoryDashboardFilters.stalledCoverageDaysThreshold` configurável.
///
/// **Granularidade real: por produto, não por SKU/variante.** Enumera uma
/// página de `ProductRepository.listCatalog` (já filtrável por
/// `categoryId`/`collectionId`, TASK-082) e enriquece cada produto da página
/// — nunca o catálogo inteiro — com
/// [GetStockTurnoverMetricsUseCase]`(StockTurnoverScopeType.product)`,
/// exatamente o mesmo padrão limitado que `ProductDashboardBloc
/// ._enrichVisibleRows` (TASK-137) já usa para não disparar "centenas de
/// queries do cliente" (`tasks.md`, seção 22). Ver esse bloc's own doc para
/// a nota completa sobre por que esta é a única fonte de giro por produto
/// hoje realmente conectada a um repositório (o dataset de insight da
/// TASK-128 depende de um builder de produção que ainda não existe).
@injectable
final class LoadInventoryDashboardStalledProductsUseCase {
  const LoadInventoryDashboardStalledProductsUseCase(
    this._productRepository,
    this._getStockTurnoverMetrics,
  );

  final ProductRepository _productRepository;
  final GetStockTurnoverMetricsUseCase _getStockTurnoverMetrics;

  static const int _defaultLimit = 24;

  Future<AppResult<InventoryDashboardStalledProductPage>> call({
    required String organizationId,
    required InventoryDashboardFilters filters,
    String? cursor,
    int limit = _defaultLimit,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (filters.companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<InventoryDashboardStalledProductPage>(
        ValidationFailure(
          'Invalid stalled products request.',
          fieldErrors: fieldErrors,
          code: 'invalid_stalled_products_request',
        ),
      );
    }

    final catalogResult = await _productRepository.listCatalog(
      organizationId: trimmedOrganizationId,
      companyId: filters.companyId,
      cursor: cursor,
      limit: limit,
      filter: CatalogFilter(
        collectionId: filters.collectionId,
        categoryId: filters.categoryId,
      ),
    );
    if (catalogResult case AppFailure<ProductCatalogPage>(
      failure: final failure,
    )) {
      return AppFailure<InventoryDashboardStalledProductPage>(failure);
    }
    final catalogPage = (catalogResult as AppSuccess<ProductCatalogPage>).value;

    if (catalogPage.products.isEmpty) {
      return AppSuccess<InventoryDashboardStalledProductPage>(
        InventoryDashboardStalledProductPage(
          rows: const <InventoryDashboardStalledProductRow>[],
          hasMore: catalogPage.hasMore,
          nextCursor: catalogPage.nextCursor,
        ),
      );
    }

    final turnoverResults = await Future.wait(
      catalogPage.products.map(
        (product) => _getStockTurnoverMetrics(
          organizationId: trimmedOrganizationId,
          scope: StockTurnoverMetricScope(
            type: StockTurnoverScopeType.product,
            id: product.id,
          ),
          periodStart: filters.periodStart,
          periodEnd: filters.periodEnd,
        ),
      ),
    );

    final rows = <InventoryDashboardStalledProductRow>[];
    for (var i = 0; i < catalogPage.products.length; i++) {
      final product = catalogPage.products[i];
      final turnoverResult = turnoverResults[i];
      final snapshot = switch (turnoverResult) {
        AppSuccess<StockTurnoverMetricSnapshot?>(value: final value) => value,
        AppFailure<StockTurnoverMetricSnapshot?>() => null,
      };
      rows.add(_buildRow(product, snapshot, filters));
    }

    return AppSuccess<InventoryDashboardStalledProductPage>(
      InventoryDashboardStalledProductPage(
        rows: rows,
        hasMore: catalogPage.hasMore,
        nextCursor: catalogPage.nextCursor,
      ),
    );
  }

  InventoryDashboardStalledProductRow _buildRow(
    Product product,
    StockTurnoverMetricSnapshot? snapshot,
    InventoryDashboardFilters filters,
  ) {
    final photo = product.principalPhoto;
    final isStalled =
        snapshot != null &&
        snapshot.coverageStatus == StockCoverageStatus.ready &&
        snapshot.stockCoverageDays >= filters.stalledCoverageDaysThreshold;

    return InventoryDashboardStalledProductRow(
      productId: product.id,
      productName: product.name,
      imageUrl: photo?.thumbnailUrl ?? photo?.url,
      categoryId: product.categoryId,
      categoryName: null,
      turnoverSnapshot: snapshot,
      isStalled: isStalled,
    );
  }
}

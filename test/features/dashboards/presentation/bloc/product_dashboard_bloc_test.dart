import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_scope.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import 'package:vestipro/features/inventory/domain/repositories/stock_turnover_repository.dart';
import 'package:vestipro/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_coverage_status.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_turnover_scope_type.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/domain/entities/price_list.dart';
import 'package:vestipro/features/pricing/domain/repositories/price_list_item_repository.dart';
import 'package:vestipro/features/pricing/domain/repositories/price_list_repository.dart';
import 'package:vestipro/features/pricing/domain/usecases/resolve_applicable_price_lists_use_case.dart';
import 'package:vestipro/features/products/domain/entities/category.dart';
import 'package:vestipro/features/products/domain/entities/collection.dart';
import 'package:vestipro/features/products/domain/entities/product.dart';
import 'package:vestipro/features/products/domain/repositories/category_repository.dart';
import 'package:vestipro/features/products/domain/repositories/collection_repository.dart';
import 'package:vestipro/features/products/domain/repositories/product_repository.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockCompanyRepository extends Mock implements CompanyRepository {}

class _MockCollectionRepository extends Mock implements CollectionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAggregationRepository extends Mock
    implements AggregationRepository {}

class _MockPriceListRepository extends Mock implements PriceListRepository {}

class _MockPriceListItemRepository extends Mock
    implements PriceListItemRepository {}

class _MockStockTurnoverRepository extends Mock
    implements StockTurnoverRepository {}

class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late _MockCompanyRepository companyRepository;
  late _MockCollectionRepository collectionRepository;
  late _MockCategoryRepository categoryRepository;
  late _MockAggregationRepository aggregationRepository;
  late _MockPriceListRepository priceListRepository;
  late _MockPriceListItemRepository priceListItemRepository;
  late _MockStockTurnoverRepository stockTurnoverRepository;
  late _MockProductRepository productRepository;
  late FakeAnalyticsService analytics;

  setUpAll(() {
    registerFallbackValue(AggregationDimension.productMonthly);
    registerFallbackValue(
      const StockTurnoverMetricScope(
        type: StockTurnoverScopeType.product,
        id: 'fallback',
      ),
    );
  });

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    companyRepository = _MockCompanyRepository();
    collectionRepository = _MockCollectionRepository();
    categoryRepository = _MockCategoryRepository();
    aggregationRepository = _MockAggregationRepository();
    priceListRepository = _MockPriceListRepository();
    priceListItemRepository = _MockPriceListItemRepository();
    stockTurnoverRepository = _MockStockTurnoverRepository();
    productRepository = _MockProductRepository();
    analytics = FakeAnalyticsService();

    when(
      () => aggregationRepository.listByPeriod(
        organizationId: any(named: 'organizationId'),
        dimension: any(named: 'dimension'),
        companyId: any(named: 'companyId'),
        periodKey: any(named: 'periodKey'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[]),
    );
    when(() => collectionRepository.listByOrganization(any())).thenAnswer(
      (_) async => const AppSuccess<List<Collection>>(<Collection>[]),
    );
    when(
      () => categoryRepository.listByOrganization(any()),
    ).thenAnswer((_) async => const AppSuccess<List<Category>>(<Category>[]));
    when(
      () => priceListRepository.listByCompany(
        organizationId: any(named: 'organizationId'),
        companyId: any(named: 'companyId'),
      ),
    ).thenAnswer((_) async => const AppSuccess<List<PriceList>>(<PriceList>[]));
    when(
      () => stockTurnoverRepository.getByScopeAndPeriod(
        organizationId: any(named: 'organizationId'),
        scope: any(named: 'scope'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer(
      (_) async => const AppSuccess<StockTurnoverMetricSnapshot?>(null),
    );
    when(
      () => productRepository.getByIds(
        organizationId: any(named: 'organizationId'),
        ids: any(named: 'ids'),
      ),
    ).thenAnswer((_) async => const AppSuccess<List<Product>>(<Product>[]));
  });

  ProductDashboardBloc buildBloc() {
    return ProductDashboardBloc(
      ExecutiveDashboardVisibilityService(membershipRepository, teamRepository),
      LoadProductDashboardRankingUseCase(
        aggregationRepository,
        ResolveApplicablePriceListsUseCase(priceListRepository),
        priceListItemRepository,
      ),
      const BuildProductDashboardSnapshotUseCase(),
      companyRepository,
      collectionRepository,
      categoryRepository,
      GetStockTurnoverMetricsUseCase(stockTurnoverRepository),
      productRepository,
      analytics,
    );
  }

  void stubMembership(
    String userId,
    String roleName, {
    List<String> teamIds = const <String>[],
  }) {
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: userId,
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: userId,
          organizationId: 'org-1',
          userId: userId,
          roleId: roleName,
          roleName: roleName,
          teamIds: teamIds,
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
    );
  }

  Company companyOf(String id, String name) {
    final now = DateTime.utc(2026, 1, 1);
    return Company(
      id: id,
      organizationId: 'org-1',
      name: name,
      status: CompanyStatus.active,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
    );
  }

  void stubCompanies({List<Company> companies = const <Company>[]}) {
    when(
      () => companyRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => AppSuccess<List<Company>>(companies));
  }

  AggregationSnapshot productSnapshot(String productId, {int index = 0}) {
    return AggregationSnapshot(
      organizationId: 'org-1',
      companyId: 'company-1',
      dimension: AggregationDimension.productMonthly,
      scopeId: productId,
      periodKey: '2026-08',
      revenueGross: 100.0 - index,
      revenueNet: 100.0 - index,
      discountAmount: 0,
      orderCount: 1,
      itemQuantity: 1,
      labels: <String, String>{'productName': 'Produto $productId'},
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  const filters = ProductDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 8,
  );

  group('ProductDashboardBloc', () {
    blocTest<ProductDashboardBloc, ProductDashboardState>(
      'a role without report.viewSensitive resolves to forbidden — same '
      'documented gap the other EPIC-17 dashboards already carry',
      setUp: () {
        stubMembership('rep-1', 'SALES_REP');
        stubCompanies();
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ProductDashboardStarted(
          organizationId: 'org-1',
          userId: 'rep-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<ProductDashboardState>().having(
          (state) => state.status,
          'status',
          ProductDashboardStatus.loading,
        ),
        isA<ProductDashboardState>().having(
          (state) => state.visibilityFilter?.mode,
          'visibility mode',
          ExecutiveDashboardVisibilityMode.none,
        ),
        isA<ProductDashboardState>().having(
          (state) => state.status,
          'status',
          ProductDashboardStatus.forbidden,
        ),
      ],
    );

    blocTest<ProductDashboardBloc, ProductDashboardState>(
      'an OWNER reaches ready with KPI snapshot and ranking rows, and logs '
      'dashboard_viewed(type=product)',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompanies(companies: <Company>[companyOf('company-1', 'Marca A')]);
        when(
          () => aggregationRepository.listByPeriod(
            organizationId: any(named: 'organizationId'),
            dimension: AggregationDimension.productMonthly,
            companyId: any(named: 'companyId'),
            periodKey: '2026-08',
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<AggregationSnapshot>>(
            <AggregationSnapshot>[productSnapshot('product-a')],
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ProductDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(analytics.loggedEvents, isNotEmpty);
        final event = analytics.loggedEvents.last;
        expect(event.name, AnalyticsEvents.dashboardViewed);
        expect(event.parameters?['dashboard_type'], 'product');
        expect(event.parameters?['company_id'], 'company-1');
        expect(bloc.state.rankingStatus, ProductDashboardRankingStatus.ready);
        expect(bloc.state.rankingRows, hasLength(1));
        expect(bloc.state.snapshot?.quantitySold.value, 1);
        expect(bloc.state.snapshot?.margin.status, isNot(equals(null)));
      },
      expect: () => <Object>[
        isA<ProductDashboardState>(),
        isA<ProductDashboardState>(),
        isA<ProductDashboardState>(),
        isA<ProductDashboardState>().having(
          (state) => state.status,
          'status',
          ProductDashboardStatus.ready,
        ),
        isA<ProductDashboardState>().having(
          (state) => state.rankingStatus,
          'rankingStatus',
          ProductDashboardRankingStatus.ready,
        ),
      ],
    );

    blocTest<ProductDashboardBloc, ProductDashboardState>(
      'ranking pagination grows the visible window while preserving every '
      'row already loaded',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompanies(companies: <Company>[companyOf('company-1', 'Marca A')]);
      },
      build: buildBloc,
      seed: () => ProductDashboardState(
        status: ProductDashboardStatus.ready,
        organizationId: 'org-1',
        userId: 'owner-1',
        visibilityFilter: const ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
        filters: filters,
        rankingStatus: ProductDashboardRankingStatus.ready,
        rankingRows: <ProductDashboardRankingRow>[
          for (var i = 0; i < 45; i++)
            ProductDashboardRankingRow(
              productId: 'product-$i',
              productName: 'Produto $i',
              quantitySold: 1,
              revenueGross: 100,
              revenueNet: 100,
              discountAmount: 0,
              orderCount: 1,
              mixPercentage: 100 / 45,
            ),
        ],
      ),
      act: (bloc) => bloc.add(const ProductDashboardRankingPageRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.visibleRankingCount, 40);
        expect(bloc.state.visibleRankingRows, hasLength(40));
        expect(bloc.state.visibleRankingRows.first.productId, 'product-0');
      },
      expect: () => <Object>[
        isA<ProductDashboardState>().having(
          (state) => state.visibleRankingCount,
          'visibleRankingCount',
          40,
        ),
        isA<ProductDashboardState>(),
      ],
    );

    blocTest<ProductDashboardBloc, ProductDashboardState>(
      'a failure resolving companies surfaces the error state',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        when(() => companyRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => const AppFailure<List<Company>>(
            ServerFailure('boom', code: 'boom'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ProductDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<ProductDashboardState>(),
        isA<ProductDashboardState>(),
        isA<ProductDashboardState>().having(
          (state) => state.status,
          'status',
          ProductDashboardStatus.error,
        ),
      ],
    );

    blocTest<ProductDashboardBloc, ProductDashboardState>(
      'enriches visible rows with giro (TASK-094), reading the product-'
      'scoped GetStockTurnoverMetricsUseCase — the same canonical TASK-094 '
      'source `HighStockLowTurnoverInsightRule` is designed to eventually '
      'read from (see ProductDashboardBloc\'s own docs)',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompanies(companies: <Company>[companyOf('company-1', 'Marca A')]);
        when(
          () => aggregationRepository.listByPeriod(
            organizationId: any(named: 'organizationId'),
            dimension: AggregationDimension.productMonthly,
            companyId: any(named: 'companyId'),
            periodKey: '2026-08',
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<AggregationSnapshot>>(
            <AggregationSnapshot>[productSnapshot('product-a')],
          ),
        );
        when(
          () => stockTurnoverRepository.getByScopeAndPeriod(
            organizationId: any(named: 'organizationId'),
            scope: any(
              named: 'scope',
              that: isA<StockTurnoverMetricScope>()
                  .having(
                    (scope) => scope.type,
                    'type',
                    StockTurnoverScopeType.product,
                  )
                  .having((scope) => scope.id, 'id', 'product-a'),
            ),
            periodStart: any(named: 'periodStart'),
            periodEnd: any(named: 'periodEnd'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<StockTurnoverMetricSnapshot?>(
            StockTurnoverMetricSnapshot(
              organizationId: 'org-1',
              scopeType: StockTurnoverScopeType.product,
              scopeId: 'product-a',
              periodStart: DateTime.utc(2026, 8),
              periodEnd: DateTime.utc(2026, 9),
              coveredDays: 31,
              sellThroughRate: 0.5,
              stockCoverageDays: 10,
              turnoverRate: 2.5,
              openingStockQuantity: 10,
              receivedQuantity: 0,
              soldQuantity: 5,
              closingStockQuantity: 5,
              averageStockQuantity: 7.5,
              averageDailySalesQuantity: 0.16,
              coverageStatus: StockCoverageStatus.ready,
              generatedAt: DateTime.utc(2026, 8, 31),
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ProductDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.turnoverByProductId['product-a']?.turnoverRate, 2.5);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductGridPage', () {
    testWidgets('renders the first page and appends the next page on '
        '"carregar mais"', (tester) async {
      final repository = _ScriptedProductRepository(
        <String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[
                _buildProduct(id: 'product-1', name: 'Camisa Essential'),
              ],
              hasMore: true,
              nextCursor: 'product-1',
            ),
          ),
          'product-1': AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[
                _buildProduct(id: 'product-2', name: 'Calca Reta'),
              ],
              hasMore: false,
            ),
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProductGridPage(
            organizationId: 'org-1',
            createBloc: () => ProductGridBloc(
              listCatalogProducts: ListCatalogProductsUseCase(repository),
              getVariantAvailability: GetVariantAvailabilityUseCase(
                const _FakeVariantAvailabilityRepository(),
              ),
              analyticsService: FakeAnalyticsService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camisa Essential'), findsOneWidget);
      expect(find.text('Calca Reta'), findsNothing);

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(find.text('Camisa Essential'), findsOneWidget);
      expect(find.text('Calca Reta'), findsOneWidget);
    });

    testWidgets('logs product_viewed and forwards the tap when a card is '
        'opened', (tester) async {
      final repository = _ScriptedProductRepository(
        <String?, AppResult<ProductCatalogPage>>{
          null: AppSuccess<ProductCatalogPage>(
            ProductCatalogPage(
              products: <Product>[
                _buildProduct(id: 'product-1', name: 'Camisa Essential'),
              ],
              hasMore: false,
            ),
          ),
        },
      );
      final analyticsService = FakeAnalyticsService();
      Product? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProductGridPage(
            organizationId: 'org-1',
            createBloc: () => ProductGridBloc(
              listCatalogProducts: ListCatalogProductsUseCase(repository),
              getVariantAvailability: GetVariantAvailabilityUseCase(
                const _FakeVariantAvailabilityRepository(),
              ),
              analyticsService: analyticsService,
            ),
            onProductSelected: (product) => selected = product,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camisa Essential'));
      await tester.pumpAndSettle();

      expect(selected?.id, 'product-1');
      expect(
        analyticsService.loggedEvents
            .map((event) => event.name)
            .contains(AnalyticsEvents.productViewed),
        isTrue,
      );
    });

    testWidgets('shows the empty state when the catalog has no products', (
      tester,
    ) async {
      final repository =
          _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
            null: const AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(products: <Product>[], hasMore: false),
            ),
          });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProductGridPage(
            organizationId: 'org-1',
            createBloc: () => ProductGridBloc(
              listCatalogProducts: ListCatalogProductsUseCase(repository),
              getVariantAvailability: GetVariantAvailabilityUseCase(
                const _FakeVariantAvailabilityRepository(),
              ),
              analyticsService: FakeAnalyticsService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
    });
  });
}

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FakeVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }
}

final class _ScriptedProductRepository implements ProductRepository {
  _ScriptedProductRepository(this._pages);

  final Map<String?, AppResult<ProductCatalogPage>> _pages;

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) async {
    final result = _pages[cursor];
    if (result == null) {
      throw StateError('No scripted catalog page for cursor "$cursor".');
    }
    return result;
  }

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Product>> create({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> update({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) => throw UnimplementedError();
}

Product _buildProduct({required String id, required String name}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse('SKU-$id'),
    reference: 'REF-$id',
    name: name,
    status: ProductStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

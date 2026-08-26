import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('CatalogFilterPage', () {
    late _MockSessionService sessionService;

    setUp(() {
      sessionService = _MockSessionService();
      when(
        () => sessionService.currentUser,
      ).thenReturn(const SessionUser(uid: 'user-1', emailVerified: true));
    });

    CatalogFilterBloc buildBloc(_ScriptedProductRepository repository) {
      return CatalogFilterBloc(
        listCatalogProducts: ListCatalogProductsUseCase(repository),
        getVariantAvailability: GetVariantAvailabilityUseCase(
          const _EmptyVariantAvailabilityRepository(),
        ),
        listCollections: ListCollectionsUseCase(
          const _EmptyCollectionRepository(),
        ),
        listSeasons: ListSeasonsUseCase(const _EmptySeasonRepository()),
        listCategories: ListCategoriesUseCase(const _EmptyCategoryRepository()),
        listProductColors: ListProductColorsUseCase(
          const _EmptyProductColorRepository(),
        ),
        listSizeGridTemplates: ListSizeGridTemplatesUseCase(
          const _EmptySizeGridTemplateRepository(),
        ),
        loadCatalogPreferences: LoadCatalogPreferencesUseCase(
          _EmptyCatalogPreferencesRepository(),
        ),
        saveCatalogPreferences: SaveCatalogPreferencesUseCase(
          _EmptyCatalogPreferencesRepository(),
        ),
        analyticsService: FakeAnalyticsService(),
        sessionService: sessionService,
      );
    }

    Future<void> pumpAt(
      WidgetTester tester, {
      required double width,
      required _ScriptedProductRepository repository,
      CatalogFilter? initialFilter,
      void Function(CatalogViewMode, CatalogFilter)? onUrlStateChanged,
    }) async {
      final view = tester.view;
      view.physicalSize = Size(width + 100, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SizedBox(
            width: width,
            child: CatalogFilterPage(
              organizationId: 'org-1',
              createBloc: () => buildBloc(repository),
              initialFilter: initialFilter,
              onUrlStateChanged: onUrlStateChanged,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the first page of products (mobile)', (tester) async {
      await mockNetworkImagesFor(() async {
        final repository = _ScriptedProductRepository(
          <String?, AppResult<ProductCatalogPage>>{
            null: AppSuccess<ProductCatalogPage>(
              ProductCatalogPage(
                products: <Product>[_product(id: 'p1', name: 'Camisa')],
                hasMore: false,
              ),
            ),
          },
        );

        await pumpAt(tester, width: 375, repository: repository);

        expect(find.text('Camisa'), findsOneWidget);
      });
    });

    testWidgets(
      'mobile: filter button opens the filter panel in a bottom sheet',
      (tester) async {
        await mockNetworkImagesFor(() async {
          final repository = _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          );

          await pumpAt(tester, width: 375, repository: repository);

          expect(find.text('Aplicar filtros'), findsNothing);
          await tester.tap(find.byIcon(Icons.filter_list));
          await tester.pumpAndSettle();

          expect(find.text('Aplicar filtros'), findsOneWidget);
        });
      },
    );

    testWidgets('desktop: filter panel renders as a permanent side panel', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        final repository =
            _ScriptedProductRepository(<String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            });

        await pumpAt(tester, width: 1200, repository: repository);

        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.text('Aplicar filtros'), findsOneWidget);
      });
    });

    testWidgets(
      'shows a removable chip for the active filter and clears it on tap',
      (tester) async {
        await mockNetworkImagesFor(() async {
          final repository = _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          );

          await pumpAt(
            tester,
            width: 1200,
            repository: repository,
            initialFilter: const CatalogFilter(brand: 'Malwee'),
          );

          expect(find.text('Marca: Malwee'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();

          expect(find.text('Marca: Malwee'), findsNothing);
        });
      },
    );

    testWidgets(
      'notifies the host of every view mode/filter change (deep-link URL '
      'contract)',
      (tester) async {
        await mockNetworkImagesFor(() async {
          final repository = _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          );
          final urlUpdates = <(CatalogViewMode, CatalogFilter)>[];

          await pumpAt(
            tester,
            width: 1200,
            repository: repository,
            onUrlStateChanged: (mode, filter) => urlUpdates.add((mode, filter)),
          );

          await tester.tap(find.text('Lista'));
          await tester.pumpAndSettle();

          expect(
            urlUpdates.any((update) => update.$1 == CatalogViewMode.list),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'moves focus between filter panel fields with Tab (Web keyboard nav)',
      (tester) async {
        await mockNetworkImagesFor(() async {
          final repository = _ScriptedProductRepository(
            <String?, AppResult<ProductCatalogPage>>{
              null: const AppSuccess<ProductCatalogPage>(
                ProductCatalogPage(products: <Product>[], hasMore: false),
              ),
            },
          );

          await pumpAt(tester, width: 1200, repository: repository);

          // "Tags" and "Material/tecido" are two adjacent `AppTextField`s
          // in the filter panel (same guaranteed-focusable-via-Tab
          // precedent as the login page's e-mail -> senha fields).
          await tester.tap(find.bySemanticsLabel('Filtrar por tags'));
          await tester.pump();

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();

          final materialField = tester.widget<EditableText>(
            find.descendant(
              of: find.bySemanticsLabel('Filtrar por material ou tecido'),
              matching: find.byType(EditableText),
            ),
          );
          expect(materialField.focusNode.hasFocus, isTrue);
        });
      },
    );
  });
}

Product _product({required String id, String name = 'Produto'}) {
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

final class _EmptyVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _EmptyVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
}

final class _EmptyCollectionRepository implements CollectionRepository {
  const _EmptyCollectionRepository();

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Collection>>(<Collection>[]);

  @override
  Future<AppResult<Collection>> create({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> update({required Collection collection}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) => throw UnimplementedError();
}

final class _EmptySeasonRepository implements SeasonRepository {
  const _EmptySeasonRepository();

  @override
  Future<AppResult<List<Season>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Season>>(<Season>[]);

  @override
  Future<AppResult<Season>> create({required Season season}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Season>> update({required Season season}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Season>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasCollections({
    required String organizationId,
    required String seasonId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) => throw UnimplementedError();
}

final class _EmptyCategoryRepository implements CategoryRepository {
  const _EmptyCategoryRepository();

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<Category>>(<Category>[]);

  @override
  Future<AppResult<Category>> create({required Category category}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Category>> update({required Category category}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) => throw UnimplementedError();
}

final class _EmptyProductColorRepository implements ProductColorRepository {
  const _EmptyProductColorRepository();

  @override
  Future<AppResult<List<ProductColor>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<ProductColor>>(<ProductColor>[]);

  @override
  Future<AppResult<ProductColor>> create({required ProductColor color}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductColor>> update({required ProductColor color}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductColor>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> eanExists({
    required String organizationId,
    required Ean ean,
    String? excludingColorId,
  }) => throw UnimplementedError();
}

final class _EmptySizeGridTemplateRepository
    implements SizeGridTemplateRepository {
  const _EmptySizeGridTemplateRepository();

  @override
  Future<AppResult<List<SizeGridTemplate>>> listByOrganization(
    String organizationId,
  ) async => const AppSuccess<List<SizeGridTemplate>>(<SizeGridTemplate>[]);

  @override
  Future<AppResult<SizeGridTemplate>> create({
    required SizeGridTemplate template,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<SizeGridTemplate>> update({
    required SizeGridTemplate template,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<SizeGridTemplate>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> nameExists({
    required String organizationId,
    required String name,
    String? excludingTemplateId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> hasPublishedProductsUsingTemplate({
    required String organizationId,
    required String templateId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> sizeHasGeneratedVariants({
    required String organizationId,
    required String templateId,
    required String sizeId,
  }) => throw UnimplementedError();
}

final class _EmptyCatalogPreferencesRepository
    implements CatalogPreferencesRepository {
  @override
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  }) async => const AppSuccess<CatalogPreferences?>(null);

  @override
  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) async => const AppSuccess<void>(null);
}

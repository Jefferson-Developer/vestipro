import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/mappers/product_mapper.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_category_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesProductRepository', () {
    late SharedPreferencesProductRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPreferencesProductRepository(const ProductMapper());
    });

    test(
      'persists a created product as pending sync and reads it back',
      () async {
        final product = _product(
          seoTitle: 'Camisa Essential',
          ean: '4006381333931',
        );

        final createResult = await repository.create(product: product);
        final lookupResult = await repository.getById(
          organizationId: 'org-1',
          id: 'product-1',
        );

        expect(createResult, isA<AppSuccess<Product>>());
        expect(lookupResult, isA<AppSuccess<Product>>());
        final loaded = (lookupResult as AppSuccess<Product>).value;
        expect(loaded.syncStatus, ProductSyncStatus.pending);
        expect(loaded.seoTitle, 'Camisa Essential');
        expect(loaded.ean, Ean.parse('4006381333931'));
      },
    );

    test('blocks a duplicate SKU in the same organization', () async {
      await repository.create(product: _product());

      final duplicateResult = await repository.create(
        product: _product(id: 'product-2'),
      );

      expect(duplicateResult, isA<AppFailure<Product>>());
      expect(
        (duplicateResult as AppFailure<Product>).failure,
        isA<ConflictFailure>(),
      );
    });

    test('existsBySku excludes the product being updated', () async {
      await repository.create(product: _product());

      final excludingSelf = await repository.existsBySku(
        organizationId: 'org-1',
        sku: Sku.parse('CAMISA-001'),
        excludingProductId: 'product-1',
      );
      final withoutExcluding = await repository.existsBySku(
        organizationId: 'org-1',
        sku: Sku.parse('CAMISA-001'),
      );

      expect((excludingSelf as AppSuccess<bool>).value, isFalse);
      expect((withoutExcluding as AppSuccess<bool>).value, isTrue);
    });

    test('update fails for a product that was never created', () async {
      final result = await repository.update(product: _product());

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
    });

    test('getById fails for a product from a different organization', () async {
      await repository.create(product: _product());

      final result = await repository.getById(
        organizationId: 'org-2',
        id: 'product-1',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
    });

    test(
      'syncs a category/subcategory usage index so CategoryRepository can '
      'block deleting a Category still referenced by a Product (TASK-067)',
      () async {
        const categoryRepository = SharedPreferencesCategoryRepository();

        await repository.create(
          product: _product(categoryId: 'cat-1', subcategoryId: 'sub-1'),
        );

        final categoryInUse = await categoryRepository.hasProducts(
          organizationId: 'org-1',
          categoryId: 'cat-1',
        );
        final subcategoryInUse = await categoryRepository.hasProducts(
          organizationId: 'org-1',
          categoryId: 'sub-1',
        );
        final unrelatedNotInUse = await categoryRepository.hasProducts(
          organizationId: 'org-1',
          categoryId: 'cat-2',
        );

        expect((categoryInUse as AppSuccess<bool>).value, isTrue);
        expect((subcategoryInUse as AppSuccess<bool>).value, isTrue);
        expect((unrelatedNotInUse as AppSuccess<bool>).value, isFalse);
      },
    );

    test('removes a category from the usage index once no product references '
        'it anymore', () async {
      const categoryRepository = SharedPreferencesCategoryRepository();
      final product = _product(categoryId: 'cat-1');
      await repository.create(product: product);

      await repository.update(product: product.copyWith(categoryId: null));

      final stillInUse = await categoryRepository.hasProducts(
        organizationId: 'org-1',
        categoryId: 'cat-1',
      );
      expect((stillInUse as AppSuccess<bool>).value, isFalse);
    });

    group('listRecentlyLaunched', () {
      test('orders active products by launchDate, newest first', () async {
        final older = _product(id: 'product-older', sku: 'SKU-OLDER').copyWith(
          status: ProductStatus.active,
          launchDate: DateTime.utc(2026, 1, 1),
        );
        final newer = _product(id: 'product-newer', sku: 'SKU-NEWER').copyWith(
          status: ProductStatus.active,
          launchDate: DateTime.utc(2026, 6, 1),
        );
        await repository.create(product: older);
        await repository.create(product: newer);

        final result = await repository.listRecentlyLaunched(
          organizationId: 'org-1',
        );

        final products = (result as AppSuccess<List<Product>>).value;
        expect(products.map((p) => p.id).toList(), <String>[
          'product-newer',
          'product-older',
        ]);
      });

      test('excludes draft/inactive and soft-deleted products', () async {
        final active = _product(
          id: 'product-active',
          sku: 'SKU-ACTIVE',
        ).copyWith(status: ProductStatus.active);
        final draft = _product(id: 'product-draft', sku: 'SKU-DRAFT');
        final deleted = _product(id: 'product-deleted', sku: 'SKU-DELETED')
            .copyWith(
              status: ProductStatus.active,
              deletedAt: DateTime.utc(2026, 2, 1),
            );
        await repository.create(product: active);
        await repository.create(product: draft);
        await repository.create(product: deleted);

        final result = await repository.listRecentlyLaunched(
          organizationId: 'org-1',
        );

        final products = (result as AppSuccess<List<Product>>).value;
        expect(products.map((p) => p.id).toList(), <String>['product-active']);
      });

      test('caps the result at the requested limit', () async {
        for (var i = 0; i < 5; i++) {
          await repository.create(
            product: _product(id: 'product-$i', sku: 'SKU-$i').copyWith(
              status: ProductStatus.active,
              launchDate: DateTime.utc(2026, 1, 1 + i),
            ),
          );
        }

        final result = await repository.listRecentlyLaunched(
          organizationId: 'org-1',
          limit: 2,
        );

        final products = (result as AppSuccess<List<Product>>).value;
        expect(products, hasLength(2));
      });

      test(
        'includes company-scoped and organization-wide products for a given company',
        () async {
          final companyScoped = _product(
            id: 'product-company',
            sku: 'SKU-C',
          ).copyWith(status: ProductStatus.active, companyId: 'company-1');
          final orgWide = _product(
            id: 'product-org-wide',
            sku: 'SKU-O',
          ).copyWith(status: ProductStatus.active);
          final otherCompany = _product(
            id: 'product-other',
            sku: 'SKU-X',
          ).copyWith(status: ProductStatus.active, companyId: 'company-2');
          await repository.create(product: companyScoped);
          await repository.create(product: orgWide);
          await repository.create(product: otherCompany);

          final result = await repository.listRecentlyLaunched(
            organizationId: 'org-1',
            companyId: 'company-1',
          );

          final ids = (result as AppSuccess<List<Product>>).value
              .map((p) => p.id)
              .toSet();
          expect(ids, <String>{'product-company', 'product-org-wide'});
          expect(ids.contains('product-other'), isFalse);
        },
      );
    });

    group('listCatalog', () {
      test('orders active products by createdAt, newest first', () async {
        final older = _product(id: 'product-older', sku: 'SKU-OLDER').copyWith(
          status: ProductStatus.active,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final newer = _product(id: 'product-newer', sku: 'SKU-NEWER').copyWith(
          status: ProductStatus.active,
          createdAt: DateTime.utc(2026, 6, 1),
        );
        await repository.create(product: older);
        await repository.create(product: newer);

        final result = await repository.listCatalog(organizationId: 'org-1');

        final page = (result as AppSuccess<ProductCatalogPage>).value;
        expect(page.products.map((p) => p.id).toList(), <String>[
          'product-newer',
          'product-older',
        ]);
        expect(page.hasMore, isFalse);
        expect(page.nextCursor, isNull);
      });

      test('excludes draft/inactive and soft-deleted products', () async {
        final active = _product(
          id: 'product-active',
          sku: 'SKU-ACTIVE',
        ).copyWith(status: ProductStatus.active);
        final draft = _product(id: 'product-draft', sku: 'SKU-DRAFT');
        final deleted = _product(id: 'product-deleted', sku: 'SKU-DELETED')
            .copyWith(
              status: ProductStatus.active,
              deletedAt: DateTime.utc(2026, 2, 1),
            );
        await repository.create(product: active);
        await repository.create(product: draft);
        await repository.create(product: deleted);

        final result = await repository.listCatalog(organizationId: 'org-1');

        final page = (result as AppSuccess<ProductCatalogPage>).value;
        expect(page.products.map((p) => p.id).toList(), <String>[
          'product-active',
        ]);
      });

      test(
        'paginates with a cursor, never duplicating or skipping items',
        () async {
          for (var i = 0; i < 5; i++) {
            await repository.create(
              product: _product(id: 'product-$i', sku: 'SKU-$i').copyWith(
                status: ProductStatus.active,
                createdAt: DateTime.utc(2026, 1, 1 + i),
              ),
            );
          }
          // Newest first: product-4, product-3, product-2, product-1, product-0.

          final firstPage =
              (await repository.listCatalog(organizationId: 'org-1', limit: 2))
                  as AppSuccess<ProductCatalogPage>;
          expect(firstPage.value.products.map((p) => p.id).toList(), <String>[
            'product-4',
            'product-3',
          ]);
          expect(firstPage.value.hasMore, isTrue);
          expect(firstPage.value.nextCursor, 'product-3');

          final secondPage =
              (await repository.listCatalog(
                    organizationId: 'org-1',
                    limit: 2,
                    cursor: firstPage.value.nextCursor,
                  ))
                  as AppSuccess<ProductCatalogPage>;
          expect(secondPage.value.products.map((p) => p.id).toList(), <String>[
            'product-2',
            'product-1',
          ]);
          expect(secondPage.value.hasMore, isTrue);

          final thirdPage =
              (await repository.listCatalog(
                    organizationId: 'org-1',
                    limit: 2,
                    cursor: secondPage.value.nextCursor,
                  ))
                  as AppSuccess<ProductCatalogPage>;
          expect(thirdPage.value.products.map((p) => p.id).toList(), <String>[
            'product-0',
          ]);
          expect(thirdPage.value.hasMore, isFalse);
          expect(thirdPage.value.nextCursor, isNull);
        },
      );

      test(
        'restarts from the first page when the cursor no longer matches any product',
        () async {
          await repository.create(
            product: _product(
              id: 'product-1',
              sku: 'SKU-1',
            ).copyWith(status: ProductStatus.active),
          );

          final result = await repository.listCatalog(
            organizationId: 'org-1',
            cursor: 'does-not-exist',
          );

          final page = (result as AppSuccess<ProductCatalogPage>).value;
          expect(page.products.map((p) => p.id).toList(), <String>[
            'product-1',
          ]);
        },
      );

      test(
        'includes company-scoped and organization-wide products for a given company',
        () async {
          final companyScoped = _product(
            id: 'product-company',
            sku: 'SKU-C',
          ).copyWith(status: ProductStatus.active, companyId: 'company-1');
          final orgWide = _product(
            id: 'product-org-wide',
            sku: 'SKU-O',
          ).copyWith(status: ProductStatus.active);
          final otherCompany = _product(
            id: 'product-other',
            sku: 'SKU-X',
          ).copyWith(status: ProductStatus.active, companyId: 'company-2');
          await repository.create(product: companyScoped);
          await repository.create(product: orgWide);
          await repository.create(product: otherCompany);

          final result = await repository.listCatalog(
            organizationId: 'org-1',
            companyId: 'company-1',
          );

          final ids = (result as AppSuccess<ProductCatalogPage>).value.products
              .map((p) => p.id)
              .toSet();
          expect(ids, <String>{'product-company', 'product-org-wide'});
          expect(ids.contains('product-other'), isFalse);
        },
      );

      test(
        'returns an empty page with hasMore false when there is nothing to show',
        () async {
          final result = await repository.listCatalog(organizationId: 'org-1');

          final page = (result as AppSuccess<ProductCatalogPage>).value;
          expect(page.products, isEmpty);
          expect(page.hasMore, isFalse);
          expect(page.nextCursor, isNull);
        },
      );

      group('with a CatalogFilter (TASK-082)', () {
        test('narrows by a single dimension before pagination', () async {
          final matching = _product(
            id: 'product-match',
            sku: 'SKU-MATCH',
          ).copyWith(status: ProductStatus.active, collectionId: 'col-1');
          final other = _product(
            id: 'product-other',
            sku: 'SKU-OTHER',
          ).copyWith(status: ProductStatus.active, collectionId: 'col-2');
          await repository.create(product: matching);
          await repository.create(product: other);

          final result = await repository.listCatalog(
            organizationId: 'org-1',
            filter: const CatalogFilter(collectionId: 'col-1'),
          );

          final page = (result as AppSuccess<ProductCatalogPage>).value;
          expect(page.products.map((p) => p.id).toList(), <String>[
            'product-match',
          ]);
        });

        test(
          'combines multiple dimensions (AND across, OR within a set)',
          () async {
            final matching = _product(id: 'product-match', sku: 'SKU-MATCH')
                .copyWith(
                  status: ProductStatus.active,
                  collectionId: 'col-1',
                  brand: 'Malwee',
                  colorIds: const <String>['red', 'blue'],
                  tags: const <String>['casual'],
                );
            final wrongBrand =
                _product(id: 'product-wrong-brand', sku: 'SKU-WB').copyWith(
                  status: ProductStatus.active,
                  collectionId: 'col-1',
                  brand: 'OutraMarca',
                  colorIds: const <String>['red'],
                  tags: const <String>['casual'],
                );
            final wrongColor =
                _product(id: 'product-wrong-color', sku: 'SKU-WC').copyWith(
                  status: ProductStatus.active,
                  collectionId: 'col-1',
                  brand: 'Malwee',
                  colorIds: const <String>['green'],
                  tags: const <String>['casual'],
                );
            await repository.create(product: matching);
            await repository.create(product: wrongBrand);
            await repository.create(product: wrongColor);

            final result = await repository.listCatalog(
              organizationId: 'org-1',
              filter: const CatalogFilter(
                collectionId: 'col-1',
                brand: 'malwee',
                colorIds: <String>{'red', 'yellow'},
                tags: <String>{'casual', 'formal'},
              ),
            );

            final page = (result as AppSuccess<ProductCatalogPage>).value;
            expect(page.products.map((p) => p.id).toList(), <String>[
              'product-match',
            ]);
          },
        );

        test(
          'returns an empty (never broken) page for a combination with no match',
          () async {
            final product = _product(
              id: 'product-1',
              sku: 'SKU-1',
            ).copyWith(status: ProductStatus.active, brand: 'Malwee');
            await repository.create(product: product);

            final result = await repository.listCatalog(
              organizationId: 'org-1',
              filter: const CatalogFilter(brand: 'Inexistente'),
            );

            final page = (result as AppSuccess<ProductCatalogPage>).value;
            expect(page.products, isEmpty);
            expect(page.hasMore, isFalse);
          },
        );

        test(
          'launchOnly ranks by launchDate (newest first), like listRecentlyLaunched',
          () async {
            final noLaunchDate =
                _product(id: 'product-no-launch', sku: 'SKU-NL').copyWith(
                  status: ProductStatus.active,
                  createdAt: DateTime.utc(2026, 5, 1),
                );
            final olderLaunch =
                _product(id: 'product-older-launch', sku: 'SKU-OL').copyWith(
                  status: ProductStatus.active,
                  launchDate: DateTime.utc(2026, 1, 1),
                );
            final newerLaunch =
                _product(id: 'product-newer-launch', sku: 'SKU-NEL').copyWith(
                  status: ProductStatus.active,
                  launchDate: DateTime.utc(2026, 6, 1),
                );
            await repository.create(product: noLaunchDate);
            await repository.create(product: olderLaunch);
            await repository.create(product: newerLaunch);

            final result = await repository.listCatalog(
              organizationId: 'org-1',
              filter: const CatalogFilter(launchOnly: true),
            );

            final page = (result as AppSuccess<ProductCatalogPage>).value;
            expect(page.products.map((p) => p.id).toList(), <String>[
              'product-newer-launch',
              'product-older-launch',
            ]);
          },
        );

        test('material matches Product.fabric case-insensitively', () async {
          final matching = _product(
            id: 'product-match',
            sku: 'SKU-MATCH',
          ).copyWith(status: ProductStatus.active, fabric: 'Algodão Pima');
          final other = _product(
            id: 'product-other',
            sku: 'SKU-OTHER',
          ).copyWith(status: ProductStatus.active, fabric: 'Poliéster');
          await repository.create(product: matching);
          await repository.create(product: other);

          final result = await repository.listCatalog(
            organizationId: 'org-1',
            filter: const CatalogFilter(material: 'algodão'),
          );

          final page = (result as AppSuccess<ProductCatalogPage>).value;
          expect(page.products.map((p) => p.id).toList(), <String>[
            'product-match',
          ]);
        });
      });
    });
  });
}

Product _product({
  String id = 'product-1',
  String sku = 'CAMISA-001',
  String? seoTitle,
  String? ean,
  String? categoryId,
  String? subcategoryId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse(sku),
    reference: 'REF-$id',
    name: 'Produto $id',
    ean: ean == null ? null : Ean.parse(ean),
    seoTitle: seoTitle,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    status: ProductStatus.draft,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}

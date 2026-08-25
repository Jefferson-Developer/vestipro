import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/features/products/data/datasources/drift_product_local_search_index_data_source.dart';
import 'package:vestipro/features/products/data/mappers/product_mapper.dart';
import 'package:vestipro/features/products/data/mappers/product_search_index_mapper.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('DriftProductLocalSearchIndexDataSource', () {
    late AppDatabase database;
    late DriftProductLocalSearchIndexDataSource dataSource;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      dataSource = DriftProductLocalSearchIndexDataSource(
        database,
        const ProductSearchIndexMapper(ProductMapper()),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('searches by normalized name, SKU, reference, EAN and tags', () async {
      final product = buildTestProduct(
        id: 'product-1',
        name: 'Camisa Básica',
        sku: 'CAM-BAS-001',
        reference: 'REF-VERAO',
        ean: '7891234567895',
        tags: const <String>['Pré-venda'],
      );
      await dataSource.replaceProducts(
        organizationId: 'org-1',
        products: <Product>[product],
      );

      expect(await _idsFor(dataSource, 'org-1', 'basica'), <String>[
        'product-1',
      ]);
      expect(await _idsFor(dataSource, 'org-1', 'cam-bas'), <String>[
        'product-1',
      ]);
      expect(await _idsFor(dataSource, 'org-1', 'verao'), <String>[
        'product-1',
      ]);
      expect(await _idsFor(dataSource, 'org-1', '7891234567895'), <String>[
        'product-1',
      ]);
      expect(await _idsFor(dataSource, 'org-1', 'pre venda'), <String>[
        'product-1',
      ]);
    });

    test('keeps offline search isolated by organization', () async {
      await dataSource.replaceProducts(
        organizationId: 'org-1',
        products: <Product>[
          buildTestProduct(id: 'product-1', name: 'Jaqueta Linho'),
        ],
      );
      await dataSource.replaceProducts(
        organizationId: 'org-2',
        products: <Product>[
          buildTestProduct(
            id: 'product-2',
            organizationId: 'org-2',
            name: 'Jaqueta Linho',
          ),
        ],
      );

      expect(await _idsFor(dataSource, 'org-1', 'linho'), <String>[
        'product-1',
      ]);
      expect(await _idsFor(dataSource, 'org-2', 'linho'), <String>[
        'product-2',
      ]);

      await dataSource.replaceProducts(
        organizationId: 'org-1',
        products: const <Product>[],
      );

      expect(await _idsFor(dataSource, 'org-1', 'linho'), isEmpty);
      expect(await _idsFor(dataSource, 'org-2', 'linho'), <String>[
        'product-2',
      ]);
    });
  });
}

Future<List<String>> _idsFor(
  DriftProductLocalSearchIndexDataSource dataSource,
  String organizationId,
  String query,
) async {
  final products = await dataSource.searchProducts(
    organizationId: organizationId,
    normalizedQuery: ProductSearchNormalizer.normalize(query),
  );
  return products.map((product) => product.id).toList(growable: false);
}

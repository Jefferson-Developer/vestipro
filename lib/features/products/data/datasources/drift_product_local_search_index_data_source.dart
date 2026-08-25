import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/product.dart';
import '../mappers/product_search_index_mapper.dart';
import 'product_local_search_index_data_source.dart';

@LazySingleton(as: ProductLocalSearchIndexDataSource)
final class DriftProductLocalSearchIndexDataSource
    implements ProductLocalSearchIndexDataSource {
  const DriftProductLocalSearchIndexDataSource(this._database, this._mapper);

  final AppDatabase _database;
  final ProductSearchIndexMapper _mapper;

  @override
  Future<void> replaceProducts({
    required String organizationId,
    required List<Product> products,
  }) {
    return _database.replaceProductSearchIndex(
      organizationId: organizationId,
      productRows: products.map(_mapper.toRow).toList(growable: false),
    );
  }

  @override
  Future<void> upsertProduct({required Product product}) {
    return _database.upsertProductSearchIndex(
      productRow: _mapper.toRow(product),
    );
  }

  @override
  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  }) async {
    final rows = await _database.searchProductIndex(
      organizationId: organizationId,
      normalizedQuery: normalizedQuery,
      limit: limit,
    );
    return rows
        .map((row) => _mapper.fromRow(row.product))
        .toList(growable: false);
  }
}

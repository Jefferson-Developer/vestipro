import '../../domain/entities/product.dart';

abstract interface class ProductLocalSearchIndexDataSource {
  Future<void> replaceProducts({
    required String organizationId,
    required List<Product> products,
  });

  Future<void> upsertProduct({required Product product});

  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  });
}

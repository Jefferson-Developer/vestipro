import '../../domain/entities/product.dart';

abstract interface class ProductRemoteSearchDataSource {
  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  });
}

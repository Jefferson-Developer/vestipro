import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('UpdateProductMediaUseCase', () {
    late _InMemoryProductRepository repository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late UpdateProductMediaUseCase useCase;

    setUp(() {
      repository = _InMemoryProductRepository();
      auditLogRepository = _InMemoryAuditLogRepository();
      useCase = UpdateProductMediaUseCase(repository, auditLogRepository);
    });

    test(
      'replaces the media list of a draft product without an audit entry',
      () async {
        repository.seed(_buildProduct(id: 'product-1'));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'product-1',
          media: const <ProductMedia>[
            ProductMedia(
              id: 'a.jpg',
              type: ProductMediaType.photo,
              url: 'https://cdn.example.com/a.jpg',
              order: 0,
              principal: true,
            ),
          ],
          updatedBy: 'user-2',
          actorName: 'Ana Souza',
        );

        expect(result, isA<AppSuccess<Product>>());
        final product = (result as AppSuccess<Product>).value;
        expect(product.media, hasLength(1));
        expect(product.hasPrincipalPhoto, isTrue);
        expect(product.version, 2);
        expect(product.syncStatus, ProductSyncStatus.pending);
        expect(auditLogRepository.entries, isEmpty);
      },
    );

    test('records an audit entry (mediaCount/principalPhotoId) when the '
        'product was already published', () async {
      repository.seed(
        _buildProduct(id: 'product-1', status: ProductStatus.active),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'product-1',
        media: const <ProductMedia>[
          ProductMedia(
            id: 'a.jpg',
            type: ProductMediaType.photo,
            url: 'https://cdn.example.com/a.jpg',
            order: 0,
            principal: true,
          ),
        ],
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppSuccess<Product>>());
      expect(auditLogRepository.entries, hasLength(1));
      final entry = auditLogRepository.entries.single;
      expect(entry.action, AuditAction.productUpdated);
      expect(entry.previousValue?['mediaCount'], 0);
      expect(entry.newValue?['mediaCount'], 1);
      expect(entry.newValue?['principalPhotoId'], 'a.jpg');
    });

    test('fails when the product does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing',
        media: const <ProductMedia>[],
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
    });

    test(
      'rejects an empty updatedBy without touching the repository',
      () async {
        repository.seed(_buildProduct(id: 'product-1'));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'product-1',
          media: const <ProductMedia>[],
          updatedBy: '   ',
          actorName: 'Ana Souza',
        );

        expect(result, isA<AppFailure<Product>>());
        expect(
          (result as AppFailure<Product>).failure,
          isA<ValidationFailure>(),
        );
        expect(repository.products.single.version, 1);
      },
    );
  });
}

Product _buildProduct({
  required String id,
  String organizationId = 'org-1',
  ProductStatus status = ProductStatus.draft,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: organizationId,
    sku: Sku.parse('CAMISA-001'),
    reference: 'REF-$id',
    name: 'Produto $id',
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}

final class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

  void seed(Product product) => products.add(product);

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async {
    return AppSuccess<bool>(false);
  }

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    products.add(product);
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      return const AppFailure<Product>(
        NotFoundFailure('Product not found.', code: 'product_not_found'),
      );
    }
    products[index] = product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final product in products) {
      if (product.organizationId == organizationId && product.id == id) {
        return AppSuccess<Product>(product);
      }
    }
    return const AppFailure<Product>(
      NotFoundFailure('Product not found.', code: 'product_not_found'),
    );
  }

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    final wanted = ids.toSet();
    return AppSuccess<List<Product>>(
      products
          .where(
            (product) =>
                product.organizationId == organizationId &&
                wanted.contains(product.id),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) async {
    return const AppSuccess<List<Product>>(<Product>[]);
  }

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
  }) async {
    return const AppSuccess<ProductCatalogPage>(
      ProductCatalogPage(products: <Product>[], hasMore: false),
    );
  }
}

final class _InMemoryAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> entries = <AuditLogEntry>[];

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    entries.add(entry);
    return AppSuccess<AuditLogEntry>(entry);
  }

  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  }) async {
    return AppSuccess<List<AuditLogEntry>>(
      entries.where((entry) => entry.organizationId == organizationId).toList(),
    );
  }

  @override
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) async {
    return const AppSuccess<AuditLogEntryPage>(
      AuditLogEntryPage(entries: <AuditLogEntry>[], hasMore: false),
    );
  }
}

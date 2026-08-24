import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('UpdateProductUseCase', () {
    late _InMemoryProductRepository repository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late UpdateProductUseCase useCase;

    setUp(() {
      repository = _InMemoryProductRepository();
      auditLogRepository = _InMemoryAuditLogRepository();
      useCase = UpdateProductUseCase(repository, auditLogRepository);
    });

    test('updates a draft product without recording any audit entry', () async {
      repository.seed(_buildProduct(id: 'product-1', sku: 'CAMISA-001'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'product-1',
        sku: 'CAMISA-001',
        reference: 'REF-001-B',
        name: 'Camisa Essential Atualizada',
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppSuccess<Product>>());
      final product = (result as AppSuccess<Product>).value;
      expect(product.reference, 'REF-001-B');
      expect(product.version, 2);
      expect(product.syncStatus, ProductSyncStatus.pending);
      expect(auditLogRepository.entries, isEmpty);
    });

    test('records an audit entry with the changed fields when the product was '
        'already published', () async {
      repository.seed(
        _buildProduct(
          id: 'product-1',
          sku: 'CAMISA-001',
          status: ProductStatus.active,
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'product-1',
        sku: 'CAMISA-002',
        reference: 'REF-product-1',
        name: 'Produto product-1',
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppSuccess<Product>>());
      expect(auditLogRepository.entries, hasLength(1));
      final entry = auditLogRepository.entries.single;
      expect(entry.action, AuditAction.productUpdated);
      expect(entry.entityType, 'product');
      expect(entry.entityId, 'product-1');
      expect(entry.previousValue?['sku'], 'CAMISA-001');
      expect(entry.newValue?['sku'], 'CAMISA-002');
      expect(entry.actorName, 'Ana Souza');
    });

    test(
      'does not record an audit entry when nothing tracked changed',
      () async {
        repository.seed(
          _buildProduct(
            id: 'product-1',
            sku: 'CAMISA-001',
            status: ProductStatus.active,
          ),
        );

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'product-1',
          sku: 'CAMISA-001',
          reference: 'REF-product-1',
          name: 'Produto product-1',
          updatedBy: 'user-2',
          actorName: 'Ana Souza',
        );

        expect(result, isA<AppSuccess<Product>>());
        expect(auditLogRepository.entries, isEmpty);
      },
    );

    test('blocks a duplicate SKU owned by a different product', () async {
      repository.seed(_buildProduct(id: 'product-1', sku: 'CAMISA-001'));
      repository.seed(_buildProduct(id: 'product-2', sku: 'CAMISA-002'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'product-1',
        sku: 'CAMISA-002',
        reference: 'REF-product-1',
        name: 'Produto product-1',
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<ConflictFailure>());
    });

    test('fails when the product does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing',
        sku: 'CAMISA-001',
        reference: 'REF-001',
        name: 'Produto',
        updatedBy: 'user-2',
        actorName: 'Ana Souza',
      );

      expect(result, isA<AppFailure<Product>>());
      expect((result as AppFailure<Product>).failure, isA<NotFoundFailure>());
    });
  });
}

Product _buildProduct({
  required String id,
  required String sku,
  String organizationId = 'org-1',
  ProductStatus status = ProductStatus.draft,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: organizationId,
    sku: Sku.parse(sku),
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
    return AppSuccess<bool>(
      products.any(
        (product) =>
            product.organizationId == organizationId &&
            product.sku == sku &&
            product.id != excludingProductId,
      ),
    );
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

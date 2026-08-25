import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

const _photoA = ProductMedia(
  id: 'a.jpg',
  type: ProductMediaType.photo,
  url: 'https://cdn.example.com/a.jpg',
  order: 0,
  principal: true,
);
const _photoB = ProductMedia(
  id: 'b.jpg',
  type: ProductMediaType.photo,
  url: 'https://cdn.example.com/b.jpg',
  order: 1,
);

void main() {
  group('ProductMediaGallerySection', () {
    late _InMemoryProductRepository productRepository;
    late _InMemoryAuditLogRepository auditLogRepository;

    setUp(() {
      productRepository = _InMemoryProductRepository()
        ..seed(
          _buildProduct(
            id: 'product-1',
            media: const <ProductMedia>[_photoA, _photoB],
          ),
        );
      auditLogRepository = _InMemoryAuditLogRepository();
    });

    ProductMediaBloc buildBloc() {
      return ProductMediaBloc(
        storage: _NoopStorageDataSource(),
        updateMedia: UpdateProductMediaUseCase(
          productRepository,
          auditLogRepository,
        ),
        featureFlagService: FakeFeatureFlagService(),
        analyticsService: FakeAnalyticsService(),
      );
    }

    /// Forces the mobile breakpoint (`AppBreakpoints.tablet` starts at 600),
    /// so the gallery renders explicit "mover para cima/baixo" buttons
    /// instead of a `ReorderableListView` drag handle — the same widget-test
    /// convention `CategoriesPage`'s own reorder test already uses, since a
    /// drag gesture is not easily simulated in a widget test.
    void setMobileWidth(WidgetTester tester) {
      final view = tester.view;
      view.physicalSize = const Size(360, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
    }

    Widget buildSection(ProductMediaBloc bloc) {
      return BlocProvider<ProductMediaBloc>(
        create: (_) => bloc
          ..add(
            const ProductMediaStarted(
              organizationId: 'org-1',
              productId: 'product-1',
              updatedBy: 'user-2',
              actorName: 'Ana Souza',
              initialMedia: <ProductMedia>[_photoA, _photoB],
            ),
          ),
        child: const ProductMediaGallerySection(),
      );
    }

    testWidgets('renders every photo and marks the principal one', (
      tester,
    ) async {
      setMobileWidth(tester);
      await mockNetworkImagesFor(() async {
        await pumpApp(tester, buildSection(buildBloc()));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsOneWidget);
        expect(find.text('Principal'), findsOneWidget);
      });
    });

    testWidgets(
      'setting a different photo as principal updates the gallery and '
      'persists it',
      (tester) async {
        setMobileWidth(tester);
        await mockNetworkImagesFor(() async {
          await pumpApp(tester, buildSection(buildBloc()));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.star_border));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.star), findsOneWidget);
          expect(find.byIcon(Icons.star_border), findsOneWidget);

          final updated = await productRepository.getById(
            organizationId: 'org-1',
            id: 'product-1',
          );
          final product = (updated as AppSuccess<Product>).value;
          expect(product.principalPhoto?.id, 'b.jpg');
        });
      },
    );

    testWidgets(
      'reordering with the explicit "mover para baixo" action persists the '
      'new order — never a drag gesture on mobile',
      (tester) async {
        setMobileWidth(tester);
        await mockNetworkImagesFor(() async {
          await pumpApp(tester, buildSection(buildBloc()));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.drag_indicator), findsNothing);

          await tester.tap(find.byIcon(Icons.arrow_downward).first);
          await tester.pumpAndSettle();

          final updated = await productRepository.getById(
            organizationId: 'org-1',
            id: 'product-1',
          );
          final product = (updated as AppSuccess<Product>).value;
          expect(product.photos.map((item) => item.id).toList(), <String>[
            'b.jpg',
            'a.jpg',
          ]);
        });
      },
    );
  });
}

Product _buildProduct({
  required String id,
  List<ProductMedia> media = const <ProductMedia>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: 'org-1',
    sku: Sku.parse('CAMISA-001'),
    reference: 'REF-$id',
    name: 'Produto $id',
    status: ProductStatus.draft,
    media: media,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}

/// `ProductMediaGallerySection` never triggers an upload in these tests
/// (only reorder/set-principal), so this fake only needs to satisfy the
/// `StorageDataSource` contract, never actually invoked.
final class _NoopStorageDataSource implements StorageDataSource {
  @override
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(StorageUploadProgress progress)? onProgress,
    StorageUploadCancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> getDownloadUrl({required String path}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteFile({required String path}) async {}
}

final class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

  void seed(Product product) {
    products
      ..removeWhere((existing) => existing.id == product.id)
      ..add(product);
  }

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

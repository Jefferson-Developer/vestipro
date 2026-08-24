import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/products/products.dart';

class _MockStorageDataSource extends Mock implements StorageDataSource {}

class _MockImageCompressor extends Mock implements ImageCompressor {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('ProductMediaBloc', () {
    late _MockStorageDataSource storage;
    late _MockImageCompressor thumbnailCompressor;
    late _InMemoryProductRepository productRepository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late FakeFeatureFlagService featureFlagService;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      storage = _MockStorageDataSource();
      thumbnailCompressor = _MockImageCompressor();
      productRepository = _InMemoryProductRepository()
        ..seed(_buildProduct(id: 'product-1'));
      auditLogRepository = _InMemoryAuditLogRepository();
      featureFlagService = FakeFeatureFlagService();
      analyticsService = FakeAnalyticsService();

      when(
        () => thumbnailCompressor.compress(
          any(),
          minWidth: any(named: 'minWidth'),
          minHeight: any(named: 'minHeight'),
          quality: any(named: 'quality'),
        ),
      ).thenAnswer((_) async => Uint8List.fromList(<int>[9, 9, 9]));

      when(
        () => storage.uploadFile(
          path: any(named: 'path'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final path = invocation.namedArguments[#path] as String;
        return 'https://storage.test/$path';
      });

      when(
        () => storage.deleteFile(path: any(named: 'path')),
      ).thenAnswer((_) async {});
    });

    ProductMediaBloc buildBloc() {
      return ProductMediaBloc(
        storage: storage,
        thumbnailCompressor: thumbnailCompressor,
        updateMedia: UpdateProductMediaUseCase(
          productRepository,
          auditLogRepository,
        ),
        featureFlagService: featureFlagService,
        analyticsService: analyticsService,
      );
    }

    ProductMediaBloc startedBloc({
      List<ProductMedia> initialMedia = const <ProductMedia>[],
    }) {
      return buildBloc()..add(
        ProductMediaStarted(
          organizationId: 'org-1',
          productId: 'product-1',
          updatedBy: 'user-2',
          actorName: 'Ana Souza',
          initialMedia: initialMedia,
        ),
      );
    }

    test(
      'uploads a photo, generates a thumbnail and persists it as principal',
      () async {
        final bloc = startedBloc();
        await _drainBloc();

        bloc.add(
          ProductMediaPhotoPicked(bytes: Uint8List.fromList(<int>[1, 2, 3])),
        );
        await _drainBloc();

        expect(bloc.state.uploads, isEmpty);
        expect(bloc.state.photos, hasLength(1));
        expect(bloc.state.photos.single.principal, isTrue);
        expect(bloc.state.photos.single.thumbnailUrl, isNotNull);
        expect(bloc.state.failure, isNull);
        verify(
          () => storage.uploadFile(
            path: any(named: 'path'),
            bytes: any(named: 'bytes'),
            contentType: 'image/jpeg',
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2); // main photo + thumbnail
        verify(
          () => thumbnailCompressor.compress(
            any(),
            minWidth: any(named: 'minWidth'),
            minHeight: any(named: 'minHeight'),
            quality: any(named: 'quality'),
          ),
        ).called(1);
        expect(
          analyticsService.loggedEvents
              .map((event) => event.name)
              .contains(AnalyticsEvents.productMediaUpdated),
          isTrue,
        );

        await bloc.close();
      },
    );

    test(
      'rejects a video over the configured duration limit before uploading',
      () async {
        final bloc = startedBloc();
        await _drainBloc();

        bloc.add(
          ProductMediaVideoPicked(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            contentType: 'video/mp4',
            fileExtension: 'mp4',
            duration: const Duration(seconds: 120),
          ),
        );
        await _drainBloc();

        expect(bloc.state.videos, isEmpty);
        expect(bloc.state.failure, isA<ValidationFailure>());
        expect(
          (bloc.state.failure as ValidationFailure).code,
          'product_video_too_long',
        );
        verifyNever(
          () => storage.uploadFile(
            path: any(named: 'path'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'rejects a video over the configured size limit before uploading',
      () async {
        featureFlagService.overrideFlag(
          FeatureFlagRegistry.configProductsVideoMaxSizeMb,
          1,
        );
        final bloc = startedBloc();
        await _drainBloc();

        bloc.add(
          ProductMediaVideoPicked(
            bytes: Uint8List(2 * 1024 * 1024),
            contentType: 'video/mp4',
            fileExtension: 'mp4',
            duration: const Duration(seconds: 5),
          ),
        );
        await _drainBloc();

        expect(bloc.state.videos, isEmpty);
        expect(
          (bloc.state.failure as ValidationFailure).code,
          'product_video_too_large',
        );
        verifyNever(
          () => storage.uploadFile(
            path: any(named: 'path'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'cancelling an in-flight upload removes it without a surfaced failure',
      () async {
        final pendingCompleters = <Completer<String>>[];
        when(
          () => storage.uploadFile(
            path: any(named: 'path'),
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          final completer = Completer<String>();
          pendingCompleters.add(completer);
          return completer.future;
        });

        final bloc = startedBloc();
        await _drainBloc();

        bloc.add(
          ProductMediaPhotoPicked(bytes: Uint8List.fromList(<int>[1, 2, 3])),
        );
        await _drainBloc();

        expect(bloc.state.uploads, hasLength(1));
        final uploadId = bloc.state.uploads.single.id;

        bloc.add(ProductMediaUploadCancelled(uploadId));
        await _drainBloc();

        // The bloc itself only asks the token to cancel; the real SDK would
        // then reject the pending upload future the same way
        // `mapStorageExceptionToAppException`'s `canceled` case documents.
        pendingCompleters.first.completeError(
          const ConflictException('Upload cancelado.', code: 'canceled'),
        );
        await _drainBloc();

        expect(bloc.state.uploads, isEmpty);
        expect(bloc.state.photos, isEmpty);
        expect(bloc.state.failure, isNull);

        await bloc.close();
      },
    );

    test('removing the principal photo promotes the next one and deletes the '
        'underlying Storage files', () async {
      const principal = ProductMedia(
        id: 'a.jpg',
        type: ProductMediaType.photo,
        url:
            'https://storage.test/organizations/org-1/products/product-1/a.jpg',
        thumbnailUrl:
            'https://storage.test/organizations/org-1/products/product-1/a_thumb.jpg',
        order: 0,
        principal: true,
      );
      const other = ProductMedia(
        id: 'b.jpg',
        type: ProductMediaType.photo,
        url:
            'https://storage.test/organizations/org-1/products/product-1/b.jpg',
        order: 1,
      );
      productRepository.seed(
        _buildProduct(
          id: 'product-1',
          media: const <ProductMedia>[principal, other],
        ),
      );

      final bloc = startedBloc(
        initialMedia: const <ProductMedia>[principal, other],
      );
      await _drainBloc();

      bloc.add(const ProductMediaRemoved('a.jpg'));
      await _drainBloc();

      expect(bloc.state.photos, hasLength(1));
      expect(bloc.state.photos.single.id, 'b.jpg');
      expect(bloc.state.photos.single.principal, isTrue);
      verify(
        () => storage.deleteFile(
          path: 'organizations/org-1/products/product-1/a.jpg',
        ),
      ).called(1);
      verify(
        () => storage.deleteFile(
          path: 'organizations/org-1/products/product-1/a_thumb.jpg',
        ),
      ).called(1);

      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
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

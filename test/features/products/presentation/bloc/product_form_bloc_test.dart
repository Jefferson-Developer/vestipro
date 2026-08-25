import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductFormBloc', () {
    late _InMemoryProductRepository productRepository;
    late _InMemoryProductFormDraftRepository draftRepository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late _InMemoryCategoryRepository categoryRepository;
    late _InMemoryProductColorRepository colorRepository;
    late _InMemorySizeGridTemplateRepository sizeGridTemplateRepository;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      productRepository = _InMemoryProductRepository();
      draftRepository = _InMemoryProductFormDraftRepository();
      auditLogRepository = _InMemoryAuditLogRepository();
      categoryRepository = _InMemoryCategoryRepository();
      colorRepository = _InMemoryProductColorRepository();
      sizeGridTemplateRepository = _InMemorySizeGridTemplateRepository();
      analyticsService = FakeAnalyticsService();
    });

    ProductFormBloc buildBloc() {
      return ProductFormBloc(
        getDraft: GetProductFormDraftUseCase(draftRepository),
        saveDraft: SaveProductFormDraftUseCase(draftRepository),
        clearDraft: ClearProductFormDraftUseCase(draftRepository),
        createProduct: CreateProductUseCase(productRepository),
        updateProduct: UpdateProductUseCase(
          productRepository,
          auditLogRepository,
        ),
        publishProduct: PublishProductUseCase(
          productRepository,
          auditLogRepository,
        ),
        listCategories: ListCategoriesUseCase(categoryRepository),
        listProductColors: ListProductColorsUseCase(colorRepository),
        listSizeGridTemplates: ListSizeGridTemplatesUseCase(
          sizeGridTemplateRepository,
        ),
        analyticsService: analyticsService,
      );
    }

    Future<ProductFormBloc> startedBloc({bool canPublish = true}) async {
      final bloc = buildBloc()
        ..add(
          ProductFormStarted(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'user-1',
            actorName: 'Ana Souza',
            canPublish: canPublish,
          ),
        );
      await _drainBloc();
      return bloc;
    }

    test('saves an incomplete local draft (no category, no SKU yet)', () async {
      final bloc = await startedBloc();

      bloc
        ..add(
          const ProductFormBasicSectionChanged(
            name: 'Camisa Essential',
            sku: '',
            reference: '',
            brand: '',
          ),
        )
        ..add(const ProductFormDraftSaved());
      await _drainBloc();

      expect(bloc.state.draftStatus, ProductFormDraftStatus.saved);
      expect(bloc.state.currentProduct, isNull);
      await bloc.close();

      final resumed = await startedBloc();
      expect(resumed.state.hasRestoredDraft, isTrue);
      expect(resumed.state.name, 'Camisa Essential');
      await resumed.close();
    });

    test(
      'blocks publishing with a clear message when fields are missing',
      () async {
        final bloc = await startedBloc();

        bloc
          ..add(
            const ProductFormBasicSectionChanged(
              name: 'Camisa Essential',
              sku: 'CAMISA-001',
              reference: 'REF-001',
              brand: '',
            ),
          )
          ..add(const ProductFormSubmitted());
        await _drainBloc();

        expect(
          bloc.state.submissionStatus,
          ProductFormSubmissionStatus.success,
        );
        expect(bloc.state.currentProduct?.status, ProductStatus.draft);

        bloc.add(const ProductFormPublishRequested());
        await _drainBloc();

        expect(bloc.state.publishStatus, ProductFormPublishStatus.failure);
        expect(
          bloc.state.fieldErrors['categoryId'],
          'Selecione a categoria do produto.',
        );
        expect(productRepository.products.single.status, ProductStatus.draft);

        await bloc.close();
      },
    );

    test('publishes successfully once every minimal field is filled', () async {
      final bloc = await startedBloc();

      bloc
        ..add(
          const ProductFormBasicSectionChanged(
            name: 'Camisa Essential',
            sku: 'CAMISA-001',
            reference: 'REF-001',
            brand: 'Malwee',
          ),
        )
        ..add(
          const ProductFormCategorySectionChanged(
            categoryId: 'category-1',
            subcategoryId: '',
            collectionId: '',
            seasonId: '',
            line: '',
            gender: null,
            targetAudience: null,
          ),
        )
        ..add(const ProductFormSubmitted());
      await _drainBloc();
      expect(bloc.state.submissionStatus, ProductFormSubmissionStatus.success);

      // A principal photo (TASK-068) is set through the separate media
      // gallery (`ProductMediaBloc`), not through this form — simulate that
      // step having already happened before publishing.
      final createdProduct = bloc.state.currentProduct!;
      await productRepository.update(
        product: createdProduct.copyWith(
          media: const <ProductMedia>[
            ProductMedia(
              id: 'photo-1.jpg',
              type: ProductMediaType.photo,
              url: 'https://cdn.example.com/photo-1.jpg',
              order: 0,
              principal: true,
            ),
          ],
        ),
      );

      bloc.add(const ProductFormPublishRequested());
      await _drainBloc();

      expect(bloc.state.publishStatus, ProductFormPublishStatus.success);
      expect(bloc.state.currentProduct?.status, ProductStatus.active);
      expect(
        analyticsService.loggedEvents
            .map((event) => event.name)
            .contains(AnalyticsEvents.productPublished),
        isTrue,
      );
      expect(
        auditLogRepository.entries.single.action,
        AuditAction.productPublished,
      );

      await bloc.close();
    });

    test('denies publishing for a caller without catalog.manage, without '
        'calling the use case', () async {
      final bloc = await startedBloc(canPublish: false);

      bloc
        ..add(
          const ProductFormBasicSectionChanged(
            name: 'Camisa Essential',
            sku: 'CAMISA-001',
            reference: 'REF-001',
            brand: '',
          ),
        )
        ..add(
          const ProductFormCategorySectionChanged(
            categoryId: 'category-1',
            subcategoryId: '',
            collectionId: '',
            seasonId: '',
            line: '',
            gender: null,
            targetAudience: null,
          ),
        )
        ..add(const ProductFormSubmitted());
      await _drainBloc();
      expect(bloc.state.submissionStatus, ProductFormSubmissionStatus.success);

      bloc.add(const ProductFormPublishRequested());
      await _drainBloc();

      expect(bloc.state.publishStatus, ProductFormPublishStatus.failure);
      expect(bloc.state.failure, isA<PermissionFailure>());
      expect(
        productRepository.products.single.status,
        ProductStatus.draft,
        reason: 'a denied publish must never reach the repository',
      );
      expect(auditLogRepository.entries, isEmpty);

      await bloc.close();
    });
  });
}

final class _InMemoryProductColorRepository implements ProductColorRepository {
  final List<ProductColor> colors = <ProductColor>[];

  @override
  Future<AppResult<ProductColor>> create({required ProductColor color}) async {
    colors.add(color);
    return AppSuccess<ProductColor>(color);
  }

  @override
  Future<AppResult<ProductColor>> update({required ProductColor color}) async {
    final index = colors.indexWhere((item) => item.id == color.id);
    colors[index] = color;
    return AppSuccess<ProductColor>(color);
  }

  @override
  Future<AppResult<List<ProductColor>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<ProductColor>>(
      colors
          .where((color) => color.organizationId == organizationId)
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<ProductColor>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final color in colors) {
      if (color.organizationId == organizationId && color.id == id) {
        return AppSuccess<ProductColor>(color);
      }
    }
    return const AppFailure<ProductColor>(
      NotFoundFailure('Color not found.', code: 'color_not_found'),
    );
  }

  @override
  Future<AppResult<bool>> eanExists({
    required String organizationId,
    required Ean ean,
    String? excludingColorId,
  }) async => const AppSuccess<bool>(false);
}

final class _InMemorySizeGridTemplateRepository
    implements SizeGridTemplateRepository {
  final List<SizeGridTemplate> templates = <SizeGridTemplate>[];

  @override
  Future<AppResult<SizeGridTemplate>> create({
    required SizeGridTemplate template,
  }) async {
    templates.add(template);
    return AppSuccess<SizeGridTemplate>(template);
  }

  @override
  Future<AppResult<SizeGridTemplate>> update({
    required SizeGridTemplate template,
  }) async {
    final index = templates.indexWhere((item) => item.id == template.id);
    templates[index] = template;
    return AppSuccess<SizeGridTemplate>(template);
  }

  @override
  Future<AppResult<List<SizeGridTemplate>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<SizeGridTemplate>>(
      templates
          .where((template) => template.organizationId == organizationId)
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<SizeGridTemplate>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final template in templates) {
      if (template.organizationId == organizationId && template.id == id) {
        return AppSuccess<SizeGridTemplate>(template);
      }
    }
    return const AppFailure<SizeGridTemplate>(
      NotFoundFailure(
        'Size grid template not found.',
        code: 'size_grid_template_not_found',
      ),
    );
  }

  @override
  Future<AppResult<bool>> nameExists({
    required String organizationId,
    required String name,
    String? excludingTemplateId,
  }) async => AppSuccess<bool>(
    templates.any(
      (template) =>
          template.organizationId == organizationId &&
          template.name.toLowerCase() == name.trim().toLowerCase() &&
          template.id != excludingTemplateId,
    ),
  );

  @override
  Future<AppResult<bool>> hasPublishedProductsUsingTemplate({
    required String organizationId,
    required String templateId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<bool>> sizeHasGeneratedVariants({
    required String organizationId,
    required String templateId,
    required String sizeId,
  }) async => const AppSuccess<bool>(false);
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

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

final class _InMemoryProductFormDraftRepository
    implements ProductFormDraftRepository {
  ProductFormDraft? _draft;

  @override
  Future<AppResult<ProductFormDraft?>> get({
    required String organizationId,
    required String userId,
  }) async {
    return AppSuccess<ProductFormDraft?>(_draft);
  }

  @override
  Future<AppResult<void>> save(ProductFormDraft draft) async {
    _draft = draft;
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  }) async {
    _draft = null;
    return const AppSuccess<void>(null);
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

final class _InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> categories = <Category>[];

  @override
  Future<AppResult<Category>> create({required Category category}) async {
    categories.add(category);
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<Category>> update({required Category category}) async {
    final index = categories.indexWhere((item) => item.id == category.id);
    categories[index] = category;
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<Category>>(
      categories
          .where((category) => category.organizationId == organizationId)
          .toList(),
    );
  }

  @override
  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final category in categories) {
      if (category.id == id) return AppSuccess<Category>(category);
    }
    return const AppFailure<Category>(
      NotFoundFailure('Category not found.', code: 'category_not_found'),
    );
  }

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = categories.indexWhere((item) => item.id == id);
    final deleted = categories[index].copyWith(
      deletedAt: DateTime.utc(2026, 1, 2),
    );
    categories[index] = deleted;
    return AppSuccess<Category>(deleted);
  }

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) async => const AppSuccess<List<Category>>(<Category>[]);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('ProductFormPage', () {
    late _MockMembershipRepository membershipRepository;
    late _InMemoryProductRepository productRepository;
    late _InMemoryProductFormDraftRepository draftRepository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late _InMemoryCategoryRepository categoryRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      productRepository = _InMemoryProductRepository();
      draftRepository = _InMemoryProductFormDraftRepository();
      auditLogRepository = _InMemoryAuditLogRepository();
      categoryRepository = _InMemoryCategoryRepository();
      permissionService = PermissionService(membershipRepository);
      analyticsService = FakeAnalyticsService();

      _stubMembership(
        membershipRepository,
        roleName: SystemRoleName.owner.code,
      );
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
        analyticsService: analyticsService,
      );
    }

    Widget buildPage() {
      return ProductFormPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'current-user',
        actorName: 'Ana Souza',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('shows the forbidden page for a role without catalog.manage', (
      tester,
    ) async {
      _stubMembership(
        membershipRepository,
        roleName: SystemRoleName.salesRep.code,
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Novo produto'), findsNothing);
      expect(find.bySemanticsLabel('Nome do produto'), findsNothing);
    });

    testWidgets('renders every section and preserves data across sections', (
      tester,
    ) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Básico'), findsOneWidget);
      expect(find.text('Categoria'), findsOneWidget);
      expect(find.text('Conteúdo'), findsOneWidget);
      expect(find.text('Características'), findsOneWidget);
      expect(find.text('SEO'), findsOneWidget);
      expect(find.text('Agendamento'), findsOneWidget);

      await _enterTextField(tester, 'Nome do produto', 'Camisa Essential');
      await tester.pumpAndSettle();

      // Expanding a different section must not lose what was already typed
      // in "Básico" — the value lives in ProductFormBloc's state, not in
      // section-local widget state.
      await tester.tap(find.text('Categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Básico'));
      await tester.pumpAndSettle();

      expect(find.text('Camisa Essential'), findsOneWidget);
    });

    testWidgets('shows "Publicar produto" only after the draft is saved', (
      tester,
    ) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Publicar produto'), findsNothing);

      await _enterTextField(tester, 'Nome do produto', 'Camisa Essential');
      await _enterTextField(tester, 'SKU', 'CAMISA-001');
      await _enterTextField(tester, 'Referência', 'REF-001');
      await _tapAppButton(tester, 'Salvar produto');

      expect(find.text('Publicar produto'), findsOneWidget);
    });
  });
}

Future<void> _enterTextField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find
      .byWidgetPredicate(
        (widget) => widget is AppTextField && widget.label == label,
      )
      .last;
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.enterText(editable.first, value);
  await tester.pumpAndSettle();
}

Future<void> _tapAppButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(AppButton, label).last;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.test',
      ),
    ),
  );
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

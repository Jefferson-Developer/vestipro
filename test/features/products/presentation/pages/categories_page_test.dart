import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  group('CategoriesPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockCategoryRepository categoryRepository;
    late PermissionService permissionService;

    Membership ownerMembership() {
      return Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: 'OWNER',
        roleName: 'OWNER',
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
      );
    }

    Category category({
      required String id,
      required String name,
      String? parentId,
      int sortOrder = 0,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return Category(
        id: id,
        organizationId: 'org-1',
        name: name,
        parentId: parentId,
        sortOrder: sortOrder,
        version: 1,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
      );
    }

    CategoryListBloc buildListBloc() {
      return CategoryListBloc(
        listCategories: ListCategoriesUseCase(categoryRepository),
        deleteCategory: DeleteCategoryUseCase(categoryRepository),
        reorderCategories: ReorderCategoriesUseCase(categoryRepository),
      );
    }

    CategoryFormBloc buildFormBloc() {
      return CategoryFormBloc(
        listCategories: ListCategoriesUseCase(categoryRepository),
        createCategory: CreateCategoryUseCase(categoryRepository),
        updateCategory: UpdateCategoryUseCase(categoryRepository),
      );
    }

    Widget buildPage() {
      return CategoriesPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildListBloc,
        createFormBloc: buildFormBloc,
      );
    }

    void setWidth(WidgetTester tester, double width) {
      final view = tester.view;
      view.physicalSize = Size(width, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      categoryRepository = _MockCategoryRepository();
      permissionService = PermissionService(membershipRepository);

      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
    });

    testWidgets('shows an empty state guiding the first category creation', (
      tester,
    ) async {
      setWidth(tester, 1200);
      when(
        () => categoryRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Category>>(<Category>[]));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma categoria cadastrada'), findsOneWidget);
      expect(find.text('Criar primeira categoria'), findsOneWidget);
    });

    testWidgets('shows an error state when loading categories fails', (
      tester,
    ) async {
      setWidth(tester, 1200);
      when(() => categoryRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => const AppFailure<List<Category>>(
          UnexpectedFailure('Falha ao carregar.', code: 'boom'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar as categorias'),
        findsOneWidget,
      );
    });

    testWidgets('renders root categories and expands to reveal subcategories '
        '(desktop, drag-and-drop tree)', (tester) async {
      setWidth(tester, 1200);
      when(() => categoryRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Category>>(<Category>[
          category(id: 'cat-1', name: 'Feminino'),
          category(id: 'cat-2', name: 'Masculino', sortOrder: 1),
          category(id: 'cat-1-sub', name: 'Calças', parentId: 'cat-1'),
        ]),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Calças'), findsNothing);

      await tester.tap(find.text('Feminino'));
      await tester.pumpAndSettle();
      // A plain tap on the label does not toggle anything on its own;
      // expand via the dedicated control instead.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('Calças'), findsOneWidget);
    });

    testWidgets(
      'reorders root categories with the explicit "mover para cima/baixo" '
      'action on mobile — never a drag gesture',
      (tester) async {
        setWidth(tester, 360);
        when(() => categoryRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Category>>(<Category>[
            category(id: 'cat-1', name: 'Feminino'),
            category(id: 'cat-2', name: 'Masculino', sortOrder: 1),
          ]),
        );
        when(
          () => categoryRepository.reorder(
            organizationId: 'org-1',
            parentId: null,
            orderedIds: <String>['cat-2', 'cat-1'],
            updatedBy: 'current-user',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<Category>>(<Category>[
            category(id: 'cat-2', name: 'Masculino', sortOrder: 0),
            category(id: 'cat-1', name: 'Feminino', sortOrder: 1),
          ]),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        // No drag handle on mobile — only the explicit up/down actions.
        expect(find.byIcon(Icons.drag_indicator), findsNothing);

        await tester.tap(find.byIcon(Icons.arrow_downward).first);
        await tester.pumpAndSettle();

        verify(
          () => categoryRepository.reorder(
            organizationId: 'org-1',
            parentId: null,
            orderedIds: <String>['cat-2', 'cat-1'],
            updatedBy: 'current-user',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'search shows a flat result with the parent name, across every level',
      (tester) async {
        setWidth(tester, 1200);
        when(() => categoryRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Category>>(<Category>[
            category(id: 'cat-1', name: 'Feminino'),
            category(id: 'cat-1-sub', name: 'Calças', parentId: 'cat-1'),
          ]),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        // A lowercase partial query — proves the match is case-insensitive
        // and substring-based, and (unlike the full "Calças" name) never
        // collides with the rendered result Text widget in the finder below.
        await tester.enterText(find.byType(TextField), 'calç');
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Calças'), findsOneWidget);
        expect(find.text('Subcategoria de: Feminino'), findsOneWidget);
        expect(find.text('Masculino'), findsNothing);
      },
    );
  });
}

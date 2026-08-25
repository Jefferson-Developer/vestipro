import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('ProductColorPalettePage', () {
    late _MockMembershipRepository membershipRepository;
    late SharedPreferencesProductColorRepository repository;
    late PermissionService permissionService;

    Membership ownerMembership() {
      return Membership(
        id: 'membership-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: 'OWNER',
        roleName: 'OWNER',
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
        name: 'Ana',
        email: 'ana@vestipro.com.br',
      );
    }

    ProductColorPaletteBloc buildBloc() {
      return ProductColorPaletteBloc(
        listProductColors: ListProductColorsUseCase(repository),
        createProductColor: CreateProductColorUseCase(
          repository,
          const ProductColorSimilarityService(),
        ),
        updateProductColor: UpdateProductColorUseCase(
          repository,
          const ProductColorSimilarityService(),
        ),
        markProductColorUnavailable: MarkProductColorUnavailableUseCase(
          repository,
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      membershipRepository = _MockMembershipRepository();
      repository = const SharedPreferencesProductColorRepository();
      permissionService = PermissionService(membershipRepository);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
    });

    testWidgets(
      'renders empty state and opens color form with swatch preview',
      (tester) async {
        await pumpApp(
          tester,
          ProductColorPalettePage(
            organizationId: 'org-1',
            userId: 'user-1',
            permissionService: permissionService,
            createBloc: buildBloc,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nenhuma cor cadastrada'), findsOneWidget);

        await tester.tap(find.text('Criar primeira cor'));
        await tester.pumpAndSettle();

        expect(find.text('Nova cor'), findsAtLeastNWidgets(1));
        expect(find.bySemanticsLabel('Hexadecimal da cor'), findsOneWidget);
      },
    );
  });
}

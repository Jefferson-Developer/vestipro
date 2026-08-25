import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('SizeGridTemplatesPage', () {
    late _MockMembershipRepository membershipRepository;
    late SharedPreferencesSizeGridTemplateRepository repository;
    late PermissionService permissionService;

    SizeGridTemplateBloc buildBloc() {
      final create = CreateSizeGridTemplateUseCase(repository);
      return SizeGridTemplateBloc(
        listSizeGridTemplates: ListSizeGridTemplatesUseCase(repository),
        createSizeGridTemplate: create,
        updateSizeGridTemplate: UpdateSizeGridTemplateUseCase(repository),
        duplicateSizeGridTemplate: DuplicateSizeGridTemplateUseCase(
          repository,
          create,
        ),
        reorderSizeGridTemplateSizes: ReorderSizeGridTemplateSizesUseCase(
          repository,
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      membershipRepository = _MockMembershipRepository();
      repository = const SharedPreferencesSizeGridTemplateRepository();
      permissionService = PermissionService(membershipRepository);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(_ownerMembership()));
    });

    testWidgets('creates, duplicates and reorders a template', (tester) async {
      await pumpApp(
        tester,
        SizeGridTemplatesPage(
          organizationId: 'org-1',
          userId: 'user-1',
          permissionService: permissionService,
          createBloc: buildBloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma grade cadastrada'), findsOneWidget);
      await tester.tap(find.text('Criar primeira grade'));
      await tester.pumpAndSettle();

      await _enterTextField(tester, 'Nome do template', 'PP-GG');
      await _enterTextField(tester, 'Tamanhos em ordem comercial', 'PP\nP\nM');
      await _tapAppButton(tester, 'Salvar grade');

      expect(find.text('PP-GG'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Duplicar grade').first);
      await tester.pumpAndSettle();
      expect(find.text('PP-GG cópia'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Reordenar tamanhos').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Descer tamanho').first);
      await tester.pumpAndSettle();
      await _tapAppButton(tester, 'Salvar ordem');

      final list = await repository.listByOrganization('org-1');
      final templates = (list as AppSuccess<List<SizeGridTemplate>>).value;
      final original = templates.firstWhere(
        (template) => template.name == 'PP-GG',
      );
      expect(original.orderedSizes.map((size) => size.label), <String>[
        'P',
        'PP',
        'M',
      ]);
    });
  });
}

Membership _ownerMembership() {
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

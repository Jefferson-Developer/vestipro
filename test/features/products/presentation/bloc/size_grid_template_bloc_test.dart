import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SizeGridTemplateBloc', () {
    late SharedPreferencesSizeGridTemplateRepository repository;

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
      repository = const SharedPreferencesSizeGridTemplateRepository();
    });

    test('creates, duplicates and reorders templates', () async {
      final bloc = buildBloc()
        ..add(
          const SizeGridTemplateStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
      await _drainBloc();

      bloc
        ..add(const SizeGridTemplateCreateRequested())
        ..add(
          const SizeGridTemplateFormChanged(
            name: 'PP-GG',
            sizesInput: 'PP\nP\nM\nG\nGG',
          ),
        )
        ..add(const SizeGridTemplateSubmitted());
      await _drainBloc();

      expect(bloc.state.saveStatus, SizeGridTemplateSaveStatus.success);
      expect(bloc.state.templates, hasLength(1));

      final original = bloc.state.templates.single;
      bloc.add(SizeGridTemplateDuplicateRequested(original));
      await _drainBloc();

      expect(
        bloc.state.templates.map((template) => template.name),
        contains('PP-GG cópia'),
      );

      bloc.add(
        SizeGridTemplateReordered(
          templateId: original.id,
          orderedSizeIds: original.orderedSizes.reversed
              .map((size) => size.id)
              .toList(growable: false),
        ),
      );
      await _drainBloc();

      final reordered = bloc.state.templates.firstWhere(
        (template) => template.id == original.id,
      );
      expect(reordered.orderedSizes.first.label, 'GG');
      expect(reordered.orderedSizes.first.orderScore, 1);

      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

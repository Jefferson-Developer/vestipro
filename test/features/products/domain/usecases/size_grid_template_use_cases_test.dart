import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SizeGridTemplate use cases', () {
    late SharedPreferencesSizeGridTemplateRepository repository;
    late CreateSizeGridTemplateUseCase create;
    late UpdateSizeGridTemplateUseCase update;
    late ReorderSizeGridTemplateSizesUseCase reorder;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesSizeGridTemplateRepository();
      create = CreateSizeGridTemplateUseCase(repository);
      update = UpdateSizeGridTemplateUseCase(repository);
      reorder = ReorderSizeGridTemplateSizesUseCase(repository);
    });

    test(
      'creates, lists and validates unique names per organization',
      () async {
        final first = await create(
          id: 'template-1',
          organizationId: 'org-1',
          name: 'PP-GG',
          sizes: _sizes('org-1', <String>['PP', 'P', 'M', 'G', 'GG']),
          createdBy: 'user-1',
        );

        expect(first, isA<AppSuccess<SizeGridTemplate>>());
        final duplicate = await create(
          id: 'template-2',
          organizationId: 'org-1',
          name: ' pp-gg ',
          sizes: _sizes('org-1', <String>['PP', 'P']),
          createdBy: 'user-1',
        );
        expect(
          (duplicate as AppFailure<SizeGridTemplate>).failure,
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'size_grid_template_name_already_exists',
          ),
        );

        final anotherTenant = await create(
          id: 'template-3',
          organizationId: 'org-2',
          name: 'PP-GG',
          sizes: _sizes('org-2', <String>['PP', 'P']),
          createdBy: 'user-1',
        );
        expect(anotherTenant, isA<AppSuccess<SizeGridTemplate>>());

        final list = await repository.listByOrganization('org-1');
        final templates = (list as AppSuccess<List<SizeGridTemplate>>).value;
        expect(templates.single.name, 'PP-GG');
        expect(
          templates.single.orderedSizes.map((size) => size.label),
          <String>['PP', 'P', 'M', 'G', 'GG'],
        );
      },
    );

    test('reorders sizes preserving explicit order scores', () async {
      await create(
        id: 'template-1',
        organizationId: 'org-1',
        name: 'Numérico',
        sizes: _sizes('org-1', <String>['34', '36', '38']),
        createdBy: 'user-1',
      );

      final result = await reorder(
        organizationId: 'org-1',
        templateId: 'template-1',
        orderedSizeIds: const <String>['size-38', 'size-36', 'size-34'],
        updatedBy: 'user-2',
      );

      final template = (result as AppSuccess<SizeGridTemplate>).value;
      expect(
        template.orderedSizes.map((size) => '${size.label}:${size.orderScore}'),
        <String>['38:1', '36:2', '34:3'],
      );
    });

    test(
      'requires confirmation before removing a size used by variants',
      () async {
        await create(
          id: 'template-1',
          organizationId: 'org-1',
          name: 'P-M-G',
          sizes: _sizes('org-1', <String>['P', 'M', 'G']),
          createdBy: 'user-1',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('size_grid_variant_usage_org-1', <String>[
          'template-1|size-m',
        ]);

        final blocked = await update(
          organizationId: 'org-1',
          id: 'template-1',
          name: 'P-G',
          sizes: _sizes('org-1', <String>['P', 'G']),
          updatedBy: 'user-2',
        );
        expect(
          (blocked as AppFailure<SizeGridTemplate>).failure,
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'size_grid_template_size_usage_confirmation_required',
          ),
        );

        final confirmed = await update(
          organizationId: 'org-1',
          id: 'template-1',
          name: 'P-G',
          sizes: _sizes('org-1', <String>['P', 'G']),
          updatedBy: 'user-2',
          confirmVariantUsage: true,
        );
        expect(confirmed, isA<AppSuccess<SizeGridTemplate>>());
      },
    );
  });
}

List<SizeGridSize> _sizes(String organizationId, List<String> labels) {
  return labels.indexed
      .map((entry) {
        final (index, label) = entry;
        return SizeGridSize(
          id: 'size-${label.toLowerCase()}',
          organizationId: organizationId,
          label: label,
          orderScore: index + 1,
        );
      })
      .toList(growable: false);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('GetSizeGridTemplateByIdUseCase', () {
    late SharedPreferencesSizeGridTemplateRepository repository;
    late GetSizeGridTemplateByIdUseCase useCase;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesSizeGridTemplateRepository();
      useCase = GetSizeGridTemplateByIdUseCase(repository);
      await repository.create(template: _template());
    });

    test('returns the template when it exists in the organization', () async {
      final result = await useCase(organizationId: 'org-1', id: 'grid-1');

      expect(result, isA<AppSuccess<SizeGridTemplate>>());
      expect((result as AppSuccess<SizeGridTemplate>).value.name, 'P-M-G');
    });

    test('fails when the template does not exist', () async {
      final result = await useCase(organizationId: 'org-1', id: 'missing');

      expect(result, isA<AppFailure<SizeGridTemplate>>());
      expect(
        (result as AppFailure<SizeGridTemplate>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('fails when the template belongs to another organization', () async {
      final result = await useCase(organizationId: 'org-2', id: 'grid-1');

      expect(result, isA<AppFailure<SizeGridTemplate>>());
    });
  });
}

SizeGridTemplate _template() {
  final now = DateTime.utc(2026, 1, 1);
  return SizeGridTemplate(
    id: 'grid-1',
    organizationId: 'org-1',
    name: 'P-M-G',
    sizes: const <SizeGridSize>[
      SizeGridSize(
        id: 'size-p',
        organizationId: 'org-1',
        label: 'P',
        orderScore: 1,
      ),
    ],
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('DeleteCampaignUseCase', () {
    late InMemoryCatalogCampaignRepository repository;
    late DeleteCampaignUseCase useCase;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
      useCase = DeleteCampaignUseCase(repository);
    });

    test(
      'soft-deletes a campaign, which then disappears from listing',
      () async {
        repository.seed(buildTestCampaign(id: 'campaign-1'));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'campaign-1',
          updatedBy: 'user-1',
        );

        expect(result, isA<AppSuccess<CatalogCampaign>>());
        final deleted = (result as AppSuccess<CatalogCampaign>).value;
        expect(deleted.deletedAt, isNotNull);

        final listResult = await repository.listByOrganization('org-1');
        expect(
          (listResult as AppSuccess<List<CatalogCampaign>>).value,
          isEmpty,
        );
      },
    );

    test('fails when the campaign does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing',
        updatedBy: 'user-1',
      );

      expect(result, isA<AppFailure<CatalogCampaign>>());
      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('rejects a blank id without touching the repository', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: '   ',
        updatedBy: 'user-1',
      );

      expect(result, isA<AppFailure<CatalogCampaign>>());
      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<ValidationFailure>(),
      );
    });
  });
}

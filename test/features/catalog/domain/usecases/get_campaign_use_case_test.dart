import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('GetCampaignUseCase', () {
    late InMemoryCatalogCampaignRepository repository;
    late GetCampaignUseCase useCase;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
      useCase = GetCampaignUseCase(repository);
    });

    test('loads a campaign by id, regardless of its visibility', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'campaign-1',
      );

      expect(result, isA<AppSuccess<CatalogCampaign>>());
      expect((result as AppSuccess<CatalogCampaign>).value.id, 'campaign-1');
    });

    test('fails when the campaign does not exist', () async {
      final result = await useCase.call(organizationId: 'org-1', id: 'missing');

      expect(result, isA<AppFailure<CatalogCampaign>>());
      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<NotFoundFailure>(),
      );
    });
  });
}

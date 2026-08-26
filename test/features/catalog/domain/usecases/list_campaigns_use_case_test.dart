import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('ListCampaignsUseCase', () {
    late InMemoryCatalogCampaignRepository repository;
    late ListCampaignsUseCase useCase;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
      useCase = ListCampaignsUseCase(repository);
    });

    test('lists every non-deleted campaign of the organization, regardless of '
        'visibility', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));
      repository.seed(
        buildTestCampaign(id: 'campaign-2').copyWith(active: false),
      );

      final result = await useCase.call('org-1');

      expect(result, isA<AppSuccess<List<CatalogCampaign>>>());
      final campaigns = (result as AppSuccess<List<CatalogCampaign>>).value;
      expect(campaigns.map((c) => c.id).toSet(), <String>{
        'campaign-1',
        'campaign-2',
      });
    });

    test('propagates a repository failure', () async {
      repository.shouldFail = true;

      final result = await useCase.call('org-1');

      expect(result, isA<AppFailure<List<CatalogCampaign>>>());
    });
  });
}

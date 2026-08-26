import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('CreateCampaignUseCase', () {
    late InMemoryCatalogCampaignRepository repository;
    late CreateCampaignUseCase useCase;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
      useCase = CreateCampaignUseCase(repository);
    });

    test('creates a campaign, defaulting to active', () async {
      final result = await useCase.call(
        id: 'campaign-1',
        organizationId: 'org-1',
        title: 'Verão em Movimento',
        subtitle: 'Nova coleção',
        description: 'Editorial de verão.',
        imageUrl: 'https://example.com/cover.jpg',
        editorialImageUrls: <String>['https://example.com/a.jpg'],
        relatedProductIds: <String>['product-1'],
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<CatalogCampaign>>());
      final campaign = (result as AppSuccess<CatalogCampaign>).value;
      expect(campaign.active, isTrue);
      expect(campaign.title, 'Verão em Movimento');
      expect(campaign.editorialImageUrls, <String>[
        'https://example.com/a.jpg',
      ]);
      expect(campaign.relatedProductIds, <String>['product-1']);
      expect(repository.campaigns['campaign-1'], isNotNull);
    });

    test('rejects a blank title without touching the repository', () async {
      final result = await useCase.call(
        id: 'campaign-1',
        organizationId: 'org-1',
        title: '   ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<CatalogCampaign>>());
      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<ValidationFailure>(),
      );
      expect(repository.campaigns, isEmpty);
    });

    test('rejects an endAt before startAt', () async {
      final result = await useCase.call(
        id: 'campaign-1',
        organizationId: 'org-1',
        title: 'Verão em Movimento',
        startAt: DateTime.utc(2026, 6, 1),
        endAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<CatalogCampaign>>());
      final failure =
          (result as AppFailure<CatalogCampaign>).failure as ValidationFailure;
      expect(failure.fieldErrors, containsPair('endAt', isNotEmpty));
    });
  });
}

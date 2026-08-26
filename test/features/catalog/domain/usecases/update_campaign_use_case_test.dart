import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('UpdateCampaignUseCase', () {
    late InMemoryCatalogCampaignRepository repository;
    late UpdateCampaignUseCase useCase;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
      useCase = UpdateCampaignUseCase(repository);
    });

    test('updates every editable field, including active/vigência', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'campaign-1',
        title: 'Novo título',
        subtitle: 'Novo subtítulo',
        description: 'Novo texto',
        imageUrl: 'https://example.com/new-cover.jpg',
        editorialImageUrls: <String>['https://example.com/b.jpg'],
        relatedProductIds: <String>['product-2'],
        active: false,
        startAt: DateTime.utc(2026, 6, 1),
        endAt: DateTime.utc(2026, 6, 30),
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<CatalogCampaign>>());
      final campaign = (result as AppSuccess<CatalogCampaign>).value;
      expect(campaign.title, 'Novo título');
      expect(campaign.active, isFalse);
      expect(campaign.relatedProductIds, <String>['product-2']);
      expect(campaign.updatedBy, 'user-2');
    });

    test('fails when the campaign does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing',
        title: 'Título',
        active: true,
        updatedBy: 'user-1',
      );

      expect(result, isA<AppFailure<CatalogCampaign>>());
      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('rejects a blank title', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'campaign-1',
        title: '',
        active: true,
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

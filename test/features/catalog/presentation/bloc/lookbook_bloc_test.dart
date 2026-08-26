import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('LookbookBloc', () {
    late InMemoryCatalogCampaignRepository campaignRepository;
    late InMemoryCatalogProductRepository productRepository;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      campaignRepository = InMemoryCatalogCampaignRepository();
      productRepository = InMemoryCatalogProductRepository();
      analyticsService = FakeAnalyticsService();
    });

    LookbookBloc buildBloc({DateTime Function()? now}) {
      return LookbookBloc(
        getCampaign: GetCampaignUseCase(campaignRepository),
        listRelatedProducts: ListCampaignRelatedProductsUseCase(
          productRepository,
        ),
        analyticsService: analyticsService,
        now: now ?? () => DateTime.utc(2026, 6, 15),
      );
    }

    test('loads an active campaign with its related products, logging '
        'campaign_viewed once', () async {
      productRepository.products.add(
        buildTestCatalogHomeProduct(id: 'product-1'),
      );
      campaignRepository.seed(
        buildTestCampaign(
          id: 'campaign-1',
        ).copyWith(relatedProductIds: <String>['product-1']),
      );

      final bloc = buildBloc()
        ..add(
          const LookbookStarted(
            organizationId: 'org-1',
            campaignId: 'campaign-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.status, LookbookStatus.ready);
      expect(bloc.state.campaign?.id, 'campaign-1');
      expect(bloc.state.relatedProducts.single.id, 'product-1');
      expect(
        analyticsService.loggedEvents
            .where((e) => e.name == AnalyticsEvents.campaignViewed)
            .length,
        1,
      );
      await bloc.close();
    });

    test('treats a non-existent campaign as unavailable', () async {
      final bloc = buildBloc()
        ..add(
          const LookbookStarted(organizationId: 'org-1', campaignId: 'missing'),
        );
      await _drainBloc();

      expect(bloc.state.status, LookbookStatus.unavailable);
      await bloc.close();
    });

    test('treats a scheduled campaign (startAt in the future) as '
        'unavailable, same as not found', () async {
      campaignRepository.seed(
        buildTestCampaign(
          id: 'campaign-1',
        ).copyWith(startAt: DateTime.utc(2026, 12, 1)),
      );

      final bloc = buildBloc()
        ..add(
          const LookbookStarted(
            organizationId: 'org-1',
            campaignId: 'campaign-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.status, LookbookStatus.unavailable);
      await bloc.close();
    });

    test(
      'treats an expired campaign (endAt in the past) as unavailable',
      () async {
        campaignRepository.seed(
          buildTestCampaign(
            id: 'campaign-1',
          ).copyWith(endAt: DateTime.utc(2026, 1, 1)),
        );

        final bloc = buildBloc()
          ..add(
            const LookbookStarted(
              organizationId: 'org-1',
              campaignId: 'campaign-1',
            ),
          );
        await _drainBloc();

        expect(bloc.state.status, LookbookStatus.unavailable);
        await bloc.close();
      },
    );

    test('treats a deactivated campaign as unavailable', () async {
      campaignRepository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(active: false),
      );

      final bloc = buildBloc()
        ..add(
          const LookbookStarted(
            organizationId: 'org-1',
            campaignId: 'campaign-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.status, LookbookStatus.unavailable);
      await bloc.close();
    });

    test('loads a campaign with no related products (ids empty)', () async {
      campaignRepository.seed(buildTestCampaign(id: 'campaign-1'));

      final bloc = buildBloc()
        ..add(
          const LookbookStarted(
            organizationId: 'org-1',
            campaignId: 'campaign-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.status, LookbookStatus.ready);
      expect(bloc.state.relatedProducts, isEmpty);
      await bloc.close();
    });

    test(
      'logs campaign_product_clicked when a related product is tapped',
      () async {
        productRepository.products.add(
          buildTestCatalogHomeProduct(id: 'product-1'),
        );
        campaignRepository.seed(
          buildTestCampaign(
            id: 'campaign-1',
          ).copyWith(relatedProductIds: <String>['product-1']),
        );

        final bloc = buildBloc()
          ..add(
            const LookbookStarted(
              organizationId: 'org-1',
              campaignId: 'campaign-1',
            ),
          );
        await _drainBloc();

        bloc.add(const LookbookRelatedProductTapped('product-1'));
        await _drainBloc();

        expect(
          analyticsService.loggedEvents
              .map((e) => e.name)
              .contains(AnalyticsEvents.campaignProductClicked),
          isTrue,
        );
        await bloc.close();
      },
    );
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

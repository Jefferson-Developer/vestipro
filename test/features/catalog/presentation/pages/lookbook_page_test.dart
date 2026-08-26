import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

Future<void> _pumpLookbook(
  WidgetTester tester, {
  required String campaignId,
  double width = 400,
  InMemoryCatalogCampaignRepository? campaignRepository,
  InMemoryCatalogProductRepository? productRepository,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final campaigns = campaignRepository ?? InMemoryCatalogCampaignRepository();
  final products = productRepository ?? InMemoryCatalogProductRepository();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: LookbookPage(
        organizationId: 'org-1',
        campaignId: campaignId,
        createBloc: () => LookbookBloc(
          getCampaign: GetCampaignUseCase(campaigns),
          listRelatedProducts: ListCampaignRelatedProductsUseCase(products),
          analyticsService: FakeAnalyticsService(),
          now: () => DateTime.utc(2026, 6, 15),
        ),
      ),
    ),
  );
}

void main() {
  group('LookbookPage', () {
    testWidgets('shows an unavailable state for a campaign that does not '
        'exist', (tester) async {
      await _pumpLookbook(tester, campaignId: 'missing');
      await tester.pumpAndSettle();

      expect(find.text('Campanha indisponível'), findsOneWidget);
    });

    testWidgets('shows an unavailable state for an expired campaign, exactly '
        'like a missing one', (tester) async {
      final campaignRepository = InMemoryCatalogCampaignRepository();
      campaignRepository.seed(
        buildTestCampaign(
          id: 'campaign-1',
        ).copyWith(endAt: DateTime.utc(2026, 1, 1)),
      );

      await _pumpLookbook(
        tester,
        campaignId: 'campaign-1',
        campaignRepository: campaignRepository,
      );
      await tester.pumpAndSettle();

      expect(find.text('Campanha indisponível'), findsOneWidget);
    });

    testWidgets('renders an active campaign with no editorial content as an '
        'empty-but-graceful state', (tester) async {
      final campaignRepository = InMemoryCatalogCampaignRepository();
      campaignRepository.seed(buildTestCampaign(id: 'campaign-1'));

      await mockNetworkImagesFor(() async {
        await _pumpLookbook(
          tester,
          campaignId: 'campaign-1',
          campaignRepository: campaignRepository,
        );
        await tester.pumpAndSettle();

        expect(find.text('Campanha campaign-1'), findsOneWidget);
        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        expect(find.text('Produtos da campanha'), findsNothing);
      });
    });

    testWidgets('renders the full lookbook: cover, text and related '
        'products carousel', (tester) async {
      final campaignRepository = InMemoryCatalogCampaignRepository();
      final productRepository = InMemoryCatalogProductRepository();
      productRepository.products.add(
        buildTestCatalogHomeProduct(id: 'product-1'),
      );
      campaignRepository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(
          title: 'Verão em Movimento',
          subtitle: 'Nova coleção',
          description: 'Editorial de verão.',
          imageUrl: 'https://example.com/cover.jpg',
          relatedProductIds: <String>['product-1'],
        ),
      );

      await mockNetworkImagesFor(() async {
        await _pumpLookbook(
          tester,
          campaignId: 'campaign-1',
          campaignRepository: campaignRepository,
          productRepository: productRepository,
        );
        await tester.pumpAndSettle();

        expect(find.text('Verão em Movimento'), findsOneWidget);
        expect(find.text('Nova coleção'), findsOneWidget);
        expect(find.text('Editorial de verão.'), findsOneWidget);
        expect(find.text('Produtos da campanha'), findsOneWidget);
      });
    });

    testWidgets('lays the gallery and info side by side on desktop widths', (
      tester,
    ) async {
      final campaignRepository = InMemoryCatalogCampaignRepository();
      campaignRepository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(
          imageUrl: 'https://example.com/cover.jpg',
          description: 'Editorial de verão.',
        ),
      );

      await mockNetworkImagesFor(() async {
        await _pumpLookbook(
          tester,
          campaignId: 'campaign-1',
          campaignRepository: campaignRepository,
          width: 1300,
        );
        await tester.pumpAndSettle();

        final descriptionTop = tester
            .getTopLeft(find.text('Editorial de verão.'))
            .dy;
        final imageTop = tester.getTopLeft(find.byType(Image)).dy;
        // Side by side on desktop: both start near the top of the same row
        // instead of the text being pushed hundreds of pixels below the
        // (tall) stacked gallery, as it is on mobile.
        expect((descriptionTop - imageTop).abs(), lessThan(400));
      });
    });

    testWidgets('stacks the gallery above the info on mobile widths', (
      tester,
    ) async {
      final campaignRepository = InMemoryCatalogCampaignRepository();
      campaignRepository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(
          imageUrl: 'https://example.com/cover.jpg',
          description: 'Editorial de verão.',
        ),
      );

      await mockNetworkImagesFor(() async {
        await _pumpLookbook(
          tester,
          campaignId: 'campaign-1',
          campaignRepository: campaignRepository,
          width: 400,
        );
        await tester.pumpAndSettle();

        final descriptionTop = tester
            .getTopLeft(find.text('Editorial de verão.'))
            .dy;
        final imageTop = tester.getTopLeft(find.byType(Image)).dy;
        // Stacked on mobile: the cover image (360px tall) sits well above
        // the text.
        expect(descriptionTop - imageTop, greaterThan(300));
      });
    });
  });
}

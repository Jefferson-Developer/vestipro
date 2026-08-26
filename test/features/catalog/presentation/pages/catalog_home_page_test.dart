import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

import '../../catalog_test_fakes.dart';

Future<void> _pumpCatalogHome(
  WidgetTester tester, {
  required AppResult<List<Collection>> collectionsResult,
  required AppResult<List<Product>> productsResult,
  required AppResult<List<CatalogCampaign>> campaignsResult,
  CatalogHomeSnapshot? cachedSnapshot,
  double width = 400,
  VoidCallback? onCreateProductTap,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CatalogHomePage(
        organizationId: 'org-1',
        userId: 'user-1',
        onCreateProductTap: onCreateProductTap,
        createBloc: () => buildTestCatalogHomeBloc(
          collectionsResult: collectionsResult,
          productsResult: productsResult,
          campaignsResult: campaignsResult,
          cachedSnapshot: cachedSnapshot,
          analyticsService: FakeAnalyticsService(),
        ),
      ),
    ),
  );
}

void main() {
  group('CatalogHomePage', () {
    testWidgets('shows a skeleton before the first load completes', (
      tester,
    ) async {
      await _pumpCatalogHome(
        tester,
        collectionsResult: AppSuccess<List<Collection>>(<Collection>[
          buildTestCollection(id: 'col-1'),
        ]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
      );

      // Exactly one frame in: the bloc's Started event has been enqueued
      // but not processed yet, so the page is still in its initial state.
      expect(find.byType(AppProductCardSkeleton), findsWidgets);
    });

    testWidgets('renders sections once loaded, without ever showing an '
        'empty section title', (tester) async {
      await mockNetworkImagesFor(() async {
        await _pumpCatalogHome(
          tester,
          collectionsResult: AppSuccess<List<Collection>>(<Collection>[
            buildTestCollection(id: 'col-1'),
          ]),
          productsResult: AppSuccess<List<Product>>(<Product>[
            buildTestCatalogHomeProduct(id: 'prod-1'),
          ]),
          campaignsResult: const AppSuccess<List<CatalogCampaign>>(
            <CatalogCampaign>[],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Coleções em destaque'), findsOneWidget);
        expect(find.text('Lançamentos'), findsOneWidget);
        // Campaigns resolved with zero items: its section is dropped
        // entirely, never shown with an empty title/container.
        expect(find.text('Campanhas em destaque'), findsNothing);
      });
    });

    testWidgets('shows the friendly empty state when the catalog genuinely '
        'has no content yet', (tester) async {
      await _pumpCatalogHome(
        tester,
        collectionsResult: const AppSuccess<List<Collection>>(<Collection>[]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catálogo em preparação'), findsOneWidget);
    });

    testWidgets('offers product creation from the empty catalog when wired', (
      tester,
    ) async {
      var tapped = false;
      await _pumpCatalogHome(
        tester,
        onCreateProductTap: () => tapped = true,
        collectionsResult: const AppSuccess<List<Collection>>(<Collection>[]),
        productsResult: const AppSuccess<List<Product>>(<Product>[]),
        campaignsResult: const AppSuccess<List<CatalogCampaign>>(
          <CatalogCampaign>[],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows a full error state with retry when everything fails '
        'and there is no cache', (tester) async {
      await _pumpCatalogHome(
        tester,
        collectionsResult: const AppFailure<List<Collection>>(
          ServerFailure('down', code: 'down'),
        ),
        productsResult: const AppFailure<List<Product>>(
          ServerFailure('down', code: 'down'),
        ),
        campaignsResult: const AppFailure<List<CatalogCampaign>>(
          ServerFailure('down', code: 'down'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar o catálogo'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('shows a stale-data notice when falling back to cache', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await _pumpCatalogHome(
          tester,
          collectionsResult: const AppFailure<List<Collection>>(
            ConnectivityFailure('offline', code: 'offline'),
          ),
          productsResult: const AppFailure<List<Product>>(
            ConnectivityFailure('offline', code: 'offline'),
          ),
          campaignsResult: const AppFailure<List<CatalogCampaign>>(
            ConnectivityFailure('offline', code: 'offline'),
          ),
          cachedSnapshot: CatalogHomeSnapshot(
            savedAt: DateTime.utc(2026, 1, 1),
            sections: <CatalogHomeSection>[
              const CatalogHomeSection(
                type: CatalogHomeSectionType.featuredCollections,
                title: 'Coleções em destaque',
                order: 0,
                priority: 0,
                items: <CatalogHomeItem>[
                  CatalogHomeItem(id: 'cached-1', title: 'Coleção cacheada'),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('desatualizado'), findsOneWidget);
        expect(find.text('Coleção cacheada'), findsOneWidget);
      });
    });

    testWidgets('lays sections out in a single column on mobile widths', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await _pumpCatalogHome(
          tester,
          width: 400,
          collectionsResult: AppSuccess<List<Collection>>(<Collection>[
            buildTestCollection(id: 'col-1'),
          ]),
          productsResult: AppSuccess<List<Product>>(<Product>[
            buildTestCatalogHomeProduct(id: 'prod-1'),
          ]),
          campaignsResult: const AppSuccess<List<CatalogCampaign>>(
            <CatalogCampaign>[],
          ),
        );
        await tester.pumpAndSettle();

        // One section stacked strictly below the other: their titles are
        // far apart vertically instead of sharing a row.
        final collectionsTop = tester
            .getTopLeft(find.text('Coleções em destaque'))
            .dy;
        final newArrivalsTop = tester.getTopLeft(find.text('Lançamentos')).dy;
        expect(newArrivalsTop - collectionsTop, greaterThan(100));
      });
    });

    testWidgets('lays sections out side by side on desktop widths', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await _pumpCatalogHome(
          tester,
          width: 1300,
          collectionsResult: AppSuccess<List<Collection>>(<Collection>[
            buildTestCollection(id: 'col-1'),
          ]),
          productsResult: AppSuccess<List<Product>>(<Product>[
            buildTestCatalogHomeProduct(id: 'prod-1'),
          ]),
          campaignsResult: const AppSuccess<List<CatalogCampaign>>(
            <CatalogCampaign>[],
          ),
        );
        await tester.pumpAndSettle();

        // Both sections share (approximately) the same row instead of the
        // second one being pushed far below the first.
        final collectionsTop = tester
            .getTopLeft(find.text('Coleções em destaque'))
            .dy;
        final newArrivalsTop = tester.getTopLeft(find.text('Lançamentos')).dy;
        expect((newArrivalsTop - collectionsTop).abs(), lessThan(5));
      });
    });

    testWidgets('exposes each section to assistive technology by title', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await mockNetworkImagesFor(() async {
        await _pumpCatalogHome(
          tester,
          collectionsResult: AppSuccess<List<Collection>>(<Collection>[
            buildTestCollection(id: 'col-1'),
          ]),
          productsResult: const AppSuccess<List<Product>>(<Product>[]),
          campaignsResult: const AppSuccess<List<CatalogCampaign>>(
            <CatalogCampaign>[],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(RegExp('Coleções em destaque')),
          findsOneWidget,
        );
      });
      handle.dispose();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

const _shirt = AppProductCardData(
  id: 'sku-1',
  name: 'Camisa Social Slim',
  brandOrCollection: 'Coleção Verão',
  imageUrl: 'https://cdn.vestipro.test/sku-1.jpg',
  badgeLabels: ['Lançamento'],
);

void main() {
  group('AppProductCarousel', () {
    testWidgets('renders one card per product horizontally', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpApp(
          tester,
          AppProductCarousel(products: const [_shirt], onProductTap: (_) {}),
        );

        expect(find.text('Camisa Social Slim'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.scrollDirection, Axis.horizontal);
      });
    });

    testWidgets('renders nothing for an empty, non-loading carousel', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppProductCarousel(
          products: const <AppProductCardData>[],
          onProductTap: (_) {},
        ),
      );

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('renders skeleton cards while loading', (tester) async {
      await pumpApp(
        tester,
        AppProductCarousel(
          products: const <AppProductCardData>[],
          isLoading: true,
          loadingItemCount: 3,
          onProductTap: (_) {},
        ),
      );

      expect(find.byType(AppProductCardSkeleton), findsNWidgets(3));
    });

    testWidgets('invokes onProductTap with the tapped product', (tester) async {
      AppProductCardData? tapped;
      await mockNetworkImagesFor(() async {
        await pumpApp(
          tester,
          AppProductCarousel(
            products: const [_shirt],
            onProductTap: (product) => tapped = product,
          ),
        );

        await tester.tap(find.text('Camisa Social Slim'));
        await tester.pump();

        expect(tapped?.id, 'sku-1');
      });
    });
  });
}

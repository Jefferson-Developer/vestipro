import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

void main() {
  group('CatalogHomeSectionView', () {
    testWidgets('renders the section title and its items', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpApp(
          tester,
          CatalogHomeSectionView(
            section: const CatalogHomeSection(
              type: CatalogHomeSectionType.newArrivals,
              title: 'Lançamentos',
              order: 1,
              priority: 1,
              items: <CatalogHomeItem>[
                CatalogHomeItem(id: 'product-1', title: 'Camisa Slim'),
              ],
            ),
            onItemTap: (_) {},
          ),
        );

        expect(find.text('Lançamentos'), findsOneWidget);
        expect(find.text('Camisa Slim'), findsOneWidget);
      });
    });

    testWidgets('invokes onItemTap with the tapped item', (tester) async {
      CatalogHomeItem? tapped;
      const item = CatalogHomeItem(id: 'col-1', title: 'Verão 2026');
      await mockNetworkImagesFor(() async {
        await pumpApp(
          tester,
          CatalogHomeSectionView(
            section: const CatalogHomeSection(
              type: CatalogHomeSectionType.featuredCollections,
              title: 'Coleções em destaque',
              order: 0,
              priority: 0,
              items: <CatalogHomeItem>[item],
            ),
            onItemTap: (tappedItem) => tapped = tappedItem,
          ),
        );

        await tester.tap(find.text('Verão 2026'));
        await tester.pump();

        expect(tapped?.id, 'col-1');
      });
    });
  });
}

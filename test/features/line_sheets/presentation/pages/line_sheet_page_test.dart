import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/features/line_sheets/line_sheets.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

void main() {
  group('LineSheetPage', () {
    test(
      'denies a shared line sheet for a non-allowed customer/profile',
      () async {
        final repository = InMemoryLineSheetRepository(<LineSheet>[
          _buildLineSheet(
            accessPolicy: const LineSheetAccessPolicy(
              visibleProfiles: <LineSheetAccessProfile>{
                LineSheetAccessProfile.buyer,
              },
              showPrices: true,
              showStock: true,
              allowedCustomerIds: <String>{'customer-1'},
            ),
          ),
        ]);
        final result = await repository.getPublishedForCollection(
          organizationId: 'org-1',
          collectionId: 'col-1',
          profile: LineSheetAccessProfile.buyer,
          customerId: 'customer-2',
        );

        expect(
          result.fold(
            onSuccess: (_) => 'allowed',
            onFailure: (failure) => failure.code,
          ),
          'line_sheet_access_denied',
        );
      },
    );

    testWidgets(
      'renders a dense order form with a wide grid without overflow',
      (tester) async {
        final analytics = FakeAnalyticsService();
        final lineSheet = _buildLineSheet();
        final repository = InMemoryLineSheetRepository(<LineSheet>[lineSheet]);
        Object? snapshot;

        await pumpApp(
          tester,
          SizedBox(
            width: 390,
            height: 720,
            child: LineSheetPage(
              createCubit: () => _buildCubit(repository, analytics),
              onAddItemsToOrder: (_, versionSnapshot) {
                snapshot = versionSnapshot;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Order form'));
        await tester.pumpAndSettle();

        expect(find.text('48'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.enterText(find.bySemanticsLabel('Preto 38').first, '3');
        await tester.pumpAndSettle();

        expect(find.textContaining('3 pecas'), findsOneWidget);
        await tester.tap(find.text('Adicionar ao pedido'));
        await tester.pumpAndSettle();

        expect(snapshot, <String, Object?>{
          'line_sheet_id': 'sheet-1',
          'line_sheet_version': 3,
          'collection_id': 'col-1',
        });
        expect(
          analytics.loggedEvents.map((event) => event.name),
          containsAll(<String>[
            AnalyticsEvents.lineSheetOpened,
            AnalyticsEvents.lineSheetFiltered,
            AnalyticsEvents.lineSheetItemAdded,
          ]),
        );
      },
    );

    testWidgets('logs product view analytics from the visual line sheet', (
      tester,
    ) async {
      final analytics = FakeAnalyticsService();
      final repository = InMemoryLineSheetRepository(<LineSheet>[
        _buildLineSheet(),
      ]);

      await pumpApp(
        tester,
        SizedBox(
          width: 900,
          height: 720,
          child: LineSheetPage(
            createCubit: () => _buildCubit(repository, analytics),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Produto p1'));
      await tester.pumpAndSettle();

      expect(
        analytics.loggedEvents.map((event) => event.name),
        contains(AnalyticsEvents.lineSheetProductViewed),
      );
    });
  });
}

LineSheetCubit _buildCubit(
  LineSheetRepository repository,
  AnalyticsService analytics,
) {
  return LineSheetCubit(
    organizationId: 'org-1',
    collectionId: 'col-1',
    profile: LineSheetAccessProfile.buyer,
    customerId: 'customer-1',
    openLineSheet: OpenLineSheetUseCase(
      repository: repository,
      analyticsService: analytics,
    ),
    startOrderForm: const StartLineSheetOrderFormUseCase(),
    analyticsService: analytics,
  );
}

LineSheet _buildLineSheet({LineSheetAccessPolicy? accessPolicy}) {
  final now = DateTime.utc(2026, 9, 11, 12);
  return LineSheet(
    id: 'sheet-1',
    organizationId: 'org-1',
    collectionId: 'col-1',
    title: 'Line Sheet Verao 2027',
    version: 3,
    status: LineSheetStatus.published,
    accessPolicy:
        accessPolicy ??
        const LineSheetAccessPolicy(
          visibleProfiles: <LineSheetAccessProfile>{
            LineSheetAccessProfile.buyer,
            LineSheetAccessProfile.seller,
            LineSheetAccessProfile.salesManager,
          },
          showPrices: true,
          showStock: true,
          allowedCustomerIds: <String>{'customer-1'},
        ),
    productEntries: <LineSheetProductEntry>[_buildEntry()],
    publishedAt: now,
    updatedAt: now,
  );
}

LineSheetProductEntry _buildEntry() {
  final now = DateTime.utc(2026, 9, 11, 12);
  final sizes = List<SizeGridSize>.generate(
    11,
    (index) => SizeGridSize(
      id: '${38 + index}',
      organizationId: 'org-1',
      label: '${38 + index}',
      orderScore: index,
    ),
  );
  final colors = <ProductColor>[
    _buildColor('black', 'Preto', '#111111'),
    _buildColor('off', 'Off', '#EEEEEE'),
  ];
  final variants = <ProductVariant>[
    for (final color in colors)
      for (final size in sizes)
        ProductVariant(
          id: '${color.id}-${size.id}',
          organizationId: 'org-1',
          productId: 'p1',
          colorId: color.id,
          sizeGridTemplateId: 'grid-1',
          sizeId: size.id,
          sku: Sku.parse('SKU-${color.id}-${size.id}'),
          manualAvailableQuantity: size.id == '48' ? 0 : 12,
          manualAvailabilityStatus: size.id == '48'
              ? VariantAvailabilityStatus.unavailable
              : VariantAvailabilityStatus.readyStock,
          status: ProductVariantStatus.active,
          createdAt: now,
          createdBy: 'user-1',
          updatedAt: now,
          updatedBy: 'user-1',
          version: 1,
          syncStatus: ProductSyncStatus.synced,
        ),
  ];
  final availability = <String, VariantAvailability>{
    for (final variant in variants)
      variant.id: VariantAvailability.fromVariant(variant),
  };
  return LineSheetProductEntry(
    product: Product(
      id: 'p1',
      organizationId: 'org-1',
      sku: Sku.parse('SKU-P1'),
      reference: 'REF-P1',
      name: 'Produto p1',
      collectionId: 'col-1',
      status: ProductStatus.active,
      createdAt: now,
      createdBy: 'user-1',
      updatedAt: now,
      updatedBy: 'user-1',
      version: 1,
      syncStatus: ProductSyncStatus.synced,
    ),
    editorialOrder: 1,
    highlight: true,
    tags: const <String>['Best seller'],
    unitPrice: 33.5,
    stockUpdatedAt: now,
    colors: colors,
    sizes: sizes,
    variants: variants,
    availabilityByVariantId: availability,
  );
}

ProductColor _buildColor(String id, String name, String hex) {
  final now = DateTime.utc(2026, 9, 11, 12);
  return ProductColor(
    id: id,
    organizationId: 'org-1',
    code: id,
    name: name,
    hex: HexColor.parse(hex),
    status: ProductColorStatus.available,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

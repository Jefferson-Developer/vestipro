import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('UpsertPriceListItemsBatchUseCase', () {
    late _FakePriceListItemRepository repository;
    late UpsertPriceListItemsBatchUseCase useCase;

    setUp(() {
      repository = _FakePriceListItemRepository();
      useCase = UpsertPriceListItemsBatchUseCase(repository);
    });

    test('creates a new product price and variant exception batch', () async {
      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
        updatedBy: 'user-1',
        items: const <PriceListItemInput>[
          PriceListItemInput(productId: 'product-1', price: 189.9),
          PriceListItemInput(
            productId: 'product-1',
            variantId: 'variant-1',
            price: 199.9,
          ),
        ],
        now: DateTime.utc(2026, 6, 1),
      );

      expect(result, isA<AppSuccess<List<PriceListItem>>>());
      expect(repository.saved, hasLength(2));
      expect(repository.saved.last.variantId, 'variant-1');
    });

    test('blocks overwriting existing rows without confirmation', () async {
      repository.existing = <PriceListItem>[
        PriceListItem(
          id: PriceListItem.composeId(
            priceListId: 'price-list-1',
            productId: 'product-1',
          ),
          organizationId: 'org-1',
          companyId: 'company-1',
          priceListId: 'price-list-1',
          productId: 'product-1',
          price: 100,
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
        ),
      ];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
        updatedBy: 'user-1',
        items: const <PriceListItemInput>[
          PriceListItemInput(productId: 'product-1', price: 120),
        ],
      );

      expect(result, isA<AppFailure<List<PriceListItem>>>());
      expect(
        (result as AppFailure<List<PriceListItem>>).failure,
        isA<ConflictFailure>(),
      );
    });

    test(
      'rejects invalid values such as negative and non-numeric prices',
      () async {
        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceListId: 'price-list-1',
          updatedBy: 'user-1',
          items: const <PriceListItemInput>[
            PriceListItemInput(productId: 'product-1', price: -1),
            PriceListItemInput(
              productId: 'product-1',
              variantId: 'variant-1',
              price: double.nan,
            ),
          ],
        );

        expect(result, isA<AppFailure<List<PriceListItem>>>());
        expect(
          (result as AppFailure<List<PriceListItem>>).failure,
          isA<ValidationFailure>(),
        );
      },
    );
  });
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  List<PriceListItem> existing = <PriceListItem>[];
  List<PriceListItem> saved = <PriceListItem>[];

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) async {
    final ids = existing.map((item) => item.id).toSet();
    if (!confirmOverwrite && items.any((item) => ids.contains(item.id))) {
      return const AppFailure<List<PriceListItem>>(
        ConflictFailure(
          'Existing variant/product prices require explicit overwrite confirmation.',
          code: 'price_list_item_overwrite_confirmation_required',
        ),
      );
    }
    saved = items;
    return AppSuccess<List<PriceListItem>>(items);
  }
}

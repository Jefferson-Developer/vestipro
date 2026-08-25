import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_commercial_size_grid_draft_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesCommercialSizeGridDraftRepository', () {
    late SharedPreferencesCommercialSizeGridDraftRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesCommercialSizeGridDraftRepository();
    });

    test('persists quantities by organization and product', () async {
      final draft = CommercialSizeGridDraft(
        organizationId: 'org-1',
        productId: 'product-1',
        quantitiesByVariantId: const <String, int>{
          'variant-preto-p': 4,
          'variant-preto-m': 2,
        },
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      await repository.saveDraft(draft: draft);
      final loaded = await repository.getDraft(
        organizationId: 'org-1',
        productId: 'product-1',
      );

      final value = (loaded as AppSuccess<CommercialSizeGridDraft?>).value!;
      expect(value.quantitiesByVariantId, draft.quantitiesByVariantId);
      expect(value.totalQuantity, 6);

      final otherProduct = await repository.getDraft(
        organizationId: 'org-1',
        productId: 'product-2',
      );
      expect(
        (otherProduct as AppSuccess<CommercialSizeGridDraft?>).value,
        isNull,
      );
    });
  });
}

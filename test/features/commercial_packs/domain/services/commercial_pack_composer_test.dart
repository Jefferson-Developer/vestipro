import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

void main() {
  group('CommercialPackComposer.compose', () {
    test('fixed composition applies the same quantity to every resolved '
        'variant', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.product,
        scopeReferenceId: 'product-1',
        compositionType: PackComponentCompositionType.fixed,
        quantity: 2,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-p', productId: 'product-1'),
            (variantId: 'variant-m', productId: 'product-1'),
          ],
        },
      );

      final lines = _requireSuccess(result);
      expect(lines, hasLength(2));
      expect(lines.every((line) => line.quantity == 2), isTrue);
      expect(lines.every((line) => line.componentId == 'component-1'), isTrue);
    });

    test('rejects a fixed component with zero/negative quantity', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.fixed,
        quantity: 0,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        },
      );

      _requireValidationFailure(result, 'components[0].quantity');
    });

    test('flexible composition defaults to minQuantity when no override is '
        'given', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.flexible,
        minQuantity: 3,
        maxQuantity: 10,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        },
      );

      expect(_requireSuccess(result).single.quantity, 3);
    });

    test('flexible composition honors a valid override within range', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.flexible,
        minQuantity: 3,
        maxQuantity: 10,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        },
        quantityOverridesByComponent: <String, int>{'component-1': 7},
      );

      expect(_requireSuccess(result).single.quantity, 7);
    });

    test('rejects a flexible override outside the min/max range', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.flexible,
        minQuantity: 3,
        maxQuantity: 10,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        },
        quantityOverridesByComponent: <String, int>{'component-1': 99},
      );

      _requireValidationFailure(result, 'components[0].quantity');
    });

    test('gridProportion distributes the rounded absolute quantity evenly '
        'across resolved variants, remainder on the last one', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.color,
        scopeReferenceId: 'color-blue',
        compositionType: PackComponentCompositionType.gridProportion,
        proportion: 0.5,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-p', productId: 'product-1'),
            (variantId: 'variant-m', productId: 'product-1'),
            (variantId: 'variant-g', productId: 'product-1'),
          ],
        },
        totalGridQuantity: 10, // 50% of 10 = 5, split across 3 variants.
      );

      final lines = _requireSuccess(result);
      expect(lines.map((line) => line.quantity).toList(), <int>[2, 2, 1]);
      expect(lines.fold<int>(0, (sum, line) => sum + line.quantity), 5);
    });

    test('gridProportion requires totalGridQuantity', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.color,
        scopeReferenceId: 'color-blue',
        compositionType: PackComponentCompositionType.gridProportion,
        proportion: 0.5,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        },
      );

      _requireValidationFailure(result, 'totalGridQuantity');
    });

    test('fails the whole composition when a component resolves to no '
        'sellable variant — never silently skips it', () {
      final component = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.fixed,
        quantity: 1,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[component],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[],
        },
      );

      _requireValidationFailure(result, 'components[0].scopeReferenceId');
    });

    test('composes multiple components together, preserving isBonusItem', () {
      final fixedComponent = const PackComponent(
        id: 'component-1',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        compositionType: PackComponentCompositionType.fixed,
        quantity: 2,
      );
      final bonusComponent = const PackComponent(
        id: 'component-2',
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-2',
        compositionType: PackComponentCompositionType.fixed,
        quantity: 1,
        isBonusItem: true,
      );

      final result = CommercialPackComposer.compose(
        components: <PackComponent>[fixedComponent, bonusComponent],
        resolvedVariantsByComponent: <String, List<ResolvedComponentVariant>>{
          'component-1': <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
          'component-2': <ResolvedComponentVariant>[
            (variantId: 'variant-2', productId: 'product-2'),
          ],
        },
      );

      final lines = _requireSuccess(result);
      expect(lines, hasLength(2));
      expect(
        lines.firstWhere((line) => line.variantId == 'variant-2').isBonusItem,
        isTrue,
      );
      expect(
        lines.firstWhere((line) => line.variantId == 'variant-1').isBonusItem,
        isFalse,
      );
    });
  });
}

List<ResolvedPackLine> _requireSuccess(
  AppResult<List<ResolvedPackLine>> result,
) {
  return switch (result) {
    AppSuccess<List<ResolvedPackLine>>(value: final lines) => lines,
    AppFailure<List<ResolvedPackLine>>(failure: final failure) => fail(
      'Expected success, got failure: $failure',
    ),
  };
}

void _requireValidationFailure(
  AppResult<List<ResolvedPackLine>> result,
  String expectedFieldErrorKey,
) {
  switch (result) {
    case AppSuccess<List<ResolvedPackLine>>():
      fail('Expected a ValidationFailure, got success.');
    case AppFailure<List<ResolvedPackLine>>(failure: final failure):
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey(
          expectedFieldErrorKey,
        ),
        isTrue,
        reason:
            'Expected fieldErrors to contain "$expectedFieldErrorKey", got '
            '${failure.fieldErrors.keys}',
      );
  }
}

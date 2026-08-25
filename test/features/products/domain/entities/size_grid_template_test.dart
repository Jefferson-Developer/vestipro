import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/domain/usecases/size_grid_template_use_case_helpers.dart';
import 'package:vestipro/features/products/products.dart';

/// TASK-075 — Central commercial size ordering.
///
/// These tests guard the single shared comparator used by every screen that
/// lists sizes (grade comercial, formulário de cadastro de template e
/// relatórios), ensuring the order always follows the explicit
/// [SizeGridSize.orderScore] — never alphabetical order used as a silent
/// fallback.
void main() {
  group('compareSizeGridSizesByOrder / sortedByCommercialOrder', () {
    test('orders alphabetic commercial labels by explicit score', () {
      final sizes = <SizeGridSize>[
        _size('gg', 'GG', 5),
        _size('pp', 'PP', 1),
        _size('xgg', 'XGG', 6),
        _size('g', 'G', 4),
        _size('m', 'M', 3),
        _size('p', 'P', 2),
      ];

      final ordered = sizes.sortedByCommercialOrder();

      expect(ordered.map((size) => size.label), <String>[
        'PP',
        'P',
        'M',
        'G',
        'GG',
        'XGG',
      ]);
    });

    test('orders numeric commercial labels by explicit score', () {
      // Numeric labels are compared lexicographically as strings when used
      // as a fallback, which would wrongly place '36' before '4' — the
      // explicit score must be what drives the order here.
      final sizes = <SizeGridSize>[
        _size('s46', '46', 7),
        _size('s34', '34', 1),
        _size('s40', '40', 4),
        _size('s36', '36', 2),
        _size('s44', '44', 6),
        _size('s38', '38', 3),
        _size('s42', '42', 5),
      ];

      final ordered = sizes.sortedByCommercialOrder();

      expect(ordered.map((size) => size.label), <String>[
        '34',
        '36',
        '38',
        '40',
        '42',
        '44',
        '46',
      ]);
    });

    test('orders mixed alphabetic and numeric-suffixed labels by score', () {
      final sizes = <SizeGridSize>[
        _size('g3', 'G3', 6),
        _size('p', 'P', 1),
        _size('g1', 'G1', 4),
        _size('m', 'M', 2),
        _size('g', 'G', 3),
        _size('g2', 'G2', 5),
      ];

      final ordered = sizes.sortedByCommercialOrder();

      expect(ordered.map((size) => size.label), <String>[
        'P',
        'M',
        'G',
        'G1',
        'G2',
        'G3',
      ]);
    });

    test('breaks ties deterministically by label when scores are equal, '
        'without treating label order as the primary rule', () {
      final sizes = <SizeGridSize>[_size('b', 'M', 1), _size('a', 'G', 1)];

      final ordered = sizes.sortedByCommercialOrder();

      expect(ordered.map((size) => size.label), <String>['G', 'M']);
    });

    test('does not mutate the original list', () {
      final sizes = <SizeGridSize>[_size('g', 'G', 2), _size('p', 'P', 1)];

      sizes.sortedByCommercialOrder();

      expect(sizes.map((size) => size.label), <String>['G', 'P']);
    });
  });

  group('SizeGridTemplate.orderedSizes', () {
    test('applies the central comparator regardless of insertion order', () {
      final template = _template(<SizeGridSize>[
        _size('gg', 'GG', 4),
        _size('pp', 'PP', 1),
        _size('m', 'M', 3),
        _size('p', 'P', 2),
      ]);

      expect(template.orderedSizes.map((size) => size.label), <String>[
        'PP',
        'P',
        'M',
        'GG',
      ]);
    });
  });

  group('cross-screen ordering consistency (TASK-075)', () {
    test('grade comercial, formulário de cadastro e persistência de template '
        'exibem os mesmos tamanhos na mesma ordem para o mesmo template', () {
      final scrambled = <SizeGridSize>[
        _size('gg', 'GG', 4),
        _size('pp', 'PP', 1),
        _size('m', 'M', 3),
        _size('p', 'P', 2),
      ];
      final template = _template(scrambled);

      // Formulário de cadastro / página administrativa de templates.
      final formOrder = template.orderedSizes.map((size) => size.label);

      // Grade comercial (CommercialSizeGridState.orderedSizes).
      final commercialState = CommercialSizeGridState(
        sizeGridTemplate: template,
      );
      final commercialOrder = commercialState.orderedSizes.map(
        (size) => size.label,
      );

      // Normalização usada ao salvar/atualizar o template (persistência).
      final normalizedOrder = normalizeSizeGridSizes(
        scrambled,
      ).map((size) => size.label);

      expect(formOrder, <String>['PP', 'P', 'M', 'GG']);
      expect(commercialOrder, formOrder);
      expect(normalizedOrder, formOrder);
    });
  });
}

SizeGridSize _size(String id, String label, int orderScore) {
  return SizeGridSize(
    id: 'size-$id',
    organizationId: 'org-1',
    label: label,
    orderScore: orderScore,
  );
}

SizeGridTemplate _template(List<SizeGridSize> sizes) {
  final now = DateTime.utc(2026, 1, 1);
  return SizeGridTemplate(
    id: 'template-1',
    organizationId: 'org-1',
    name: 'Grade',
    sizes: sizes,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}

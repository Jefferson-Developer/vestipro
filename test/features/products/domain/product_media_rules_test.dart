import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

ProductMedia _photo({
  required String id,
  required int order,
  bool principal = false,
}) {
  return ProductMedia(
    id: id,
    type: ProductMediaType.photo,
    url: 'https://cdn.example.com/$id',
    order: order,
    principal: principal,
  );
}

ProductMedia _video({required String id, required int order}) {
  return ProductMedia(
    id: id,
    type: ProductMediaType.video,
    url: 'https://cdn.example.com/$id',
    order: order,
  );
}

void main() {
  group('appendProductMedia', () {
    test('assigns order 0 and makes the first photo principal', () {
      final result = appendProductMedia(
        const <ProductMedia>[],
        _photo(id: 'a.jpg', order: 99),
      );

      expect(result.single.order, 0);
      expect(result.single.principal, isTrue);
    });

    test('appends after the highest existing order of the same type', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
      ];

      final result = appendProductMedia(
        existing,
        _photo(id: 'c.jpg', order: 0),
      );

      expect(result.last.id, 'c.jpg');
      expect(result.last.order, 2);
      expect(
        result.last.principal,
        isFalse,
        reason: 'a principal already exists',
      );
    });

    test('videos and photos are ordered independently', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
      ];

      final result = appendProductMedia(
        existing,
        _video(id: 'clip.mp4', order: 0),
      );

      expect(result.last.order, 0, reason: 'first video, own sequence');
    });
  });

  group('reorderProductMedia', () {
    test('reassigns order to match the requested sequence', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
        _photo(id: 'c.jpg', order: 2),
      ];

      final result = reorderProductMedia(
        existing,
        type: ProductMediaType.photo,
        orderedIds: <String>['c.jpg', 'a.jpg', 'b.jpg'],
      );

      expect(result.firstWhere((m) => m.id == 'c.jpg').order, 0);
      expect(result.firstWhere((m) => m.id == 'a.jpg').order, 1);
      expect(result.firstWhere((m) => m.id == 'b.jpg').order, 2);
    });

    test('never touches items of a different type', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _video(id: 'clip.mp4', order: 0),
      ];

      final result = reorderProductMedia(
        existing,
        type: ProductMediaType.photo,
        orderedIds: <String>['a.jpg'],
      );

      expect(result.firstWhere((m) => m.id == 'clip.mp4').order, 0);
    });

    test('returns the list unchanged for a mismatched id set', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
      ];

      final result = reorderProductMedia(
        existing,
        type: ProductMediaType.photo,
        orderedIds: <String>['a.jpg'],
      );

      expect(result, same(existing));
    });
  });

  group('setPrincipalProductMedia', () {
    test('marks the target photo principal and unmarks every other', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
      ];

      final result = setPrincipalProductMedia(existing, mediaId: 'b.jpg');

      expect(result.firstWhere((m) => m.id == 'a.jpg').principal, isFalse);
      expect(result.firstWhere((m) => m.id == 'b.jpg').principal, isTrue);
    });

    test('never promotes a video to principal', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _video(id: 'clip.mp4', order: 0),
      ];

      final result = setPrincipalProductMedia(existing, mediaId: 'clip.mp4');

      expect(result, same(existing));
    });

    test('returns unchanged for an unknown id', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
      ];

      final result = setPrincipalProductMedia(existing, mediaId: 'missing');

      expect(result, same(existing));
    });
  });

  group('removeProductMedia', () {
    test('removes the item and compacts remaining order of its type', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
        _photo(id: 'c.jpg', order: 2),
      ];

      final result = removeProductMedia(existing, mediaId: 'b.jpg');

      expect(result.map((m) => m.id), <String>['a.jpg', 'c.jpg']);
      expect(result.firstWhere((m) => m.id == 'c.jpg').order, 1);
    });

    test(
      'auto-promotes the next remaining photo when the principal is removed',
      () {
        final existing = <ProductMedia>[
          _photo(id: 'a.jpg', order: 0, principal: true),
          _photo(id: 'b.jpg', order: 1),
        ];

        final result = removeProductMedia(existing, mediaId: 'a.jpg');

        expect(result.single.id, 'b.jpg');
        expect(result.single.principal, isTrue);
      },
    );

    test('leaves no principal photo when the only photo is removed (publish '
        'stays blocked until a new one is uploaded)', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
      ];

      final result = removeProductMedia(existing, mediaId: 'a.jpg');

      expect(result, isEmpty);
    });

    test('removing a non-principal item never touches who is principal', () {
      final existing = <ProductMedia>[
        _photo(id: 'a.jpg', order: 0, principal: true),
        _photo(id: 'b.jpg', order: 1),
      ];

      final result = removeProductMedia(existing, mediaId: 'b.jpg');

      expect(result.single.principal, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  group('sliceFetchedPage', () {
    test('returns hasMore=false when the fetch has no extra item', () {
      final result = sliceFetchedPage<int>([1, 2], 2);

      expect(result.items, [1, 2]);
      expect(result.hasMore, isFalse);
    });

    test('drops the extra (limit + 1)-th item and reports hasMore=true', () {
      final result = sliceFetchedPage<int>([1, 2, 3], 2);

      expect(result.items, [1, 2]);
      expect(result.hasMore, isTrue);
    });

    test(
      'a second page starting after the first cursor never repeats items',
      () {
        const source = [1, 2, 3, 4, 5];

        final page1 = sliceFetchedPage<int>(source.sublist(0, 3), 2);
        expect(page1.items, [1, 2]);
        expect(page1.hasMore, isTrue);

        // Simulates fetching limit+1 starting right after the last item of
        // page 1 (cursor = value 2), exactly like [FirestoreCollectionDataSource
        // .getPage] does with `startAfterDocument`.
        final page2 = sliceFetchedPage<int>(source.sublist(2, 5), 2);
        expect(page2.items, [3, 4]);
        expect(page2.hasMore, isTrue);

        expect(page1.items.toSet().intersection(page2.items.toSet()), isEmpty);
      },
    );

    test('a failure fetching the next page never mutates a previously '
        'returned page', () {
      final page1 = sliceFetchedPage<int>([1, 2, 3], 2);
      final page1ItemsBefore = List<int>.of(page1.items);

      expect(
        () => throw StateError('simulated failure fetching page 2'),
        throwsStateError,
      );

      expect(page1.items, page1ItemsBefore);
      expect(
        () => page1.items.add(99),
        throwsUnsupportedError,
        reason: 'a returned page must be immutable to callers',
      );
    });
  });
}

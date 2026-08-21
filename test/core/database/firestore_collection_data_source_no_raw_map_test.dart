import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'FirestoreCollectionDataSource never returns a raw Map<String, dynamic>',
    () {
      final source = File(
        'lib/core/database/firestore_collection_data_source.dart',
      ).readAsStringSync();

      final publicApiSignatures = RegExp(
        r'^\s{2}(Future<[^;{]+|Stream<[^;{]+)\{',
        multiLine: true,
      ).allMatches(source).toList();

      // Sanity-check the regex itself actually found the class's public
      // methods (getById, getStream, getPage, watchQuery, set, update) —
      // otherwise this test would pass vacuously if the file were rewritten.
      expect(publicApiSignatures.length, greaterThanOrEqualTo(6));

      for (final match in publicApiSignatures) {
        expect(
          match.group(0),
          isNot(contains('Map<String, dynamic>')),
          reason:
              '${match.group(0)} leaks a raw Firestore map to callers '
              'outside data/.',
        );
      }
    },
  );
}

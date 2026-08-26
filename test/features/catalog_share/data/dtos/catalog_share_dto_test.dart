import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_dto.dart';

void main() {
  group('CatalogShareDto.fromFirestore', () {
    Map<String, dynamic> validJson() {
      return <String, dynamic>{
        'organizationId': 'org-1',
        'scope': 'product',
        'items': <Map<String, dynamic>>[
          {'productId': 'product-1', 'name': 'Camisa Linho', 'imageUrl': null},
        ],
        'collectionId': null,
        'collectionName': null,
        'status': 'active',
        'openCount': 3,
        'firstOpenedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        'lastOpenedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 3)),
        'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
        'createdBy': 'rep-1',
        'createdByName': 'Rep Um',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      };
    }

    test('parses a well-formed Firestore document', () {
      final dto = CatalogShareDto.fromFirestore(validJson(), id: 'share-1');

      expect(dto.id, 'share-1');
      expect(dto.scope, 'product');
      expect(dto.items, hasLength(1));
      expect(dto.items.single.productId, 'product-1');
      expect(dto.openCount, 3);
      expect(dto.firstOpenedAt?.toUtc(), DateTime.utc(2026, 1, 2));
      expect(dto.expiresAt.toUtc(), DateTime.utc(2026, 2, 1));
    });

    test('accepts null firstOpenedAt/lastOpenedAt (never opened yet)', () {
      final json = Map<String, dynamic>.from(validJson())
        ..['firstOpenedAt'] = null
        ..['lastOpenedAt'] = null;

      final dto = CatalogShareDto.fromFirestore(json, id: 'share-1');

      expect(dto.firstOpenedAt, isNull);
      expect(dto.lastOpenedAt, isNull);
    });

    test(
      'throws ValidationException for each required field missing/wrong-typed',
      () {
        for (final field in <String>[
          'organizationId',
          'scope',
          'items',
          'status',
          'openCount',
          'expiresAt',
          'createdBy',
          'createdByName',
          'createdAt',
          'updatedAt',
        ]) {
          final json = Map<String, dynamic>.from(validJson())..remove(field);
          expect(
            () => CatalogShareDto.fromFirestore(json, id: 'share-1'),
            throwsA(isA<ValidationException>()),
            reason: 'field: $field',
          );
        }
      },
    );
  });
}

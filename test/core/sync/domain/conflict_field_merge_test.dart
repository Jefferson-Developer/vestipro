import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/sync/sync.dart';

void main() {
  group('ConflictFieldMerge.compute', () {
    test(
      'changes in distinct fields are combined correctly, with no conflict',
      () {
        final result = ConflictFieldMerge.compute(
          base: const <String, Object?>{
            'phone': '1111-1111',
            'address': 'Rua A, 100',
            'name': 'Loja A',
          },
          local: const <String, Object?>{
            'phone': '1111-1111',
            'address': 'Rua B, 200', // changed locally
            'name': 'Loja A',
          },
          remote: const <String, Object?>{
            'phone': '2222-2222', // changed remotely
            'address': 'Rua A, 100',
            'name': 'Loja A',
          },
        );

        expect(result.hasConflict, isFalse);
        expect(result.conflictingFields, isEmpty);
        expect(result.mergedFields, {'address'});
        expect(result.mergedData, <String, Object?>{
          'phone': '2222-2222',
          'address': 'Rua B, 200',
          'name': 'Loja A',
        });
      },
    );

    test('the same field changed on both sides to different values is reported '
        'as a conflict, never merged silently', () {
      final result = ConflictFieldMerge.compute(
        base: const <String, Object?>{'phone': '1111-1111'},
        local: const <String, Object?>{'phone': '2222-2222'},
        remote: const <String, Object?>{'phone': '3333-3333'},
      );

      expect(result.hasConflict, isTrue);
      expect(result.conflictingFields, {'phone'});
      expect(result.mergedData, isEmpty);
      expect(result.mergedFields, isEmpty);
    });

    test('the same field changed on both sides to the exact same value is not '
        'a conflict', () {
      final result = ConflictFieldMerge.compute(
        base: const <String, Object?>{'phone': '1111-1111'},
        local: const <String, Object?>{'phone': '2222-2222'},
        remote: const <String, Object?>{'phone': '2222-2222'},
      );

      expect(result.hasConflict, isFalse);
      expect(result.mergedData['phone'], '2222-2222');
    });

    test('a field present only in remote (new field) is kept in the merge', () {
      final result = ConflictFieldMerge.compute(
        base: const <String, Object?>{'name': 'Loja A'},
        local: const <String, Object?>{'name': 'Loja A'},
        remote: const <String, Object?>{'name': 'Loja A', 'segment': 'Varejo'},
      );

      expect(result.hasConflict, isFalse);
      expect(result.mergedData['segment'], 'Varejo');
      expect(result.mergedFields, isEmpty);
    });

    test('no changes on either side merges without conflict or diff', () {
      final result = ConflictFieldMerge.compute(
        base: const <String, Object?>{'name': 'Loja A'},
        local: const <String, Object?>{'name': 'Loja A'},
        remote: const <String, Object?>{'name': 'Loja A'},
      );

      expect(result.hasConflict, isFalse);
      expect(result.mergedFields, isEmpty);
      expect(result.mergedData, <String, Object?>{'name': 'Loja A'});
    });
  });
}

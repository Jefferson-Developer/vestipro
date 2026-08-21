import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

class _SampleEntity {
  const _SampleEntity({required this.id, required this.name});

  final String id;
  final String name;
}

final _sampleConverter = FirestoreConverter<_SampleEntity>(
  fromJson: (data, id) =>
      _SampleEntity(id: id, name: data['name'] as String? ?? ''),
  toJson: (value) => {'name': value.name},
);

void main() {
  group('FirestoreConverter', () {
    test('fromSnapshotData builds a typed entity from document data', () {
      final entity = _sampleConverter.fromSnapshotData({
        'name': 'Malwee',
      }, 'doc-1');

      expect(entity.id, 'doc-1');
      expect(entity.name, 'Malwee');
    });

    test('fromSnapshotData falls back to an empty map when data is null', () {
      final entity = _sampleConverter.fromSnapshotData(null, 'doc-2');

      expect(entity.id, 'doc-2');
      expect(entity.name, '');
    });

    test('toDocumentData serializes the entity back into a flat map', () {
      final data = _sampleConverter.toDocumentData(
        const _SampleEntity(id: 'doc-1', name: 'Malwee'),
      );

      expect(data, {'name': 'Malwee'});
    });
  });
}

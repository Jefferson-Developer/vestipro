import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/branch_dto.dart';

void main() {
  group('BranchDto', () {
    final addressJson = <String, dynamic>{
      'street': 'Rua XV de Novembro',
      'number': '100',
      'complement': null,
      'neighborhood': 'Centro',
      'city': 'Blumenau',
      'state': 'SC',
      'postalCode': '89010-000',
      'country': 'BR',
    };

    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'companyId': 'company-1',
      'name': 'Loja Blumenau',
      'type': 'store',
      'address': addressJson,
      'status': 'active',
      'version': 1,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'user-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'user-1',
    };

    test(
      'fromJson parses a full Firestore payload, id supplied out-of-band',
      () {
        final dto = BranchDto.fromJson(json, id: 'branch-1');

        expect(dto.id, 'branch-1');
        expect(dto.organizationId, 'org-1');
        expect(dto.companyId, 'company-1');
        expect(dto.type, 'store');
        expect(dto.address, isNotNull);
        expect(dto.address!.street, 'Rua XV de Novembro');
        expect(dto.version, 1);
      },
    );

    test('fromJson parses a payload without an address (null)', () {
      final minimalJson = Map<String, dynamic>.of(json)..remove('address');

      final dto = BranchDto.fromJson(minimalJson, id: 'branch-1');

      expect(dto.address, isNull);
    });

    test('toJson never includes id as one of its keys', () {
      final dto = BranchDto.fromJson(json, id: 'branch-1');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['companyId'], 'company-1');
    });

    test('fromJson throws ValidationException for a missing companyId', () {
      final invalidJson = Map<String, dynamic>.of(json)..remove('companyId');

      expect(
        () => BranchDto.fromJson(invalidJson, id: 'branch-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws ValidationException for a malformed address', () {
      final invalidJson = Map<String, dynamic>.of(json)
        ..['address'] = 'not-a-map';

      expect(
        () => BranchDto.fromJson(invalidJson, id: 'branch-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

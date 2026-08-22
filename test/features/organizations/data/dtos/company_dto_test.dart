import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/company_dto.dart';

void main() {
  group('CompanyDto', () {
    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'name': 'Marca A',
      'legalName': 'Marca A Confecções Ltda',
      'taxId': '12.345.678/0001-90',
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
        final dto = CompanyDto.fromJson(json, id: 'company-1');

        expect(dto.id, 'company-1');
        expect(dto.organizationId, 'org-1');
        expect(dto.legalName, 'Marca A Confecções Ltda');
        expect(dto.taxId, '12.345.678/0001-90');
        expect(dto.version, 1);
      },
    );

    test('fromJson parses a payload without legalName/taxId (both null)', () {
      final minimalJson = Map<String, dynamic>.of(json)
        ..remove('legalName')
        ..remove('taxId');

      final dto = CompanyDto.fromJson(minimalJson, id: 'company-1');

      expect(dto.legalName, isNull);
      expect(dto.taxId, isNull);
    });

    test('toJson never includes id as one of its keys', () {
      final dto = CompanyDto.fromJson(json, id: 'company-1');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['organizationId'], 'org-1');
    });

    test(
      'fromJson throws ValidationException for a missing organizationId',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..remove('organizationId');

        expect(
          () => CompanyDto.fromJson(invalidJson, id: 'company-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('fromJson throws ValidationException for a non-int version', () {
      final invalidJson = Map<String, dynamic>.of(json)..['version'] = '1';

      expect(
        () => CompanyDto.fromJson(invalidJson, id: 'company-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

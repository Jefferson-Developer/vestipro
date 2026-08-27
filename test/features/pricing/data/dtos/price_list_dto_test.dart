import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/pricing/data/dtos/price_list_dto.dart';

void main() {
  group('PriceListDto', () {
    Map<String, dynamic> validJson({Map<String, dynamic>? overrides}) {
      final base = <String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'name': 'Tabela Padrão',
        'currency': 'BRL',
        'validFrom': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'validTo': Timestamp.fromDate(DateTime.utc(2026, 12, 31)),
        'status': 'active',
        'scope': 'company',
        'scopeValue': null,
        'priority': 0,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'createdBy': 'user-1',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'updatedBy': 'user-1',
        'deletedAt': null,
        'version': 1,
        'syncStatus': 'synced',
      };
      base.addAll(overrides ?? const <String, dynamic>{});
      return base;
    }

    test('fromJson parses a valid payload', () {
      final dto = PriceListDto.fromJson(validJson(), id: 'price-list-1');

      expect(dto.id, 'price-list-1');
      expect(dto.currency, 'BRL');
      expect(dto.scope, 'company');
      expect(dto.status, 'active');
    });

    test('fromJson throws when currency is missing', () {
      final json = validJson()..remove('currency');

      expect(
        () => PriceListDto.fromJson(json, id: 'price-list-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws when scope is missing', () {
      final json = validJson()..remove('scope');

      expect(
        () => PriceListDto.fromJson(json, id: 'price-list-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws when organizationId is missing', () {
      final json = validJson()..remove('organizationId');

      expect(
        () => PriceListDto.fromJson(json, id: 'price-list-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('toJson round-trips through fromJson', () {
      final dto = PriceListDto.fromJson(validJson(), id: 'price-list-1');
      final roundTripped = PriceListDto.fromJson(dto.toJson(), id: dto.id);

      expect(roundTripped.currency, dto.currency);
      expect(roundTripped.scope, dto.scope);
      expect(roundTripped.validFrom, dto.validFrom);
      expect(roundTripped.validTo, dto.validTo);
    });
  });
}

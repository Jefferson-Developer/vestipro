import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customer_import/customer_import.dart';

void main() {
  group('validateCustomerImportMapping', () {
    test('accepts a mapping with document and a name field, no collisions', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
          CustomerImportField.legalName: 1,
          CustomerImportField.primaryEmail: 2,
        },
      );

      expect(validateCustomerImportMapping(mapping), isEmpty);
    });

    test('rejects a mapping missing the document column', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.legalName: 0,
        },
      );

      final errors = validateCustomerImportMapping(mapping);
      expect(errors, contains(CustomerImportField.document.code));
    });

    test('rejects a mapping with no name field mapped at all', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
        },
      );

      final errors = validateCustomerImportMapping(mapping);
      expect(errors, contains('name'));
    });

    test('accepts tradeName alone as satisfying the "any name field" rule', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
          CustomerImportField.tradeName: 1,
        },
      );

      expect(validateCustomerImportMapping(mapping), isEmpty);
    });

    test('accepts fullName alone as satisfying the "any name field" rule', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: false,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
          CustomerImportField.fullName: 1,
        },
      );

      expect(validateCustomerImportMapping(mapping), isEmpty);
    });

    test('rejects two fields mapped to the very same column', () {
      final mapping = CustomerImportMapping(
        hasHeaderRow: true,
        columnByField: const <CustomerImportField, int>{
          CustomerImportField.document: 0,
          CustomerImportField.legalName: 1,
          CustomerImportField.tradeName: 1,
        },
      );

      final errors = validateCustomerImportMapping(mapping);
      expect(errors, contains(CustomerImportField.legalName.code));
      expect(errors, contains(CustomerImportField.tradeName.code));
    });
  });

  group('CustomerImportField.fromCode', () {
    test('round-trips every value through its own code', () {
      for (final field in CustomerImportField.values) {
        expect(CustomerImportFieldCode.fromCode(field.code), field);
      }
    });

    test('returns null for an unknown code', () {
      expect(CustomerImportFieldCode.fromCode('not-a-real-field'), isNull);
    });
  });
}

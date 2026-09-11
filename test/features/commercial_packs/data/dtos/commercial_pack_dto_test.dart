import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/commercial_packs/data/dtos/commercial_pack_dto.dart';

void main() {
  group('CommercialPackDto', () {
    Map<String, dynamic> validJson({Map<String, dynamic>? overrides}) {
      final base = <String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'packCode': 'PACK-1',
        'version': 1,
        'name': 'Kit Verão',
        'description': null,
        'packType': 'kit',
        'status': 'active',
        'pricingPolicyType': 'componentSum',
        'fixedPrice': null,
        'discountPercentage': null,
        'bonusComponentId': null,
        'stockPolicyType': 'consumeComponentBalances',
        'dedicatedWarehouseId': null,
        'collectionId': null,
        'campaignId': null,
        'customerSegment': null,
        'channel': null,
        'validFrom': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'validTo': Timestamp.fromDate(DateTime.utc(2026, 12, 31)),
        'components': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'component-1',
            'scopeType': 'variant',
            'scopeReferenceId': 'variant-1',
            'compositionType': 'fixed',
            'quantity': 2,
            'minQuantity': null,
            'maxQuantity': null,
            'proportion': null,
            'isBonusItem': false,
          },
        ],
        'assortmentRules': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'createdBy': 'user-1',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'updatedBy': 'user-1',
        'deletedAt': null,
        'supersededByPackId': null,
        'syncStatus': 'synced',
      };
      base.addAll(overrides ?? const <String, dynamic>{});
      return base;
    }

    test('fromJson parses a valid payload', () {
      final dto = CommercialPackDto.fromJson(validJson(), id: 'pack-1');

      expect(dto.id, 'pack-1');
      expect(dto.packCode, 'PACK-1');
      expect(dto.version, 1);
      expect(dto.components, hasLength(1));
      expect(dto.components.single.scopeReferenceId, 'variant-1');
    });

    test('fromJson throws when organizationId is missing', () {
      final json = validJson()..remove('organizationId');

      expect(
        () => CommercialPackDto.fromJson(json, id: 'pack-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws when packCode is missing', () {
      final json = validJson()..remove('packCode');

      expect(
        () => CommercialPackDto.fromJson(json, id: 'pack-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws when a nested component payload is malformed', () {
      final json = validJson(
        overrides: <String, dynamic>{
          'components': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'component-1'},
          ],
        },
      );

      expect(
        () => CommercialPackDto.fromJson(json, id: 'pack-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('toJson round-trips through fromJson, including nested components '
        'and assortment rules', () {
      final json = validJson(
        overrides: <String, dynamic>{
          'components': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'component-1',
              'scopeType': 'color',
              'scopeReferenceId': 'color-blue',
              'compositionType': 'gridProportion',
              'quantity': null,
              'minQuantity': null,
              'maxQuantity': null,
              'proportion': 0.3,
              'isBonusItem': false,
            },
          ],
          'assortmentRules': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'rule-1',
              'type': 'minPercentagePerColor',
              'colorId': 'color-blue',
              'sizeId': null,
              'minPercentage': 0.3,
              'minQuantity': null,
            },
          ],
        },
      );
      final dto = CommercialPackDto.fromJson(json, id: 'pack-1');

      final roundTripped = CommercialPackDto.fromJson(dto.toJson(), id: dto.id);

      expect(roundTripped.packCode, dto.packCode);
      expect(roundTripped.version, dto.version);
      expect(roundTripped.components.single.proportion, 0.3);
      expect(roundTripped.assortmentRules.single.minPercentage, 0.3);
    });
  });
}

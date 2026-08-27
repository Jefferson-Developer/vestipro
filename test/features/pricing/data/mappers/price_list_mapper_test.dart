import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/pricing/data/mappers/price_list_mapper.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('PriceListMapper', () {
    const mapper = PriceListMapper();
    final now = DateTime.utc(2026, 1, 1);

    PriceList priceList() {
      return PriceList(
        id: 'price-list-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Tabela Padrão',
        currency: 'BRL',
        validFrom: now,
        validTo: now.add(const Duration(days: 365)),
        status: PriceListStatus.active,
        scope: PriceListScopeType.channel,
        scopeValue: 'wholesale',
        priority: 5,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 2,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    test('toDto/toEntity round-trip preserves every field', () {
      final original = priceList();

      final roundTripped = mapper.toEntity(mapper.toDto(original));

      expect(roundTripped, original);
    });

    test('statusToDto/statusToEntity round-trip for every PriceListStatus', () {
      for (final status in PriceListStatus.values) {
        expect(mapper.statusToEntity(mapper.statusToDto(status)), status);
      }
    });

    test(
      'scopeToDto/scopeToEntity round-trip for every PriceListScopeType',
      () {
        for (final scope in PriceListScopeType.values) {
          expect(mapper.scopeToEntity(mapper.scopeToDto(scope)), scope);
        }
      },
    );

    test('syncStatusToDto/syncStatusToEntity round-trip for every '
        'PriceListSyncStatus', () {
      for (final syncStatus in PriceListSyncStatus.values) {
        expect(
          mapper.syncStatusToEntity(mapper.syncStatusToDto(syncStatus)),
          syncStatus,
        );
      }
    });

    test('statusToEntity rejects an unknown code', () {
      expect(
        () => mapper.statusToEntity('unknown'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scopeToEntity rejects an unknown code', () {
      expect(
        () => mapper.scopeToEntity('unknown'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/data/mappers/price_list_mapper.dart';
import 'package:vestipro/features/pricing/data/repositories/shared_preferences_price_list_repository.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('SharedPreferencesPriceListRepository', () {
    late SharedPreferencesPriceListRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPreferencesPriceListRepository(
        const PriceListMapper(),
      );
    });

    PriceList priceList({
      String id = 'price-list-1',
      String organizationId = 'org-1',
      String companyId = 'company-1',
      String currency = 'BRL',
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return PriceList(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: 'Tabela Padrão',
        currency: currency,
        validFrom: now,
        status: PriceListStatus.draft,
        scope: PriceListScopeType.company,
        priority: 0,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: PriceListSyncStatus.pending,
      );
    }

    test('creates and retrieves a price list by id', () async {
      final createResult = await repository.create(priceList: priceList());
      final getResult = await repository.getById(
        organizationId: 'org-1',
        id: 'price-list-1',
      );

      expect(createResult, isA<AppSuccess<PriceList>>());
      expect((getResult as AppSuccess<PriceList?>).value?.id, 'price-list-1');
    });

    test('rejects creating two price lists with the same id', () async {
      await repository.create(priceList: priceList());

      final result = await repository.create(priceList: priceList());

      expect(result, isA<AppFailure<PriceList>>());
      expect((result as AppFailure<PriceList>).failure, isA<ConflictFailure>());
    });

    test('listByCompany returns only price lists of that company', () async {
      await repository.create(
        priceList: priceList(id: 'a', companyId: 'company-1'),
      );
      await repository.create(
        priceList: priceList(id: 'b', companyId: 'company-2'),
      );

      final result = await repository.listByCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      final list = (result as AppSuccess<List<PriceList>>).value;
      expect(list.map((p) => p.id), <String>['a']);
    });

    test('update succeeds when the currency stays the same', () async {
      final created = await repository.create(priceList: priceList());
      final toUpdate = (created as AppSuccess<PriceList>).value.copyWith(
        name: 'Tabela Renomeada',
      );

      final result = await repository.update(priceList: toUpdate);

      expect(result, isA<AppSuccess<PriceList>>());
    });

    test('update rejects a currency change (immutability rule)', () async {
      await repository.create(priceList: priceList(currency: 'BRL'));

      final result = await repository.update(
        priceList: priceList(currency: 'USD'),
      );

      expect(result, isA<AppFailure<PriceList>>());
      expect(
        (result as AppFailure<PriceList>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('update fails for a price list that does not exist', () async {
      final result = await repository.update(priceList: priceList());

      expect(result, isA<AppFailure<PriceList>>());
      expect((result as AppFailure<PriceList>).failure, isA<NotFoundFailure>());
    });
  });
}

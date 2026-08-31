import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('LoadInitialPriceListOfflineDataUseCase', () {
    late _FakePriceListRepository repository;
    late _FakePriceListLocalStoreRepository localStore;
    late LoadInitialPriceListOfflineDataUseCase useCase;

    setUp(() {
      repository = _FakePriceListRepository();
      localStore = _FakePriceListLocalStoreRepository();
      useCase = LoadInitialPriceListOfflineDataUseCase(repository, localStore);
    });

    PriceList priceList(String id) {
      final now = DateTime.utc(2026, 1, 1);
      return PriceList(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Tabela $id',
        currency: 'BRL',
        validFrom: now,
        status: PriceListStatus.active,
        scope: PriceListScopeType.company,
        priority: 1,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    test('rejects an invalid payload before touching any repository', () async {
      final result = await useCase(organizationId: '', companyId: 'company-1');

      expect(result, isA<AppFailure<int>>());
      expect(localStore.replaceCalls, isEmpty);
    });

    test(
      'replaces the local price list cache with every company price list',
      () async {
        repository.priceLists.addAll(<PriceList>[
          priceList('a'),
          priceList('b'),
        ]);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        expect(result, isA<AppSuccess<int>>());
        expect((result as AppSuccess<int>).value, 2);
        expect(localStore.replaceCalls, hasLength(1));
        expect(
          localStore.replaceCalls.single.map((p) => p.id).toSet(),
          <String>{'a', 'b'},
        );
      },
    );

    test('propagates a remote repository failure without touching the local '
        'store', () async {
      repository.listFailure = const ConnectivityFailure('offline');

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(result, isA<AppFailure<int>>());
      expect(localStore.replaceCalls, isEmpty);
    });
  });
}

final class _FakePriceListRepository implements PriceListRepository {
  final List<PriceList> priceLists = <PriceList>[];
  Failure? listFailure;

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    if (listFailure != null) {
      return AppFailure<List<PriceList>>(listFailure!);
    }
    return AppSuccess<List<PriceList>>(List<PriceList>.of(priceLists));
  }

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePriceListLocalStoreRepository
    implements PriceListLocalStoreRepository {
  final List<List<PriceList>> replaceCalls = <List<PriceList>>[];

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PriceList> priceLists,
  }) async {
    replaceCalls.add(priceLists);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> upsert({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceList>>> getAll({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<int>(replaceCalls.isEmpty ? 0 : replaceCalls.last.length);
  }
}

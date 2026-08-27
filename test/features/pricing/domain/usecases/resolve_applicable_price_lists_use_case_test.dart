import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ResolveApplicablePriceListsUseCase', () {
    final now = DateTime.utc(2026, 6, 1);

    PriceList priceList({
      required String id,
      PriceListStatus status = PriceListStatus.active,
      DateTime? validFrom,
      DateTime? validTo,
      PriceListScopeType scope = PriceListScopeType.company,
      String? scopeValue,
      int priority = 0,
      String organizationId = 'org-1',
      String companyId = 'company-1',
    }) {
      return PriceList(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: id,
        currency: 'BRL',
        validFrom: validFrom ?? DateTime.utc(2026, 1, 1),
        validTo: validTo,
        status: status,
        scope: scope,
        scopeValue: scopeValue,
        priority: priority,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    test('returns an empty list when no price list is vigent', () async {
      final repository = _FakePriceListRepository(<PriceList>[
        priceList(id: 'draft', status: PriceListStatus.draft),
      ]);
      final useCase = ResolveApplicablePriceListsUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        now: now,
      );

      expect(result, isA<AppSuccess<List<PriceList>>>());
      expect((result as AppSuccess<List<PriceList>>).value, isEmpty);
    });

    test('returns the single vigent price list', () async {
      final repository = _FakePriceListRepository(<PriceList>[
        priceList(id: 'active'),
      ]);
      final useCase = ResolveApplicablePriceListsUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        now: now,
      );

      final value = (result as AppSuccess<List<PriceList>>).value;
      expect(value.map((p) => p.id), <String>['active']);
    });

    test(
      'orders multiple vigent price lists by priority, highest first',
      () async {
        final repository = _FakePriceListRepository(<PriceList>[
          priceList(id: 'low', priority: 1),
          priceList(id: 'high', priority: 10),
          priceList(id: 'medium', priority: 5),
        ]);
        final useCase = ResolveApplicablePriceListsUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          now: now,
        );

        final value = (result as AppSuccess<List<PriceList>>).value;
        expect(value.map((p) => p.id), <String>['high', 'medium', 'low']);
      },
    );

    test(
      'excludes an expired (date-wise) price list even if flagged active',
      () async {
        final repository = _FakePriceListRepository(<PriceList>[
          priceList(
            id: 'expired',
            validFrom: DateTime.utc(2025, 1, 1),
            validTo: DateTime.utc(2025, 12, 31),
          ),
          priceList(id: 'active'),
        ]);
        final useCase = ResolveApplicablePriceListsUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          now: now,
        );

        final value = (result as AppSuccess<List<PriceList>>).value;
        expect(value.map((p) => p.id), <String>['active']);
      },
    );

    test('excludes a scheduled (not yet started) price list', () async {
      final repository = _FakePriceListRepository(<PriceList>[
        priceList(id: 'future', validFrom: DateTime.utc(2027, 1, 1)),
        priceList(id: 'active'),
      ]);
      final useCase = ResolveApplicablePriceListsUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        now: now,
      );

      final value = (result as AppSuccess<List<PriceList>>).value;
      expect(value.map((p) => p.id), <String>['active']);
    });

    test(
      'only returns price lists matching the customer channel/segment scope',
      () async {
        final repository = _FakePriceListRepository(<PriceList>[
          priceList(
            id: 'wholesale-channel',
            scope: PriceListScopeType.channel,
            scopeValue: 'wholesale',
            priority: 10,
          ),
          priceList(
            id: 'vip-segment',
            scope: PriceListScopeType.segment,
            scopeValue: 'vip',
            priority: 10,
          ),
          priceList(id: 'company-wide', priority: 1),
        ]);
        final useCase = ResolveApplicablePriceListsUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerChannel: 'wholesale',
          customerSegment: 'regular',
          now: now,
        );

        final value = (result as AppSuccess<List<PriceList>>).value;
        expect(value.map((p) => p.id), <String>[
          'wholesale-channel',
          'company-wide',
        ]);
      },
    );

    test('rejects a missing organizationId/companyId', () async {
      final repository = _FakePriceListRepository(<PriceList>[]);
      final useCase = ResolveApplicablePriceListsUseCase(repository);

      final result = await useCase(organizationId: '', companyId: '');

      expect(result, isA<AppFailure<List<PriceList>>>());
    });
  });
}

final class _FakePriceListRepository implements PriceListRepository {
  _FakePriceListRepository(this._priceLists);

  final List<PriceList> _priceLists;

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

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PriceList>>(
      _priceLists
          .where(
            (priceList) =>
                priceList.organizationId == organizationId &&
                priceList.companyId == companyId,
          )
          .toList(growable: false),
    );
  }
}

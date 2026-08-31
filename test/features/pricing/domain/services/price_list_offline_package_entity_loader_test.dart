import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/permissions/permission_service.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('PriceListOfflinePackageEntityLoader', () {
    late _FakePriceListRepository priceListRepository;
    late _FakePriceListLocalStoreRepository localStore;
    late _FakeMembershipRepository membershipRepository;
    late PriceListOfflinePackageEntityLoader loader;

    setUp(() {
      priceListRepository = _FakePriceListRepository();
      localStore = _FakePriceListLocalStoreRepository();
      membershipRepository = _FakeMembershipRepository();
      loader = PriceListOfflinePackageEntityLoader(
        LoadInitialPriceListOfflineDataUseCase(priceListRepository, localStore),
        localStore,
        PermissionService(membershipRepository),
      );
    });

    test('kind is priceLists', () {
      expect(loader.kind, OfflinePackageEntityKind.priceLists);
    });

    test('is applicable for a SALES_REP (has orderCreate)', () async {
      membershipRepository.membership = _membership(roleName: 'SALES_REP');

      final result = await loader.isApplicable(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isTrue);
    });

    test('is not applicable for a READ_ONLY role', () async {
      membershipRepository.membership = _membership(roleName: 'READ_ONLY');

      final result = await loader.isApplicable(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('load replaces the local cache and reports progress once', () async {
      priceListRepository.priceLists.add(_priceList('a'));
      priceListRepository.priceLists.add(_priceList('b'));
      final reported = <int>[];

      final result = await loader.load(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
        cancellationToken: OfflinePackageCancellationToken(),
        onProgress: reported.add,
      );

      expect(result, isA<AppSuccess<OfflinePackageEntityLoadResult>>());
      final entityResult =
          (result as AppSuccess<OfflinePackageEntityLoadResult>).value;
      expect(entityResult.outcome, OfflinePackageEntityLoadOutcome.completed);
      expect(entityResult.recordCount, 2);
      expect(reported, <int>[2]);
    });

    test(
      'load never touches the remote/local store once already cancelled',
      () async {
        priceListRepository.priceLists.add(_priceList('a'));
        final token = OfflinePackageCancellationToken()..cancel();

        final result = await loader.load(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'user-1',
          cancellationToken: token,
          onProgress: (_) {},
        );

        expect(result, isA<AppSuccess<OfflinePackageEntityLoadResult>>());
        final entityResult =
            (result as AppSuccess<OfflinePackageEntityLoadResult>).value;
        expect(entityResult.outcome, OfflinePackageEntityLoadOutcome.cancelled);
        expect(entityResult.recordCount, 0);
        expect(localStore.replaceCalls, isEmpty);
      },
    );
  });
}

PriceList _priceList(String id) {
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

Membership _membership({required String roleName}) {
  final now = DateTime.utc(2026, 1, 1);
  return Membership(
    id: 'membership-1',
    organizationId: 'org-1',
    userId: 'user-1',
    roleId: 'role-1',
    roleName: roleName,
    status: MembershipStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

final class _FakePriceListRepository implements PriceListRepository {
  final List<PriceList> priceLists = <PriceList>[];

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
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
    return const AppSuccess<int>(0);
  }
}

final class _FakeMembershipRepository implements MembershipRepository {
  Membership? membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    final current = membership;
    if (current == null) {
      return const AppFailure<Membership>(NotFoundFailure('not found'));
    }
    return AppSuccess<Membership>(current);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) {
    throw UnimplementedError();
  }
}

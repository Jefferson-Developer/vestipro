import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  group('AggregationRepositoryImpl', () {
    late _FakeAggregationRemoteDataSource remote;
    late DateTime clock;
    late AggregationRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      remote = _FakeAggregationRemoteDataSource();
      clock = DateTime.utc(2026, 8, 15, 10);
      repository = AggregationRepositoryImpl(
        remote,
        const AggregationSnapshotMapper(),
        now: () => clock,
      );
    });

    test('getSnapshot returns null (not a failure) when the aggregation layer '
        'has not produced a snapshot yet for that period', () async {
      final result = await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'company-1',
        periodKey: '2026-08-15',
      );
      expect(result, isA<AppSuccess<AggregationSnapshot?>>());
      expect((result as AppSuccess<AggregationSnapshot?>).value, isNull);
      expect(remote.getByIdCalls, 1);
    });

    test('uses fresh cache and skips remote re-fetch within the TTL', () async {
      remote.byId['company-1_company-1_2026-08-15'] = _dto();

      final first = await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'company-1',
        periodKey: '2026-08-15',
      );
      expect(first, isA<AppSuccess<AggregationSnapshot?>>());
      expect(remote.getByIdCalls, 1);

      clock = clock.add(const Duration(minutes: 1));
      final second = await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'company-1',
        periodKey: '2026-08-15',
      );
      expect(second, isA<AppSuccess<AggregationSnapshot?>>());
      expect(remote.getByIdCalls, 1);
    });

    test('refetches once the TTL has expired', () async {
      remote.byId['company-1_company-1_2026-08-15'] = _dto();

      await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'company-1',
        periodKey: '2026-08-15',
      );
      expect(remote.getByIdCalls, 1);

      clock = clock.add(const Duration(minutes: 6));
      await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'company-1',
        periodKey: '2026-08-15',
      );
      expect(remote.getByIdCalls, 2);
    });

    test(
      'listByPeriod maps every returned dto and caches by its own key',
      () async {
        remote.byPeriod['company-1::2026-08'] = <AggregationSnapshotDto>[
          _dto(scopeId: 'customer-1'),
          _dto(scopeId: 'customer-2'),
        ];

        final result = await repository.listByPeriod(
          organizationId: 'org-1',
          dimension: AggregationDimension.customerMonthly,
          companyId: 'company-1',
          periodKey: '2026-08',
        );
        expect(result, isA<AppSuccess<List<AggregationSnapshot>>>());
        final snapshots =
            (result as AppSuccess<List<AggregationSnapshot>>).value;
        expect(snapshots, hasLength(2));
        expect(remote.listByPeriodCalls, 1);

        await repository.listByPeriod(
          organizationId: 'org-1',
          dimension: AggregationDimension.customerMonthly,
          companyId: 'company-1',
          periodKey: '2026-08',
        );
        expect(remote.listByPeriodCalls, 1);
      },
    );

    test(
      'a remote failure is mapped to AppFailure instead of throwing',
      () async {
        remote.throwOnGetById = true;

        final result = await repository.getSnapshot(
          organizationId: 'org-1',
          dimension: AggregationDimension.salesDaily,
          companyId: 'company-1',
          scopeId: 'company-1',
          periodKey: '2026-08-15',
        );
        expect(result, isA<AppFailure<AggregationSnapshot?>>());
      },
    );

    test('recovers the durable last snapshot when a new repository instance '
        'is offline', () async {
      remote.byId['company-1_rep-1_2026-08-15'] = _dto(scopeId: 'rep-1');
      await repository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'rep-1',
        periodKey: '2026-08-15',
      );

      final offlineRemote = _FakeAggregationRemoteDataSource()
        ..throwOnGetById = true;
      final restartedRepository = AggregationRepositoryImpl(
        offlineRemote,
        const AggregationSnapshotMapper(),
        now: () => clock,
      );
      final result = await restartedRepository.getSnapshot(
        organizationId: 'org-1',
        dimension: AggregationDimension.salesDaily,
        companyId: 'company-1',
        scopeId: 'rep-1',
        periodKey: '2026-08-15',
      );

      final snapshot = (result as AppSuccess<AggregationSnapshot?>).value!;
      expect(snapshot.revenueNet, 1400);
      expect(snapshot.isFromLocalCache, isTrue);
    });
  });
}

AggregationSnapshotDto _dto({String scopeId = 'company-1'}) {
  return AggregationSnapshotDto.fromJson(
    <String, dynamic>{
      'organizationId': 'org-1',
      'companyId': 'company-1',
      'scopeId': scopeId,
      'periodKey': '2026-08-15',
      'revenueGross': 1500.0,
      'revenueNet': 1400.0,
      'discountAmount': 100.0,
      'orderCount': 2,
      'itemQuantity': 20,
      'labels': <String, dynamic>{},
      'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 15, 3)),
      'version': 1,
    },
    id: 'company-1_${scopeId}_2026-08-15',
    dimension: AggregationDimension.salesDaily,
  );
}

final class _FakeAggregationRemoteDataSource
    implements AggregationRemoteDataSource {
  final Map<String, AggregationSnapshotDto> byId =
      <String, AggregationSnapshotDto>{};
  final Map<String, List<AggregationSnapshotDto>> byPeriod =
      <String, List<AggregationSnapshotDto>>{};
  final Map<String, List<AggregationSnapshotDto>> byRange =
      <String, List<AggregationSnapshotDto>>{};

  int getByIdCalls = 0;
  int listByPeriodCalls = 0;
  int listByPeriodRangeCalls = 0;
  bool throwOnGetById = false;

  @override
  Future<AggregationSnapshotDto?> getById({
    required String organizationId,
    required AggregationDimension dimension,
    required String docId,
  }) async {
    getByIdCalls += 1;
    if (throwOnGetById) {
      throw Exception('simulated remote failure');
    }
    return byId[docId];
  }

  @override
  Future<List<AggregationSnapshotDto>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    required int limit,
  }) async {
    listByPeriodCalls += 1;
    return byPeriod['$companyId::$periodKey'] ??
        const <AggregationSnapshotDto>[];
  }

  @override
  Future<List<AggregationSnapshotDto>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  }) async {
    listByPeriodRangeCalls += 1;
    return byRange['$companyId::$scopeId::$fromPeriodKey::$toPeriodKey'] ??
        const <AggregationSnapshotDto>[];
  }
}

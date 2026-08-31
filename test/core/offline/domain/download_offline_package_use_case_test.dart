import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DownloadOfflinePackageUseCase', () {
    late _FakeOfflinePackageStatusRepository statusRepository;

    setUp(() {
      statusRepository = _FakeOfflinePackageStatusRepository();
    });

    DownloadOfflinePackageUseCase buildUseCase(
      List<OfflinePackageEntityLoader> loaders,
    ) {
      return DownloadOfflinePackageUseCase(loaders, statusRepository);
    }

    test('rejects an invalid payload before touching any loader', () async {
      final customers = _FakeLoader(OfflinePackageEntityKind.customers);
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[customers]);

      final result = await useCase(
        organizationId: '',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(result, isA<AppFailure<OfflinePackageLoadSummary>>());
      expect(customers.isApplicableCalls, 0);
      expect(customers.loadCalls, 0);
    });

    test('downloads every applicable entity sequentially and marks each '
        'complete', () async {
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        recordCount: 5,
      );
      final priceLists = _FakeLoader(
        OfflinePackageEntityKind.priceLists,
        recordCount: 3,
      );
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[
        customers,
        priceLists,
      ]);
      final progressSnapshots = <OfflinePackageProgress>[];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
        onProgress: progressSnapshots.add,
      );

      expect(result, isA<AppSuccess<OfflinePackageLoadSummary>>());
      final summary = (result as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(summary.cancelled, isFalse);
      expect(summary.entityRecordCounts, <OfflinePackageEntityKind, int>{
        OfflinePackageEntityKind.customers: 5,
        OfflinePackageEntityKind.priceLists: 3,
      });
      expect(summary.totalRecords, 8);
      expect(customers.loadCalls, 1);
      expect(priceLists.loadCalls, 1);
      expect(
        statusRepository.markIncompleteCalls,
        containsAll(<OfflinePackageEntityKind>[
          OfflinePackageEntityKind.customers,
          OfflinePackageEntityKind.priceLists,
        ]),
      );
      expect(
        statusRepository.markCompleteCalls.map((call) => call.kind),
        <OfflinePackageEntityKind>[
          OfflinePackageEntityKind.customers,
          OfflinePackageEntityKind.priceLists,
        ],
      );
      expect(progressSnapshots, isNotEmpty);
    });

    test('excludes loaders that are not applicable to this user', () async {
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        applicable: false,
      );
      final priceLists = _FakeLoader(
        OfflinePackageEntityKind.priceLists,
        recordCount: 1,
      );
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[
        customers,
        priceLists,
      ]);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      final summary = (result as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(
        summary.entityRecordCounts.containsKey(
          OfflinePackageEntityKind.customers,
        ),
        isFalse,
      );
      expect(customers.estimateCalls, 0);
      expect(customers.loadCalls, 0);
      expect(priceLists.loadCalls, 1);
    });

    test('a cancellation observed before an entity starts preserves earlier '
        'committed entities and never starts the remaining ones', () async {
      final token = OfflinePackageCancellationToken();
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        recordCount: 5,
        onLoad: token.cancel,
      );
      final priceLists = _FakeLoader(
        OfflinePackageEntityKind.priceLists,
        recordCount: 3,
      );
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[
        customers,
        priceLists,
      ]);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
        cancellationToken: token,
      );

      final summary = (result as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(summary.cancelled, isTrue);
      expect(summary.entityRecordCounts, <OfflinePackageEntityKind, int>{
        OfflinePackageEntityKind.customers: 5,
      });
      expect(priceLists.loadCalls, 0);
      expect(
        statusRepository.markCompleteCalls.map((call) => call.kind),
        <OfflinePackageEntityKind>[OfflinePackageEntityKind.customers],
      );
    });

    test('a loader that itself returns "cancelled" stops the run without '
        'marking that entity complete', () async {
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        outcome: OfflinePackageEntityLoadOutcome.cancelled,
      );
      final priceLists = _FakeLoader(OfflinePackageEntityKind.priceLists);
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[
        customers,
        priceLists,
      ]);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      final summary = (result as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(summary.cancelled, isTrue);
      expect(summary.entityRecordCounts, isEmpty);
      expect(priceLists.loadCalls, 0);
      expect(statusRepository.markCompleteCalls, isEmpty);
    });

    test('a mid-run failure preserves already-committed entities and stops '
        'the remaining ones', () async {
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        recordCount: 5,
      );
      final priceLists = _FakeLoader(
        OfflinePackageEntityKind.priceLists,
        failure: const ConnectivityFailure('offline'),
      );
      final targets = _FakeLoader(OfflinePackageEntityKind.targets);
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[
        customers,
        priceLists,
        targets,
      ]);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(result, isA<AppFailure<OfflinePackageLoadSummary>>());
      expect(targets.loadCalls, 0);
      expect(
        statusRepository.markCompleteCalls.map((call) => call.kind),
        <OfflinePackageEntityKind>[OfflinePackageEntityKind.customers],
      );
    });

    test('skips an entity already marked complete unless forceFullReload is '
        'set', () async {
      statusRepository.seedComplete(OfflinePackageEntityKind.customers, 5);
      final customers = _FakeLoader(
        OfflinePackageEntityKind.customers,
        recordCount: 5,
      );
      final useCase = buildUseCase(<OfflinePackageEntityLoader>[customers]);

      final resumedResult = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );
      final resumedSummary =
          (resumedResult as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(resumedSummary.entityRecordCounts, isEmpty);
      expect(customers.estimateCalls, 0);
      expect(customers.loadCalls, 0);

      final forcedResult = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
        forceFullReload: true,
      );
      final forcedSummary =
          (forcedResult as AppSuccess<OfflinePackageLoadSummary>).value;
      expect(forcedSummary.entityRecordCounts, <OfflinePackageEntityKind, int>{
        OfflinePackageEntityKind.customers: 5,
      });
      expect(customers.loadCalls, 1);
    });
  });
}

final class _FakeLoader implements OfflinePackageEntityLoader {
  _FakeLoader(
    this.kind, {
    this.applicable = true,
    this.recordCount = 0,
    this.outcome = OfflinePackageEntityLoadOutcome.completed,
    this.failure,
    this.onLoad,
  });

  @override
  final OfflinePackageEntityKind kind;

  final bool applicable;
  final int recordCount;
  final OfflinePackageEntityLoadOutcome outcome;
  final Failure? failure;
  final void Function()? onLoad;

  int isApplicableCalls = 0;
  int estimateCalls = 0;
  int loadCalls = 0;

  @override
  Future<AppResult<bool>> isApplicable({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    isApplicableCalls += 1;
    return AppSuccess<bool>(applicable);
  }

  @override
  Future<AppResult<int>> estimate({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    estimateCalls += 1;
    return AppSuccess<int>(recordCount);
  }

  @override
  Future<AppResult<OfflinePackageEntityLoadResult>> load({
    required String organizationId,
    required String companyId,
    required String userId,
    required OfflinePackageCancellationToken cancellationToken,
    required void Function(int recordsFetchedSoFar) onProgress,
    DateTime? now,
  }) async {
    loadCalls += 1;
    onLoad?.call();
    onProgress(recordCount);
    final currentFailure = failure;
    if (currentFailure != null) {
      return AppFailure<OfflinePackageEntityLoadResult>(currentFailure);
    }
    return AppSuccess<OfflinePackageEntityLoadResult>(
      OfflinePackageEntityLoadResult(
        outcome: outcome,
        recordCount: outcome == OfflinePackageEntityLoadOutcome.completed
            ? recordCount
            : 0,
      ),
    );
  }
}

final class _MarkCompleteCall {
  const _MarkCompleteCall(this.kind, this.recordCount);
  final OfflinePackageEntityKind kind;
  final int recordCount;
}

final class _FakeOfflinePackageStatusRepository
    implements OfflinePackageStatusRepository {
  final List<OfflinePackageEntityKind> markIncompleteCalls =
      <OfflinePackageEntityKind>[];
  final List<_MarkCompleteCall> markCompleteCalls = <_MarkCompleteCall>[];
  final Map<OfflinePackageEntityKind, OfflinePackageEntityStatus> _statuses =
      <OfflinePackageEntityKind, OfflinePackageEntityStatus>{};

  void seedComplete(OfflinePackageEntityKind kind, int recordCount) {
    _statuses[kind] = OfflinePackageEntityStatus(
      kind: kind,
      isComplete: true,
      lastCompletedAt: DateTime.utc(2026),
      recordCount: recordCount,
    );
  }

  @override
  Future<AppResult<void>> markIncomplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required DateTime now,
  }) async {
    markIncompleteCalls.add(kind);
    _statuses[kind] = OfflinePackageEntityStatus(
      kind: kind,
      isComplete: false,
      lastCompletedAt: _statuses[kind]?.lastCompletedAt,
      recordCount: _statuses[kind]?.recordCount ?? 0,
    );
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> markComplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required int recordCount,
    required DateTime now,
  }) async {
    markCompleteCalls.add(_MarkCompleteCall(kind, recordCount));
    _statuses[kind] = OfflinePackageEntityStatus(
      kind: kind,
      isComplete: true,
      lastCompletedAt: now,
      recordCount: recordCount,
    );
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<OfflinePackageEntityStatus>>> getAll({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<OfflinePackageEntityStatus>>(
      _statuses.values.toList(growable: false),
    );
  }
}

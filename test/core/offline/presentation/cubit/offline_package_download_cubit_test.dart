import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('OfflinePackageDownloadCubit', () {
    late _FakeOfflinePackageStatusRepository statusRepository;

    setUp(() {
      statusRepository = _FakeOfflinePackageStatusRepository();
    });

    OfflinePackageDownloadCubit buildCubit(
      List<OfflinePackageEntityLoader> loaders,
    ) {
      return OfflinePackageDownloadCubit(
        DownloadOfflinePackageUseCase(loaders, statusRepository),
      );
    }

    test('goes idle -> estimating -> downloading -> completed', () async {
      final cubit = buildCubit(<OfflinePackageEntityLoader>[
        _FakeLoader(OfflinePackageEntityKind.customers, recordCount: 4),
      ]);
      addTearDown(cubit.close);

      expect(cubit.state.status, OfflinePackageDownloadStatus.idle);

      await cubit.download(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(cubit.state.status, OfflinePackageDownloadStatus.completed);
      expect(
        cubit.state.summary?.entityRecordCounts[OfflinePackageEntityKind
            .customers],
        4,
      );
    });

    test('reaches failed with the failure message on error', () async {
      final cubit = buildCubit(<OfflinePackageEntityLoader>[
        _FakeLoader(
          OfflinePackageEntityKind.customers,
          failure: const ConnectivityFailure('offline'),
        ),
      ]);
      addTearDown(cubit.close);

      await cubit.download(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(cubit.state.status, OfflinePackageDownloadStatus.failed);
      expect(cubit.state.failureMessage, 'offline');
    });

    test('cancel() called before the entity load starts reaches cancelled '
        'without marking anything complete', () async {
      late OfflinePackageDownloadCubit cubit;
      final loader = _FakeLoader(
        OfflinePackageEntityKind.customers,
        recordCount: 4,
        // Deterministic cancellation point: `estimate()` always runs before
        // `load()`, so cancelling here guarantees `load()` observes it.
        onEstimate: () => cubit.cancel(),
      );
      cubit = buildCubit(<OfflinePackageEntityLoader>[loader]);
      addTearDown(cubit.close);

      cubit.cancel(); // no-op: nothing in flight yet.
      await cubit.download(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(cubit.state.status, OfflinePackageDownloadStatus.cancelled);
      expect(cubit.state.summary?.entityRecordCounts, isEmpty);
    });
  });
}

final class _FakeLoader implements OfflinePackageEntityLoader {
  _FakeLoader(this.kind, {this.recordCount = 0, this.failure, this.onEstimate});

  @override
  final OfflinePackageEntityKind kind;
  final int recordCount;
  final Failure? failure;
  final void Function()? onEstimate;

  @override
  Future<AppResult<bool>> isApplicable({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async => const AppSuccess<bool>(true);

  @override
  Future<AppResult<int>> estimate({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    onEstimate?.call();
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
    onProgress(recordCount);
    if (cancellationToken.isCancelled) {
      return const AppSuccess<OfflinePackageEntityLoadResult>(
        OfflinePackageEntityLoadResult(
          outcome: OfflinePackageEntityLoadOutcome.cancelled,
          recordCount: 0,
        ),
      );
    }
    final currentFailure = failure;
    if (currentFailure != null) {
      return AppFailure<OfflinePackageEntityLoadResult>(currentFailure);
    }
    return AppSuccess<OfflinePackageEntityLoadResult>(
      OfflinePackageEntityLoadResult(
        outcome: OfflinePackageEntityLoadOutcome.completed,
        recordCount: recordCount,
      ),
    );
  }
}

final class _FakeOfflinePackageStatusRepository
    implements OfflinePackageStatusRepository {
  @override
  Future<AppResult<void>> markIncomplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required DateTime now,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> markComplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required int recordCount,
    required DateTime now,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<List<OfflinePackageEntityStatus>>> getAll({
    required String organizationId,
    required String companyId,
  }) async => const AppSuccess<List<OfflinePackageEntityStatus>>(
    <OfflinePackageEntityStatus>[],
  );
}

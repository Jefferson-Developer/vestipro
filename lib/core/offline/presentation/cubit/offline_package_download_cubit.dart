import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../../domain/download_offline_package_use_case.dart';
import '../../domain/entities/offline_package_load_summary.dart';
import '../../domain/offline_package_cancellation_token.dart';
import 'offline_package_download_state.dart';

/// Presentation state holder for the offline package download screen
/// (TASK-107). One [OfflinePackageDownloadCubit] instance owns exactly one
/// in-flight download at a time — [download] replaces any previous
/// [OfflinePackageCancellationToken] it was holding, so a stale [cancel]
/// call from a disposed widget can never affect a newer download.
@injectable
final class OfflinePackageDownloadCubit
    extends Cubit<OfflinePackageDownloadState> {
  OfflinePackageDownloadCubit(this._downloadOfflinePackage)
    : super(const OfflinePackageDownloadState());

  final DownloadOfflinePackageUseCase _downloadOfflinePackage;

  OfflinePackageCancellationToken? _activeToken;

  Future<void> download({
    required String organizationId,
    required String companyId,
    required String userId,
    bool forceFullReload = false,
  }) async {
    if (state.isBusy) {
      return;
    }

    final token = OfflinePackageCancellationToken();
    _activeToken = token;

    emit(
      const OfflinePackageDownloadState(
        status: OfflinePackageDownloadStatus.estimating,
      ),
    );

    final result = await _downloadOfflinePackage(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      cancellationToken: token,
      forceFullReload: forceFullReload,
      onProgress: (progress) {
        if (isClosed || !identical(_activeToken, token)) {
          return;
        }
        emit(
          state.copyWith(
            status: OfflinePackageDownloadStatus.downloading,
            progress: progress,
          ),
        );
      },
    );

    if (isClosed || !identical(_activeToken, token)) {
      return;
    }

    switch (result) {
      case AppSuccess<OfflinePackageLoadSummary>(value: final summary):
        emit(
          state.copyWith(
            status: summary.cancelled
                ? OfflinePackageDownloadStatus.cancelled
                : OfflinePackageDownloadStatus.completed,
            summary: summary,
            clearFailureMessage: true,
          ),
        );
      case AppFailure<OfflinePackageLoadSummary>(failure: final failure):
        emit(
          state.copyWith(
            status: OfflinePackageDownloadStatus.failed,
            failureMessage: failure.message,
            clearSummary: true,
          ),
        );
    }
  }

  /// Requests cancellation of the in-flight download, if any. Safe to call
  /// when idle/already finished — it is simply a no-op then.
  void cancel() {
    _activeToken?.cancel();
  }
}

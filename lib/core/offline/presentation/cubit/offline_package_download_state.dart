import '../../domain/entities/offline_package_load_summary.dart';
import '../../domain/entities/offline_package_progress.dart';

enum OfflinePackageDownloadStatus {
  idle,
  estimating,
  downloading,
  cancelled,
  completed,
  failed,
}

final class OfflinePackageDownloadState {
  const OfflinePackageDownloadState({
    this.status = OfflinePackageDownloadStatus.idle,
    this.progress,
    this.summary,
    this.failureMessage,
  });

  final OfflinePackageDownloadStatus status;
  final OfflinePackageProgress? progress;
  final OfflinePackageLoadSummary? summary;
  final String? failureMessage;

  bool get isBusy =>
      status == OfflinePackageDownloadStatus.estimating ||
      status == OfflinePackageDownloadStatus.downloading;

  OfflinePackageDownloadState copyWith({
    OfflinePackageDownloadStatus? status,
    OfflinePackageProgress? progress,
    bool clearProgress = false,
    OfflinePackageLoadSummary? summary,
    bool clearSummary = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return OfflinePackageDownloadState(
      status: status ?? this.status,
      progress: clearProgress ? null : (progress ?? this.progress),
      summary: clearSummary ? null : (summary ?? this.summary),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}

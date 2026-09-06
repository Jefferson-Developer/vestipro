/// Lifecycle of a `ProductImportJob` (TASK-168), mirrored exactly by the
/// `status` field `processProductImportJob` (Cloud Function, Firestore
/// trigger) writes to `organizations/{organizationId}/productImportJobs/{jobId}`.
/// The client only ever reads this — no Dart code advances a job's status
/// itself, same rationale as `CustomerImportJobStatus` (TASK-167).
enum ProductImportJobStatus { queued, processing, completed, failed }

extension ProductImportJobStatusCode on ProductImportJobStatus {
  String get code {
    return switch (this) {
      ProductImportJobStatus.queued => 'queued',
      ProductImportJobStatus.processing => 'processing',
      ProductImportJobStatus.completed => 'completed',
      ProductImportJobStatus.failed => 'failed',
    };
  }

  static ProductImportJobStatus fromCode(String code) {
    return switch (code) {
      'processing' => ProductImportJobStatus.processing,
      'completed' => ProductImportJobStatus.completed,
      'failed' => ProductImportJobStatus.failed,
      _ => ProductImportJobStatus.queued,
    };
  }

  bool get isFinished =>
      this == ProductImportJobStatus.completed ||
      this == ProductImportJobStatus.failed;
}

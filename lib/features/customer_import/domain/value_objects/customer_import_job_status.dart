/// Lifecycle of a `CustomerImportJob` (TASK-167), mirrored exactly by the
/// `status` field `processCustomerImportJob` (Cloud Function, Firestore
/// trigger) writes to `organizations/{organizationId}/customerImportJobs/{jobId}`.
/// The client only ever reads this — no Dart code advances a job's status
/// itself, since the whole point of the async job is that heavy parsing
/// never blocks the UI thread nor risks a callable timeout.
enum CustomerImportJobStatus { queued, processing, completed, failed }

extension CustomerImportJobStatusCode on CustomerImportJobStatus {
  String get code {
    return switch (this) {
      CustomerImportJobStatus.queued => 'queued',
      CustomerImportJobStatus.processing => 'processing',
      CustomerImportJobStatus.completed => 'completed',
      CustomerImportJobStatus.failed => 'failed',
    };
  }

  static CustomerImportJobStatus fromCode(String code) {
    return switch (code) {
      'processing' => CustomerImportJobStatus.processing,
      'completed' => CustomerImportJobStatus.completed,
      'failed' => CustomerImportJobStatus.failed,
      _ => CustomerImportJobStatus.queued,
    };
  }

  bool get isFinished =>
      this == CustomerImportJobStatus.completed ||
      this == CustomerImportJobStatus.failed;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/customer_import_job_status.dart';
import 'customer_import_mapping.dart';

part 'customer_import_job.freezed.dart';

/// One asynchronous customer-import execution (TASK-167), mirroring
/// `organizations/{organizationId}/customerImportJobs/{jobId}` — created by
/// the `startCustomerImportJob` Cloud Function and advanced only by
/// `processCustomerImportJob` (Firestore trigger). The Flutter client only
/// ever reads this document (`WatchCustomerImportJobUseCase`); it never
/// writes to it directly, since the whole point of the job is that parsing
/// a possibly large spreadsheet never runs on/blocks the client.
@freezed
abstract class CustomerImportJob with _$CustomerImportJob {
  const CustomerImportJob._();

  const factory CustomerImportJob({
    required String id,
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,
    String? reportStoragePath,
    String? templateId,
    required CustomerImportMapping mapping,
    required CustomerImportJobStatus status,
    int? totalRows,
    @Default(0) int processedRows,
    @Default(0) int importedCount,
    @Default(0) int rejectedCount,
    @Default(0) int duplicateCount,
    String? errorMessage,
    required DateTime createdAt,
    required String createdBy,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _CustomerImportJob;

  /// `0.0`–`1.0` progress ratio for a progress bar — `null` while
  /// [totalRows] is still unknown (the Function has not finished the first
  /// parsing pass yet), never a divide-by-zero.
  double? get progressRatio {
    final total = totalRows;
    if (total == null || total == 0) return null;
    return (processedRows / total).clamp(0.0, 1.0);
  }
}

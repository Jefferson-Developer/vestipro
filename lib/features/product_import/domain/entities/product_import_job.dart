import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/product_import_job_status.dart';

part 'product_import_job.freezed.dart';

/// One asynchronous product-import execution (TASK-168), mirroring
/// `organizations/{organizationId}/productImportJobs/{jobId}` — created by
/// the `startProductImportJob` Cloud Function and advanced only by
/// `processProductImportJob` (Firestore trigger). The Flutter client only
/// ever reads this document; it never writes to it directly.
@freezed
abstract class ProductImportJob with _$ProductImportJob {
  const ProductImportJob._();

  const factory ProductImportJob({
    required String id,
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,

    /// Storage path prefix under which optional product images were
    /// uploaded before the job started (`organizations/{organizationId}/
    /// productImports/{batchId}/images/`) — `null` when the gestor imported
    /// products without an image package.
    String? imagesFolderPath,
    String? reportStoragePath,
    String? templateId,
    required ProductImportJobStatus status,
    int? totalRows,
    @Default(0) int processedRows,
    @Default(0) int createdProductsCount,
    @Default(0) int createdVariantsCount,
    @Default(0) int imagesAssociatedCount,
    @Default(0) int imagesOrphanCount,
    @Default(0) int rejectedCount,
    String? errorMessage,
    required DateTime createdAt,
    required String createdBy,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _ProductImportJob;

  /// `0.0`–`1.0` progress ratio for a progress bar — `null` while
  /// [totalRows] is still unknown, never a divide-by-zero.
  double? get progressRatio {
    final total = totalRows;
    if (total == null || total == 0) return null;
    return (processedRows / total).clamp(0.0, 1.0);
  }
}

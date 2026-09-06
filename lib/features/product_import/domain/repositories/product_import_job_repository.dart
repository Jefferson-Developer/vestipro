import 'dart:typed_data';

import '../../../../core/utils/utils.dart';
import '../entities/product_import_job.dart';
import '../entities/product_import_lookup.dart';
import '../entities/product_import_mapping.dart';
import '../entities/product_import_report.dart';

/// Contract for the async product-import job lifecycle (TASK-168), mirroring
/// `CustomerImportJobRepository` (TASK-167). Every state-changing action goes
/// through the `startProductImportJob` Cloud Function, never a direct
/// Firestore write.
abstract interface class ProductImportJobRepository {
  /// Uploads [fileBytes] (and, when provided, every entry of [imageBytesByFileName])
  /// to Cloud Storage, then calls `startProductImportJob` with [mapping] and
  /// the already-resolved [lookup] (TASK-168: category/collection/color
  /// names are resolved to ids client-side, never by the Cloud Function
  /// itself — see `ProductImportLookup`'s docs).
  Future<AppResult<ProductImportJob>> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required ProductImportMapping mapping,
    required ProductImportLookup lookup,
    required bool createMissingCategories,
    required bool createMissingCollections,
    Map<String, Uint8List>? imageBytesByFileName,
    String? templateId,
    required String createdBy,
  });

  Stream<AppResult<ProductImportJob>> watchJob({
    required String organizationId,
    required String jobId,
  });

  Future<AppResult<List<ProductImportJob>>> listByOrganization({
    required String organizationId,
    int limit = 20,
  });

  Future<AppResult<ProductImportReport>> getReport({
    required String organizationId,
    required String jobId,
    required String reportStoragePath,
  });
}

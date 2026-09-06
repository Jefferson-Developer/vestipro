import '../dtos/product_import_job_dto.dart';

/// Read-only Firestore access to `productImportJobs` (TASK-168) — every
/// write instead goes through [ProductImportFunctionsDataSource]/Cloud
/// Functions, see `ProductImportJobRepository`'s docs.
abstract interface class ProductImportJobDataSource {
  Stream<ProductImportJobDto?> watchJob({
    required String organizationId,
    required String jobId,
  });

  Future<List<ProductImportJobDto>> listByOrganization({
    required String organizationId,
    required int limit,
  });
}

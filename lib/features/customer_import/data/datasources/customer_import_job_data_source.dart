import '../dtos/customer_import_job_dto.dart';

/// Read-only Firestore access to `customerImportJobs` (TASK-167) — every
/// write instead goes through
/// [CustomerImportFunctionsDataSource]/Cloud Functions, see
/// `CustomerImportJobRepository`'s docs.
abstract interface class CustomerImportJobDataSource {
  Stream<CustomerImportJobDto?> watchJob({
    required String organizationId,
    required String jobId,
  });

  Future<List<CustomerImportJobDto>> listByOrganization({
    required String organizationId,
    required int limit,
  });
}

/// Callable Cloud Functions for the customer import job lifecycle
/// (TASK-167) — every state-changing action on a `CustomerImportJob` goes
/// through here, never a direct Firestore write (see
/// `CustomerImportJobRepository`'s docs).
abstract interface class CustomerImportFunctionsDataSource {
  /// Calls `startCustomerImportJob`; returns the created job's id.
  Future<String> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
    String? templateId,
  });

  /// Calls `resolveCustomerImportDuplicateRow`.
  Future<void> resolveDuplicateRow({
    required String organizationId,
    required String jobId,
    required int rowNumber,
    required String resolution,
  });
}

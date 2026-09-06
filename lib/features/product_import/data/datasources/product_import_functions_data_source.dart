/// Callable Cloud Functions for the product import job lifecycle (TASK-168)
/// — every state-changing action on a `ProductImportJob` goes through here,
/// never a direct Firestore write, mirroring
/// `CustomerImportFunctionsDataSource` (TASK-167).
abstract interface class ProductImportFunctionsDataSource {
  /// Calls `startProductImportJob`; returns the created job's id.
  Future<String> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,
    String? imagesFolderPath,
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
    required String sizeGridTemplateId,
    required Map<String, String> categoryIdByName,
    required Map<String, String> collectionIdByName,
    required Map<String, String> colorIdByName,
    required Map<String, String> sizeIdByLabel,
    required bool createMissingCategories,
    required bool createMissingCollections,
    String? templateId,
  });
}

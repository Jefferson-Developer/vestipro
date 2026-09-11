abstract interface class FulfillmentWriteDataSource {
  Future<void> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required String type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  });

  Future<void> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required String status,
    String? resolutionNote,
  });
}

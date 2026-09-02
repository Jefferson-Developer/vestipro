import '../dtos/insight_dto.dart';

abstract interface class InsightDataSource {
  Future<void> saveAll({
    required String organizationId,
    required List<InsightDto> insights,
  });

  Future<List<InsightDto>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    String? type,
    String? status,
  });

  /// Same contract as [listPageByRecipient], but scoped to
  /// [recipientUserIds] instead of a single recipient — `null` means "every
  /// recipient in the organization" (OWNER/ADMIN), an empty set means "no
  /// recipient is visible" (never queries).
  Future<List<InsightDto>> listPageByVisibility({
    required String organizationId,
    required Set<String>? recipientUserIds,
    int limit = 25,
    DateTime? before,
    String? type,
  });

  Future<void> updateStatus({
    required String organizationId,
    required String insightId,
    required String status,
  });
}

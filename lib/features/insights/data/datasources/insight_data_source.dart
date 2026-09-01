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
}

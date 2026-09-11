import '../dtos/buyer_collaboration_conversion_result_dto.dart';
import '../dtos/buyer_collaboration_session_dto.dart';

abstract interface class BuyerCollaborationWriteDataSource {
  Future<String> create({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required String sourceType,
    required String sourceId,
    required List<BuyerCollaborationItemDto> items,
    required bool showPrices,
  });

  Future<void> share({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItemDto>? items,
    String? note,
  });

  Future<void> addComment({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    required String visibility,
    required List<Map<String, dynamic>> attachments,
    required List<String> mentionedMemberIds,
  });

  Future<void> requestChanges({
    required String organizationId,
    required String sessionId,
    required String comment,
    required List<Map<String, dynamic>> proposedChanges,
  });

  Future<void> approve({
    required String organizationId,
    required String sessionId,
    String? comment,
  });

  Future<BuyerCollaborationConversionResultDto> convert({
    required String organizationId,
    required String sessionId,
    required String orderId,
    required bool acceptPriceDrift,
  });

  Future<void> reopen({
    required String organizationId,
    required String sessionId,
  });
}

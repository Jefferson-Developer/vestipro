import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/buyer_collaboration_conversion_result_dto.dart';
import '../dtos/buyer_collaboration_session_dto.dart';
import 'buyer_collaboration_write_data_source.dart';

/// [BuyerCollaborationWriteDataSource] backed by [CloudFunctionsService]
/// (TASK-211) — every mutation goes through the `buyer_collaboration`
/// callables, never a direct Firestore write, same "escrita só via Cloud
/// Function" contract `CloudFunctionsCartShareRepository` (TASK-181) and
/// `CloudFunctionsExchangeRequestDataSource` (TASK-200) already follow.
@LazySingleton(as: BuyerCollaborationWriteDataSource)
final class CloudFunctionsBuyerCollaborationWriteDataSource
    implements BuyerCollaborationWriteDataSource {
  const CloudFunctionsBuyerCollaborationWriteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<String> create({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required String sourceType,
    required String sourceId,
    required List<BuyerCollaborationItemDto> items,
    required bool showPrices,
  }) async {
    final json = await _functions.call<Map<String, dynamic>>(
      'createBuyerCollaborationSession',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
        'priceListId': priceListId,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'showPrices': showPrices,
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return json['sessionId'] as String;
  }

  @override
  Future<void> share({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItemDto>? items,
    String? note,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'shareBuyerCollaborationSession',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
        if (items != null)
          'items': items.map((item) => item.toJson()).toList(growable: false),
        'note': note,
      },
    );
  }

  @override
  Future<void> addComment({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    required String visibility,
    required List<Map<String, dynamic>> attachments,
    required List<String> mentionedMemberIds,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'addBuyerCollaborationComment',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
        'body': body,
        'itemId': itemId,
        'visibility': visibility,
        'attachments': attachments,
        'mentionedMemberIds': mentionedMemberIds,
      },
    );
  }

  @override
  Future<void> requestChanges({
    required String organizationId,
    required String sessionId,
    required String comment,
    required List<Map<String, dynamic>> proposedChanges,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'requestBuyerCollaborationChanges',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
        'comment': comment,
        'proposedChanges': proposedChanges,
      },
    );
  }

  @override
  Future<void> approve({
    required String organizationId,
    required String sessionId,
    String? comment,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'approveBuyerCollaborationSession',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
        'comment': comment,
      },
    );
  }

  @override
  Future<BuyerCollaborationConversionResultDto> convert({
    required String organizationId,
    required String sessionId,
    required String orderId,
    required bool acceptPriceDrift,
  }) async {
    final json = await _functions.call<Map<String, dynamic>>(
      'convertBuyerCollaborationSession',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
        'orderId': orderId,
        'acceptPriceDrift': acceptPriceDrift,
      },
    );
    return BuyerCollaborationConversionResultDto.fromJson(json);
  }

  @override
  Future<void> reopen({
    required String organizationId,
    required String sessionId,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'reopenBuyerCollaborationSession',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sessionId': sessionId,
      },
    );
  }
}

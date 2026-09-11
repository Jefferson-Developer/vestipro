import '../../../../core/utils/utils.dart';
import '../entities/buyer_collaboration_attachment.dart';
import '../entities/buyer_collaboration_comment.dart';
import '../entities/buyer_collaboration_conversion_result.dart';
import '../entities/buyer_collaboration_item.dart';
import '../entities/buyer_collaboration_proposed_change.dart';
import '../entities/buyer_collaboration_session.dart';
import '../value_objects/buyer_collaboration_comment_kind.dart';
import '../value_objects/buyer_collaboration_source_type.dart';

abstract interface class BuyerCollaborationRepository {
  Future<AppResult<String>> createSession({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required BuyerCollaborationSourceType sourceType,
    required String sourceId,
    required List<BuyerCollaborationItem> items,
    required bool showPrices,
  });

  Future<AppResult<void>> shareSession({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItem>? items,
    String? note,
  });

  Future<AppResult<void>> addComment({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    BuyerCollaborationCommentVisibility visibility =
        BuyerCollaborationCommentVisibility.shared,
    List<BuyerCollaborationAttachment> attachments =
        const <BuyerCollaborationAttachment>[],
    List<String> mentionedMemberIds = const <String>[],
  });

  Future<AppResult<void>> requestChanges({
    required String organizationId,
    required String sessionId,
    required String comment,
    List<BuyerCollaborationProposedChange> proposedChanges =
        const <BuyerCollaborationProposedChange>[],
  });

  Future<AppResult<void>> approve({
    required String organizationId,
    required String sessionId,
    String? comment,
  });

  Future<AppResult<BuyerCollaborationConversionResult>> convert({
    required String organizationId,
    required String sessionId,
    required String orderId,
    bool acceptPriceDrift = false,
  });

  Future<AppResult<void>> reopen({
    required String organizationId,
    required String sessionId,
  });

  Stream<AppResult<BuyerCollaborationSession?>> watchSession({
    required String organizationId,
    required String sessionId,
  });

  Stream<AppResult<List<BuyerCollaborationComment>>> watchComments({
    required String organizationId,
    required String sessionId,
  });
}

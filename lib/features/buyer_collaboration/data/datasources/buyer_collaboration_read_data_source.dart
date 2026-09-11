import '../dtos/buyer_collaboration_comment_dto.dart';
import '../dtos/buyer_collaboration_session_dto.dart';

abstract interface class BuyerCollaborationReadDataSource {
  Stream<BuyerCollaborationSessionDto?> watchSession({
    required String organizationId,
    required String sessionId,
  });

  Stream<List<BuyerCollaborationCommentDto>> watchComments({
    required String organizationId,
    required String sessionId,
  });
}

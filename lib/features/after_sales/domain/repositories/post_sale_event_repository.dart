import '../../../../core/utils/utils.dart';
import '../entities/post_sale_event.dart';
import '../entities/post_sale_event_submission_result.dart';
import '../value_objects/post_sale_event_type.dart';

abstract interface class PostSaleEventRepository {
  /// Calls `registerPostSaleEvent` (Cloud Function) — never a direct
  /// Firestore write (`AGENTS.md`: regras de negócio críticas ficam no
  /// backend). [eventId] is the client-generated idempotency key/document
  /// id: a retried call with the same id always replays the same result
  /// instead of registering a second event.
  Future<AppResult<PostSaleEventSubmissionResult>> registerPostSaleEvent({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  });

  /// Every `PostSaleEvent` linked to [orderId] — feeds the pedido's own
  /// pós-venda timeline (TASK-102/TASK-201), including the devolução/troca
  /// events auto-appended by TASK-199/TASK-200's own Cloud Functions.
  Stream<AppResult<List<PostSaleEvent>>> watchByOrder({
    required String organizationId,
    required String orderId,
  });
}

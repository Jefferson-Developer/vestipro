import '../value_objects/post_sale_event_type.dart';

/// The immediate outcome of [RegisterPostSaleEventUseCase] — deliberately
/// lighter than the full [PostSaleEvent] entity (mirrors
/// `ReturnRequestSubmissionResult` vs. `ReturnRequest`, TASK-199): the UI's
/// own `PostSaleTimelineCubit` (already watching
/// `organizations/{organizationId}/postSaleEvents`) picks up the newly
/// created document through that stream, so this result only needs to carry
/// enough to drive an immediate "evento registrado" confirmation.
final class PostSaleEventSubmissionResult {
  const PostSaleEventSubmissionResult({
    required this.eventId,
    required this.orderId,
    required this.type,
    this.description,
    required this.createdAt,
  });

  final String eventId;
  final String orderId;
  final PostSaleEventType type;
  final String? description;
  final DateTime createdAt;
}

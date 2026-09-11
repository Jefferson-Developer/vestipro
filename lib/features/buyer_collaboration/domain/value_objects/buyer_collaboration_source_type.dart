import '../../../../core/errors/errors.dart';

/// Which draft a `BuyerCollaborationSession` wraps a snapshot of items from
/// (TASK-211's `sourceType`/`sourceId`) — a cart draft (TASK-181's own
/// `cartShares`), a `Quote` (TASK-197), a pre-book draft (TASK-210) or a
/// plain order draft (TASK-096).
enum BuyerCollaborationSourceType {
  cart,
  quote,
  preBook,
  orderDraft;

  static BuyerCollaborationSourceType fromCode(String code) => switch (code) {
    'cart' => cart,
    'quote' => quote,
    'preBook' => preBook,
    'orderDraft' => orderDraft,
    _ => throw ValidationException(
      'Invalid buyer collaboration source type: $code',
      code: 'invalid_buyer_collaboration_source_type',
    ),
  };

  String get code => switch (this) {
    BuyerCollaborationSourceType.cart => 'cart',
    BuyerCollaborationSourceType.quote => 'quote',
    BuyerCollaborationSourceType.preBook => 'preBook',
    BuyerCollaborationSourceType.orderDraft => 'orderDraft',
  };
}

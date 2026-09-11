import '../../../../core/errors/errors.dart';

/// Mirrors the status machine `functions/src/buyer_collaboration` enforces
/// server-side (TASK-211): `sellerDraft` → `buyerReview` → (`buyerApproved`
/// | `changesRequested` → back to `buyerReview`) → `convertedToOrder`, with
/// `expired` reachable lazily from any non-terminal status once the session's
/// `expiresAt` passes (and reversible only via an explicit `reopen`).
enum BuyerCollaborationStatus {
  sellerDraft,
  buyerReview,
  changesRequested,
  buyerApproved,
  convertedToOrder,
  expired;

  static BuyerCollaborationStatus fromCode(String code) => switch (code) {
    'seller_draft' => sellerDraft,
    'buyer_review' => buyerReview,
    'changes_requested' => changesRequested,
    'buyer_approved' => buyerApproved,
    'converted_to_order' => convertedToOrder,
    'expired' => expired,
    _ => throw ValidationException(
      'Invalid buyer collaboration status: $code',
      code: 'invalid_buyer_collaboration_status',
    ),
  };

  String get code => switch (this) {
    BuyerCollaborationStatus.sellerDraft => 'seller_draft',
    BuyerCollaborationStatus.buyerReview => 'buyer_review',
    BuyerCollaborationStatus.changesRequested => 'changes_requested',
    BuyerCollaborationStatus.buyerApproved => 'buyer_approved',
    BuyerCollaborationStatus.convertedToOrder => 'converted_to_order',
    BuyerCollaborationStatus.expired => 'expired',
  };

  bool get isTerminal =>
      this == BuyerCollaborationStatus.convertedToOrder ||
      this == BuyerCollaborationStatus.expired;
}

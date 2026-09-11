import '../../../../core/errors/errors.dart';

/// A plain remark, a buyer's structured `changesRequested` (may carry
/// [BuyerCollaborationProposedChange]s) or a system-authored entry (share,
/// revision, approval, reopen, conversion) recorded automatically alongside
/// the free-text ones — all three share one ordered, append-only history per
/// `BuyerCollaborationSession` (`tasks.md`: "histórico de negociação em um
/// só lugar").
enum BuyerCollaborationCommentKind {
  comment,
  changeRequest,
  system;

  static BuyerCollaborationCommentKind fromCode(String code) => switch (code) {
    'comment' => comment,
    'change_request' => changeRequest,
    'system' => system,
    _ => throw ValidationException(
      'Invalid buyer collaboration comment kind: $code',
      code: 'invalid_buyer_collaboration_comment_kind',
    ),
  };

  String get code => switch (this) {
    BuyerCollaborationCommentKind.comment => 'comment',
    BuyerCollaborationCommentKind.changeRequest => 'change_request',
    BuyerCollaborationCommentKind.system => 'system',
  };
}

enum BuyerCollaborationAuthorType {
  seller,
  buyer;

  static BuyerCollaborationAuthorType fromCode(String code) => switch (code) {
    'seller' => seller,
    'buyer' => buyer,
    _ => throw ValidationException(
      'Invalid buyer collaboration author type: $code',
      code: 'invalid_buyer_collaboration_author_type',
    ),
  };

  String get code => switch (this) {
    BuyerCollaborationAuthorType.seller => 'seller',
    BuyerCollaborationAuthorType.buyer => 'buyer',
  };
}

enum BuyerCollaborationCommentVisibility {
  shared,
  internal;

  static BuyerCollaborationCommentVisibility fromCode(String code) =>
      switch (code) {
        'shared' => shared,
        'internal' => internal,
        _ => throw ValidationException(
          'Invalid buyer collaboration comment visibility: $code',
          code: 'invalid_buyer_collaboration_comment_visibility',
        ),
      };

  String get code => switch (this) {
    BuyerCollaborationCommentVisibility.shared => 'shared',
    BuyerCollaborationCommentVisibility.internal => 'internal',
  };
}

enum BuyerCollaborationProposedChangeAction {
  update,
  remove,
  add;

  static BuyerCollaborationProposedChangeAction fromCode(String code) =>
      switch (code) {
        'update' => update,
        'remove' => remove,
        'add' => add,
        _ => throw ValidationException(
          'Invalid buyer collaboration proposed change action: $code',
          code: 'invalid_buyer_collaboration_proposed_change_action',
        ),
      };

  String get code => switch (this) {
    BuyerCollaborationProposedChangeAction.update => 'update',
    BuyerCollaborationProposedChangeAction.remove => 'remove',
    BuyerCollaborationProposedChangeAction.add => 'add',
  };
}

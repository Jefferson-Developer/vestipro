import '../value_objects/buyer_collaboration_comment_kind.dart';
import 'buyer_collaboration_attachment.dart';
import 'buyer_collaboration_proposed_change.dart';

/// One entry in a `BuyerCollaborationSession`'s ordered, append-only
/// history — a free-text comment (general or scoped to [itemId]), a buyer's
/// structured change request, or a system-authored milestone. Always carries
/// authorship, a timestamp and its own [visibility] (`tasks.md`: "sempre com
/// trilha de autoria, timestamp e visibilidade").
final class BuyerCollaborationComment {
  const BuyerCollaborationComment({
    required this.id,
    required this.authorId,
    required this.authorType,
    this.authorName,
    required this.visibility,
    this.itemId,
    required this.kind,
    required this.body,
    this.attachments = const <BuyerCollaborationAttachment>[],
    this.mentionedMemberIds = const <String>[],
    this.proposedChanges,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final BuyerCollaborationAuthorType authorType;
  final String? authorName;
  final BuyerCollaborationCommentVisibility visibility;
  final String? itemId;
  final BuyerCollaborationCommentKind kind;
  final String body;
  final List<BuyerCollaborationAttachment> attachments;
  final List<String> mentionedMemberIds;
  final List<BuyerCollaborationProposedChange>? proposedChanges;
  final DateTime createdAt;
}

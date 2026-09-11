import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class BuyerCollaborationAttachmentDto {
  const BuyerCollaborationAttachmentDto({
    required this.name,
    required this.url,
    required this.contentType,
  });

  factory BuyerCollaborationAttachmentDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];
    final contentType = json['contentType'];
    if (name is! String || url is! String || contentType is! String) {
      throw const ValidationException(
        'Invalid buyer collaboration attachment payload.',
        code: 'invalid_buyer_collaboration_attachment_payload',
      );
    }
    return BuyerCollaborationAttachmentDto(
      name: name,
      url: url,
      contentType: contentType,
    );
  }

  final String name;
  final String url;
  final String contentType;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'url': url,
    'contentType': contentType,
  };
}

final class BuyerCollaborationProposedChangeDto {
  const BuyerCollaborationProposedChangeDto({
    required this.itemId,
    required this.action,
    this.requestedQuantity,
    this.productId,
    this.variantId,
    this.productName,
  });

  factory BuyerCollaborationProposedChangeDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final itemId = json['itemId'];
    final action = json['action'];
    final requestedQuantity = json['requestedQuantity'];
    final productId = json['productId'];
    final variantId = json['variantId'];
    final productName = json['productName'];
    if (itemId is! String ||
        action is! String ||
        (requestedQuantity != null && requestedQuantity is! num) ||
        (productId != null && productId is! String) ||
        (variantId != null && variantId is! String) ||
        (productName != null && productName is! String)) {
      throw const ValidationException(
        'Invalid buyer collaboration proposed change payload.',
        code: 'invalid_buyer_collaboration_proposed_change_payload',
      );
    }
    return BuyerCollaborationProposedChangeDto(
      itemId: itemId,
      action: action,
      requestedQuantity: (requestedQuantity as num?)?.toInt(),
      productId: productId as String?,
      variantId: variantId as String?,
      productName: productName as String?,
    );
  }

  final String itemId;
  final String action;
  final int? requestedQuantity;
  final String? productId;
  final String? variantId;
  final String? productName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'itemId': itemId,
    'action': action,
    'requestedQuantity': requestedQuantity,
    'productId': productId,
    'variantId': variantId,
    'productName': productName,
  };
}

final class BuyerCollaborationCommentDto {
  const BuyerCollaborationCommentDto({
    required this.id,
    required this.authorId,
    required this.authorType,
    this.authorName,
    required this.visibility,
    this.itemId,
    required this.kind,
    required this.body,
    this.attachments = const <BuyerCollaborationAttachmentDto>[],
    this.mentionedMemberIds = const <String>[],
    this.proposedChanges,
    required this.createdAt,
  });

  factory BuyerCollaborationCommentDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final authorId = json['authorId'];
    final authorType = json['authorType'];
    final authorName = json['authorName'];
    final visibility = json['visibility'];
    final itemId = json['itemId'];
    final kind = json['kind'];
    final body = json['body'];
    final rawAttachments = json['attachments'];
    final rawMentions = json['mentionedMemberIds'];
    final rawProposedChanges = json['proposedChanges'];
    final createdAt = json['createdAt'];

    if (authorId is! String ||
        authorType is! String ||
        (authorName != null && authorName is! String) ||
        visibility is! String ||
        (itemId != null && itemId is! String) ||
        kind is! String ||
        body is! String ||
        createdAt is! Timestamp) {
      throw const ValidationException(
        'Invalid buyer collaboration comment payload.',
        code: 'invalid_buyer_collaboration_comment_payload',
      );
    }

    return BuyerCollaborationCommentDto(
      id: id,
      authorId: authorId,
      authorType: authorType,
      authorName: authorName as String?,
      visibility: visibility,
      itemId: itemId as String?,
      kind: kind,
      body: body,
      attachments: _attachmentDtosFromJson(rawAttachments),
      mentionedMemberIds: _stringListFromJson(rawMentions),
      proposedChanges: rawProposedChanges == null
          ? null
          : _proposedChangeDtosFromJson(rawProposedChanges),
      createdAt: createdAt.toDate(),
    );
  }

  final String id;
  final String authorId;
  final String authorType;
  final String? authorName;
  final String visibility;
  final String? itemId;
  final String kind;
  final String body;
  final List<BuyerCollaborationAttachmentDto> attachments;
  final List<String> mentionedMemberIds;
  final List<BuyerCollaborationProposedChangeDto>? proposedChanges;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'authorId': authorId,
    'authorType': authorType,
    'authorName': authorName,
    'visibility': visibility,
    'itemId': itemId,
    'kind': kind,
    'body': body,
    'attachments': attachments.map((a) => a.toJson()).toList(growable: false),
    'mentionedMemberIds': mentionedMemberIds,
    'proposedChanges': proposedChanges
        ?.map((change) => change.toJson())
        .toList(growable: false),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

List<BuyerCollaborationAttachmentDto> _attachmentDtosFromJson(Object? value) {
  if (value == null) return const <BuyerCollaborationAttachmentDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid buyer collaboration attachments payload.',
      code: 'invalid_buyer_collaboration_comment_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid buyer collaboration attachment payload.',
            code: 'invalid_buyer_collaboration_comment_payload',
          );
        }
        return BuyerCollaborationAttachmentDto.fromJson(item);
      })
      .toList(growable: false);
}

List<BuyerCollaborationProposedChangeDto> _proposedChangeDtosFromJson(
  Object? value,
) {
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid buyer collaboration proposed changes payload.',
      code: 'invalid_buyer_collaboration_comment_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid buyer collaboration proposed change payload.',
            code: 'invalid_buyer_collaboration_comment_payload',
          );
        }
        return BuyerCollaborationProposedChangeDto.fromJson(item);
      })
      .toList(growable: false);
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid buyer collaboration string list payload.',
      code: 'invalid_buyer_collaboration_comment_payload',
    );
  }
  return value.whereType<String>().toList(growable: false);
}

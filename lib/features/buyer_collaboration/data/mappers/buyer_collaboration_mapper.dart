import '../../domain/entities/buyer_collaboration_attachment.dart';
import '../../domain/entities/buyer_collaboration_comment.dart';
import '../../domain/entities/buyer_collaboration_item.dart';
import '../../domain/entities/buyer_collaboration_proposed_change.dart';
import '../../domain/entities/buyer_collaboration_session.dart';
import '../../domain/value_objects/buyer_collaboration_comment_kind.dart';
import '../../domain/value_objects/buyer_collaboration_source_type.dart';
import '../../domain/value_objects/buyer_collaboration_status.dart';
import '../dtos/buyer_collaboration_comment_dto.dart';
import '../dtos/buyer_collaboration_session_dto.dart';

extension BuyerCollaborationItemDtoMapper on BuyerCollaborationItemDto {
  BuyerCollaborationItem toDomain() => BuyerCollaborationItem(
    itemId: itemId,
    productId: productId,
    productName: productName,
    variantId: variantId,
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: subtotal,
  );

  static BuyerCollaborationItemDto fromDomain(BuyerCollaborationItem item) =>
      BuyerCollaborationItemDto(
        itemId: item.itemId,
        productId: item.productId,
        productName: item.productName,
        variantId: item.variantId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: item.subtotal,
      );
}

extension BuyerCollaborationSessionDtoMapper on BuyerCollaborationSessionDto {
  BuyerCollaborationSession toDomain() => BuyerCollaborationSession(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    sellerId: sellerId,
    customerId: customerId,
    sourceType: BuyerCollaborationSourceType.fromCode(sourceType),
    sourceId: sourceId,
    priceListId: priceListId,
    status: BuyerCollaborationStatus.fromCode(status),
    items: items.map((item) => item.toDomain()).toList(growable: false),
    showPrices: showPrices,
    currentTotal: currentTotal,
    convertedOrderId: convertedOrderId,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastActivityAt: lastActivityAt,
    expiresAt: expiresAt,
  );
}

extension BuyerCollaborationAttachmentDtoMapper
    on BuyerCollaborationAttachmentDto {
  BuyerCollaborationAttachment toDomain() => BuyerCollaborationAttachment(
    name: name,
    url: url,
    contentType: contentType,
  );

  static BuyerCollaborationAttachmentDto fromDomain(
    BuyerCollaborationAttachment attachment,
  ) => BuyerCollaborationAttachmentDto(
    name: attachment.name,
    url: attachment.url,
    contentType: attachment.contentType,
  );
}

extension BuyerCollaborationProposedChangeDtoMapper
    on BuyerCollaborationProposedChangeDto {
  BuyerCollaborationProposedChange toDomain() =>
      BuyerCollaborationProposedChange(
        itemId: itemId,
        action: BuyerCollaborationProposedChangeAction.fromCode(action),
        requestedQuantity: requestedQuantity,
        productId: productId,
        variantId: variantId,
        productName: productName,
      );

  static BuyerCollaborationProposedChangeDto fromDomain(
    BuyerCollaborationProposedChange change,
  ) => BuyerCollaborationProposedChangeDto(
    itemId: change.itemId,
    action: change.action.code,
    requestedQuantity: change.requestedQuantity,
    productId: change.productId,
    variantId: change.variantId,
    productName: change.productName,
  );
}

extension BuyerCollaborationCommentDtoMapper on BuyerCollaborationCommentDto {
  BuyerCollaborationComment toDomain() => BuyerCollaborationComment(
    id: id,
    authorId: authorId,
    authorType: BuyerCollaborationAuthorType.fromCode(authorType),
    authorName: authorName,
    visibility: BuyerCollaborationCommentVisibility.fromCode(visibility),
    itemId: itemId,
    kind: BuyerCollaborationCommentKind.fromCode(kind),
    body: body,
    attachments: attachments
        .map((attachment) => attachment.toDomain())
        .toList(growable: false),
    mentionedMemberIds: mentionedMemberIds,
    proposedChanges: proposedChanges
        ?.map((change) => change.toDomain())
        .toList(growable: false),
    createdAt: createdAt,
  );
}

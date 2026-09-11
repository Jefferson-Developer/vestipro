import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/buyer_collaboration_attachment.dart';
import '../entities/buyer_collaboration_comment.dart';
import '../entities/buyer_collaboration_conversion_result.dart';
import '../entities/buyer_collaboration_item.dart';
import '../entities/buyer_collaboration_proposed_change.dart';
import '../entities/buyer_collaboration_session.dart';
import '../repositories/buyer_collaboration_repository.dart';
import '../value_objects/buyer_collaboration_comment_kind.dart';
import '../value_objects/buyer_collaboration_source_type.dart';

@injectable
final class CreateBuyerCollaborationSessionUseCase {
  const CreateBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<String>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required BuyerCollaborationSourceType sourceType,
    required String sourceId,
    required List<BuyerCollaborationItem> items,
    required bool showPrices,
  }) {
    if (items.isEmpty) {
      return Future.value(
        const AppFailure(
          ValidationFailure('Inclua ao menos um item na seleção.'),
        ),
      );
    }
    return _repository.createSession(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      priceListId: priceListId,
      sourceType: sourceType,
      sourceId: sourceId,
      items: items,
      showPrices: showPrices,
    );
  }
}

@injectable
final class ShareBuyerCollaborationSessionUseCase {
  const ShareBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItem>? items,
    String? note,
  }) {
    if (items != null && items.isEmpty) {
      return Future.value(
        const AppFailure(
          ValidationFailure('A seleção precisa ter ao menos um item.'),
        ),
      );
    }
    return _repository.shareSession(
      organizationId: organizationId,
      sessionId: sessionId,
      items: items,
      note: note,
    );
  }
}

@injectable
final class AddBuyerCollaborationCommentUseCase {
  const AddBuyerCollaborationCommentUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    BuyerCollaborationCommentVisibility visibility =
        BuyerCollaborationCommentVisibility.shared,
    List<BuyerCollaborationAttachment> attachments =
        const <BuyerCollaborationAttachment>[],
    List<String> mentionedMemberIds = const <String>[],
  }) {
    if (body.trim().isEmpty) {
      return Future.value(
        const AppFailure(ValidationFailure('Escreva um comentário.')),
      );
    }
    return _repository.addComment(
      organizationId: organizationId,
      sessionId: sessionId,
      body: body.trim(),
      itemId: itemId,
      visibility: visibility,
      attachments: attachments,
      mentionedMemberIds: mentionedMemberIds,
    );
  }
}

@injectable
final class RequestBuyerCollaborationChangesUseCase {
  const RequestBuyerCollaborationChangesUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String sessionId,
    required String comment,
    List<BuyerCollaborationProposedChange> proposedChanges =
        const <BuyerCollaborationProposedChange>[],
  }) {
    if (comment.trim().isEmpty) {
      return Future.value(
        const AppFailure(
          ValidationFailure('Descreva a alteração que você gostaria de pedir.'),
        ),
      );
    }
    return _repository.requestChanges(
      organizationId: organizationId,
      sessionId: sessionId,
      comment: comment.trim(),
      proposedChanges: proposedChanges,
    );
  }
}

@injectable
final class ApproveBuyerCollaborationSessionUseCase {
  const ApproveBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String sessionId,
    String? comment,
  }) => _repository.approve(
    organizationId: organizationId,
    sessionId: sessionId,
    comment: comment,
  );
}

@injectable
final class ConvertBuyerCollaborationSessionUseCase {
  const ConvertBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<BuyerCollaborationConversionResult>> call({
    required String organizationId,
    required String sessionId,
    required String orderId,
    bool acceptPriceDrift = false,
  }) => _repository.convert(
    organizationId: organizationId,
    sessionId: sessionId,
    orderId: orderId,
    acceptPriceDrift: acceptPriceDrift,
  );
}

@injectable
final class ReopenBuyerCollaborationSessionUseCase {
  const ReopenBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String sessionId,
  }) =>
      _repository.reopen(organizationId: organizationId, sessionId: sessionId);
}

@injectable
final class WatchBuyerCollaborationSessionUseCase {
  const WatchBuyerCollaborationSessionUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Stream<AppResult<BuyerCollaborationSession?>> call({
    required String organizationId,
    required String sessionId,
  }) => _repository.watchSession(
    organizationId: organizationId,
    sessionId: sessionId,
  );
}

@injectable
final class WatchBuyerCollaborationCommentsUseCase {
  const WatchBuyerCollaborationCommentsUseCase(this._repository);
  final BuyerCollaborationRepository _repository;

  Stream<AppResult<List<BuyerCollaborationComment>>> call({
    required String organizationId,
    required String sessionId,
  }) => _repository.watchComments(
    organizationId: organizationId,
    sessionId: sessionId,
  );
}

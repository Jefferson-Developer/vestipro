import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/buyer_collaboration_attachment.dart';
import '../../domain/entities/buyer_collaboration_comment.dart';
import '../../domain/entities/buyer_collaboration_conversion_result.dart';
import '../../domain/entities/buyer_collaboration_item.dart';
import '../../domain/entities/buyer_collaboration_proposed_change.dart';
import '../../domain/entities/buyer_collaboration_session.dart';
import '../../domain/repositories/buyer_collaboration_repository.dart';
import '../../domain/value_objects/buyer_collaboration_comment_kind.dart';
import '../../domain/value_objects/buyer_collaboration_source_type.dart';
import '../datasources/buyer_collaboration_read_data_source.dart';
import '../datasources/buyer_collaboration_write_data_source.dart';
import '../mappers/buyer_collaboration_mapper.dart';

@LazySingleton(as: BuyerCollaborationRepository)
final class BuyerCollaborationRepositoryImpl
    implements BuyerCollaborationRepository {
  const BuyerCollaborationRepositoryImpl(
    this._readDataSource,
    this._writeDataSource,
  );

  final BuyerCollaborationReadDataSource _readDataSource;
  final BuyerCollaborationWriteDataSource _writeDataSource;

  @override
  Future<AppResult<String>> createSession({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required BuyerCollaborationSourceType sourceType,
    required String sourceId,
    required List<BuyerCollaborationItem> items,
    required bool showPrices,
  }) => _guard(() async {
    return _writeDataSource.create(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      priceListId: priceListId,
      sourceType: sourceType.code,
      sourceId: sourceId,
      items: items
          .map((item) => BuyerCollaborationItemDtoMapper.fromDomain(item))
          .toList(growable: false),
      showPrices: showPrices,
    );
  });

  @override
  Future<AppResult<void>> shareSession({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItem>? items,
    String? note,
  }) => _guard(() {
    return _writeDataSource.share(
      organizationId: organizationId,
      sessionId: sessionId,
      items: items
          ?.map((item) => BuyerCollaborationItemDtoMapper.fromDomain(item))
          .toList(growable: false),
      note: note,
    );
  });

  @override
  Future<AppResult<void>> addComment({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    BuyerCollaborationCommentVisibility visibility =
        BuyerCollaborationCommentVisibility.shared,
    List<BuyerCollaborationAttachment> attachments =
        const <BuyerCollaborationAttachment>[],
    List<String> mentionedMemberIds = const <String>[],
  }) => _guard(() {
    return _writeDataSource.addComment(
      organizationId: organizationId,
      sessionId: sessionId,
      body: body,
      itemId: itemId,
      visibility: visibility.code,
      attachments: attachments
          .map(
            (attachment) => BuyerCollaborationAttachmentDtoMapper.fromDomain(
              attachment,
            ).toJson(),
          )
          .toList(growable: false),
      mentionedMemberIds: mentionedMemberIds,
    );
  });

  @override
  Future<AppResult<void>> requestChanges({
    required String organizationId,
    required String sessionId,
    required String comment,
    List<BuyerCollaborationProposedChange> proposedChanges =
        const <BuyerCollaborationProposedChange>[],
  }) => _guard(() {
    return _writeDataSource.requestChanges(
      organizationId: organizationId,
      sessionId: sessionId,
      comment: comment,
      proposedChanges: proposedChanges
          .map(
            (change) => BuyerCollaborationProposedChangeDtoMapper.fromDomain(
              change,
            ).toJson(),
          )
          .toList(growable: false),
    );
  });

  @override
  Future<AppResult<void>> approve({
    required String organizationId,
    required String sessionId,
    String? comment,
  }) => _guard(() {
    return _writeDataSource.approve(
      organizationId: organizationId,
      sessionId: sessionId,
      comment: comment,
    );
  });

  @override
  Future<AppResult<BuyerCollaborationConversionResult>> convert({
    required String organizationId,
    required String sessionId,
    required String orderId,
    bool acceptPriceDrift = false,
  }) => _guard(() async {
    final result = await _writeDataSource.convert(
      organizationId: organizationId,
      sessionId: sessionId,
      orderId: orderId,
      acceptPriceDrift: acceptPriceDrift,
    );
    return BuyerCollaborationConversionResult(
      converted: result.converted,
      orderId: result.orderId,
      priceDrift: result.priceDrift
          .map(
            (drift) => BuyerCollaborationPriceDrift(
              itemId: drift.itemId,
              variantId: drift.variantId,
              approvedUnitPrice: drift.approvedUnitPrice,
              currentUnitPrice: drift.currentUnitPrice,
            ),
          )
          .toList(growable: false),
    );
  });

  @override
  Future<AppResult<void>> reopen({
    required String organizationId,
    required String sessionId,
  }) => _guard(() {
    return _writeDataSource.reopen(
      organizationId: organizationId,
      sessionId: sessionId,
    );
  });

  @override
  Stream<AppResult<BuyerCollaborationSession?>> watchSession({
    required String organizationId,
    required String sessionId,
  }) async* {
    try {
      await for (final dto in _readDataSource.watchSession(
        organizationId: organizationId,
        sessionId: sessionId,
      )) {
        yield AppSuccess<BuyerCollaborationSession?>(dto?.toDomain());
      }
    } catch (error) {
      yield AppFailure<BuyerCollaborationSession?>(
        UnexpectedFailure(
          'Unexpected error loading the buyer collaboration session.',
          code: 'buyer_collaboration_session_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<BuyerCollaborationComment>>> watchComments({
    required String organizationId,
    required String sessionId,
  }) async* {
    try {
      await for (final dtos in _readDataSource.watchComments(
        organizationId: organizationId,
        sessionId: sessionId,
      )) {
        yield AppSuccess<List<BuyerCollaborationComment>>(
          dtos.map((dto) => dto.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<BuyerCollaborationComment>>(
        UnexpectedFailure(
          'Unexpected error loading the buyer collaboration comments.',
          code: 'buyer_collaboration_comments_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Unexpected error managing the buyer collaboration session.',
          code: 'buyer_collaboration_unexpected',
          cause: error,
        ),
      );
    }
  }
}

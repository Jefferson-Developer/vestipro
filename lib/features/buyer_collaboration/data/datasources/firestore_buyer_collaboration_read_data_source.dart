import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/buyer_collaboration_comment_dto.dart';
import '../dtos/buyer_collaboration_session_dto.dart';
import 'buyer_collaboration_read_data_source.dart';

/// [BuyerCollaborationReadDataSource] backed directly by `cloud_firestore`
/// (TASK-211) — the same "read-only via Rules, write only via Cloud
/// Function" contract `orders`/`returnRequests`/`exchangeRequests` already
/// use: every mutation lives in [CloudFunctionsBuyerCollaborationWriteDataSource]
/// instead. The session document reuses [FirestoreCollectionDataSource]
/// (same helper `FirestoreExchangeRequestDataSource` uses); `comments` is a
/// subcollection one level deeper than that generic helper models, so it is
/// queried directly here — still entirely inside the data layer, never
/// reached by `presentation/` (`AGENTS.md`: "UI não acessa Firestore [...]
/// diretamente").
@LazySingleton(as: BuyerCollaborationReadDataSource)
final class FirestoreBuyerCollaborationReadDataSource
    implements BuyerCollaborationReadDataSource {
  FirestoreBuyerCollaborationReadDataSource(this._firestore)
    : _sessions = FirestoreCollectionDataSource<BuyerCollaborationSessionDto>(
        firestore: _firestore,
        collectionName: 'buyerCollaborationSessions',
        converter: FirestoreConverter<BuyerCollaborationSessionDto>(
          fromJson: (data, id) =>
              BuyerCollaborationSessionDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<BuyerCollaborationSessionDto> _sessions;

  @override
  Stream<BuyerCollaborationSessionDto?> watchSession({
    required String organizationId,
    required String sessionId,
  }) {
    return _sessions.getStream(organizationId: organizationId, id: sessionId);
  }

  @override
  Stream<List<BuyerCollaborationCommentDto>> watchComments({
    required String organizationId,
    required String sessionId,
  }) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('buyerCollaborationSessions')
        .doc(sessionId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(500)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BuyerCollaborationCommentDto.fromJson(
                  doc.data(),
                  id: doc.id,
                ),
              )
              .toList(growable: false),
        )
        .handleError(
          (Object error, StackTrace stackTrace) =>
              throw mapFirestoreExceptionToAppException(
                error as FirebaseException,
                stackTrace,
              ),
          test: (error) => error is FirebaseException,
        );
  }
}

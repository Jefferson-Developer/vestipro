import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/favorite_dto.dart';
import '../../domain/entities/favorite_product.dart';
import 'favorite_remote_data_source.dart';

/// Firestore-backed [FavoriteRemoteDataSource] for the
/// `organizations/{organizationId}/favorites` subcollection (TASK-079).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly, same as every other Firestore datasource in
/// this codebase. Documents are keyed by `{userId}_{productId}` (never the
/// bare product id) so two different users favoriting the same product never
/// collide, and Firestore Security Rules can gate every read/write on
/// `resource.data.userId == request.auth.uid` without reading the path.
@LazySingleton(as: FavoriteRemoteDataSource)
final class FirestoreFavoriteRemoteDataSource
    implements FavoriteRemoteDataSource {
  FirestoreFavoriteRemoteDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<FavoriteDto>(
        firestore: firestore,
        collectionName: 'favorites',
        converter: FirestoreConverter<FavoriteDto>(
          fromJson: (data, id) => FavoriteDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<FavoriteDto> _collection;

  @override
  Future<void> upsert(FavoriteProduct favorite) {
    final id = _documentId(
      userId: favorite.userId,
      productId: favorite.productId,
    );
    return _collection.set(
      organizationId: favorite.organizationId,
      id: id,
      value: FavoriteDto(
        id: id,
        organizationId: favorite.organizationId,
        userId: favorite.userId,
        productId: favorite.productId,
        companyId: favorite.companyId,
        createdAt: favorite.createdAt,
      ),
    );
  }

  @override
  Future<void> delete({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    // Personal favorites carry no business/audit value once removed, unlike
    // customer/product/order documents — a hard delete (not `softDelete`)
    // is the right call here, mirroring how the local tombstone is also
    // physically removed once its deletion is confirmed synced.
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('favorites')
        .doc(_documentId(userId: userId, productId: productId))
        .delete();
  }

  String _documentId({required String userId, required String productId}) =>
      '${userId}_$productId';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/post_sale_event_dto.dart';
import 'post_sale_event_read_data_source.dart';

@LazySingleton(as: PostSaleEventReadDataSource)
final class FirestorePostSaleEventDataSource
    implements PostSaleEventReadDataSource {
  FirestorePostSaleEventDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<PostSaleEventDto>(
        firestore: firestore,
        collectionName: 'postSaleEvents',
        converter: FirestoreConverter<PostSaleEventDto>(
          fromJson: (data, id) => PostSaleEventDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<PostSaleEventDto> _collection;

  @override
  Stream<List<PostSaleEventDto>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    return _collection.watchQuery(
      organizationId: organizationId,
      limit: 100,
      queryBuilder: (query) => query
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true),
    );
  }
}

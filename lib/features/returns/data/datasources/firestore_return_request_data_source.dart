import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/return_request_dto.dart';
import 'return_request_read_data_source.dart';

/// Firestore's `whereIn` accepts at most this many values per query — same
/// cap/precedent `kOrderSellerIdsQueryLimit` already sets for the exact same
/// "a manager's own team of sellers" shape (`firestore.rules` still
/// independently denies any document outside the real caller's visibility
/// regardless of how many sellers this query actually covers).
const int kReturnRequestSellerIdsQueryLimit = 30;

@LazySingleton(as: ReturnRequestReadDataSource)
final class FirestoreReturnRequestDataSource
    implements ReturnRequestReadDataSource {
  FirestoreReturnRequestDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<ReturnRequestDto>(
        firestore: firestore,
        collectionName: 'returnRequests',
        converter: FirestoreConverter<ReturnRequestDto>(
          fromJson: (data, id) => ReturnRequestDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ReturnRequestDto> _collection;

  @override
  Stream<List<ReturnRequestDto>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    return _collection.watchQuery(
      organizationId: organizationId,
      limit: 50,
      queryBuilder: (query) => query
          .where('orderId', isEqualTo: orderId)
          .orderBy('requestedAt', descending: true),
    );
  }

  @override
  Stream<List<ReturnRequestDto>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    required Set<String> sellerIds,
  }) {
    if (!allCompany && sellerIds.isEmpty) {
      return const Stream<List<ReturnRequestDto>>.empty();
    }
    return _collection.watchQuery(
      organizationId: organizationId,
      limit: 100,
      queryBuilder: (query) {
        var scoped = query
            .where('companyId', isEqualTo: companyId)
            .where('status', isEqualTo: 'requested')
            .orderBy('requestedAt', descending: true);
        if (!allCompany) {
          if (sellerIds.length == 1) {
            scoped = scoped.where('sellerId', isEqualTo: sellerIds.first);
          } else {
            scoped = scoped.where(
              'sellerId',
              whereIn: sellerIds
                  .take(kReturnRequestSellerIdsQueryLimit)
                  .toList(),
            );
          }
        }
        return scoped;
      },
    );
  }
}

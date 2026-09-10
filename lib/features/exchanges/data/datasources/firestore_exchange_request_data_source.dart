import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/exchange_request_dto.dart';
import 'exchange_request_read_data_source.dart';

/// Firestore's `whereIn` accepts at most this many values per query — same
/// cap/precedent `kReturnRequestSellerIdsQueryLimit` already sets for the
/// exact same "a manager's own team of sellers" shape (`firestore.rules`
/// still independently denies any document outside the real caller's
/// visibility regardless of how many sellers this query actually covers).
const int kExchangeRequestSellerIdsQueryLimit = 30;

@LazySingleton(as: ExchangeRequestReadDataSource)
final class FirestoreExchangeRequestDataSource
    implements ExchangeRequestReadDataSource {
  FirestoreExchangeRequestDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<ExchangeRequestDto>(
        firestore: firestore,
        collectionName: 'exchangeRequests',
        converter: FirestoreConverter<ExchangeRequestDto>(
          fromJson: (data, id) => ExchangeRequestDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ExchangeRequestDto> _collection;

  @override
  Stream<List<ExchangeRequestDto>> watchByOrder({
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
  Stream<List<ExchangeRequestDto>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    required Set<String> sellerIds,
  }) {
    if (!allCompany && sellerIds.isEmpty) {
      return const Stream<List<ExchangeRequestDto>>.empty();
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
                  .take(kExchangeRequestSellerIdsQueryLimit)
                  .toList(),
            );
          }
        }
        return scoped;
      },
    );
  }
}

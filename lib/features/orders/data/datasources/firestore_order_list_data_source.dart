import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/order_dto.dart';
import '../dtos/order_list_page_dto.dart';
import 'order_list_data_source.dart';

/// Firestore's `whereIn` accepts at most this many values per query — a
/// [OrderListDataSource.listPageByCompany] call with more visible sellers
/// than this (a very large managed team) silently narrows to the first 30
/// instead of failing the whole page; `firestore.rules` still independently
/// denies any document outside the real caller's visibility regardless.
const int kOrderSellerIdsQueryLimit = 30;

@LazySingleton(as: OrderListDataSource)
final class FirestoreOrderListDataSource implements OrderListDataSource {
  FirestoreOrderListDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<OrderDto>(
        firestore: firestore,
        collectionName: 'orders',
        converter: FirestoreConverter<OrderDto>(
          fromJson: (data, id) => OrderDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<OrderDto> _collection;

  @override
  Future<OrderListPageDto> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    String? status,
    String? customerId,
    String? orderNumber,
    Set<String> sellerIds = const <String>{},
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query
            .where('companyId', isEqualTo: companyId)
            .where('deletedAt', isNull: true)
            .orderBy('createdAt', descending: true);
        if (status != null && status.isNotEmpty) {
          scoped = scoped.where('status', isEqualTo: status);
        }
        if (customerId != null && customerId.isNotEmpty) {
          scoped = scoped.where('customerId', isEqualTo: customerId);
        }
        if (orderNumber != null && orderNumber.isNotEmpty) {
          scoped = scoped.where('orderNumber', isEqualTo: orderNumber);
        }
        if (sellerIds.length == 1) {
          scoped = scoped.where('sellerId', isEqualTo: sellerIds.first);
        } else if (sellerIds.length > 1) {
          scoped = scoped.where(
            'sellerId',
            whereIn: sellerIds.take(kOrderSellerIdsQueryLimit).toList(),
          );
        }
        if (before != null) {
          scoped = scoped.where(
            'createdAt',
            isLessThan: Timestamp.fromDate(before),
          );
        }
        if (from != null) {
          scoped = scoped.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          );
        }
        if (to != null) {
          scoped = scoped.where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(to),
          );
        }
        return scoped;
      },
    );
    return OrderListPageDto(items: page.items, hasMore: page.hasMore);
  }

  @override
  Future<OrderDto?> getById({
    required String organizationId,
    required String id,
  }) {
    return _collection.getById(organizationId: organizationId, id: id);
  }
}

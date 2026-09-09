import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/commission_entry_dto.dart';
import 'commission_entry_data_source.dart';

@LazySingleton(as: CommissionEntryDataSource)
final class FirestoreCommissionEntryDataSource
    implements CommissionEntryDataSource {
  FirestoreCommissionEntryDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<CommissionEntryDto>(
        firestore: firestore,
        collectionName: 'commissionEntries',
        converter: FirestoreConverter<CommissionEntryDto>(
          fromJson: (data, id) => CommissionEntryDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<CommissionEntryDto> _collection;

  @override
  Stream<List<CommissionEntryDto>> watchEntries({
    required String organizationId,
    required String companyId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    String? status,
  }) {
    return _collection.watchQuery(
      organizationId: organizationId,
      limit: 100,
      queryBuilder: (query) {
        var scoped = query
            .where('companyId', isEqualTo: companyId)
            .where(
              'occurredAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from),
            )
            .where('occurredAt', isLessThan: Timestamp.fromDate(to))
            .orderBy('occurredAt', descending: true);
        if (sellerId != null && sellerId.isNotEmpty) {
          scoped = scoped.where('sellerId', isEqualTo: sellerId);
        }
        if (status != null && status.isNotEmpty) {
          scoped = scoped.where('status', isEqualTo: status);
        }
        return scoped;
      },
    );
  }
}

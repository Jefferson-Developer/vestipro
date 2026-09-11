import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/receivable_dto.dart';
import 'receivables_read_data_source.dart';

/// [ReceivablesReadDataSource] backed directly by `cloud_firestore`
/// (TASK-213) — same "read-only via Rules, write only via Cloud Function"
/// contract `FirestoreCreditReadDataSource` (TASK-212) already follows.
@LazySingleton(as: ReceivablesReadDataSource)
final class FirestoreReceivablesReadDataSource
    implements ReceivablesReadDataSource {
  FirestoreReceivablesReadDataSource(FirebaseFirestore firestore)
    : _receivables = FirestoreCollectionDataSource<ReceivableDto>(
        firestore: firestore,
        collectionName: 'receivables',
        converter: FirestoreConverter<ReceivableDto>(
          fromJson: (data, id) => ReceivableDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ReceivableDto> _receivables;

  @override
  Stream<List<ReceivableDto>> watchReceivables({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) {
    return _receivables.watchQuery(
      organizationId: organizationId,
      limit: 200,
      queryBuilder: (query) {
        var scoped = query.where('customerId', isEqualTo: customerId);
        if (orderId != null) {
          scoped = scoped.where('orderId', isEqualTo: orderId);
        }
        return scoped.orderBy('dueDate', descending: false);
      },
    );
  }
}

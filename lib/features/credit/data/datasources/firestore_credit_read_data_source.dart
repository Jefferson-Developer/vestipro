import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/customer_credit_profile_dto.dart';
import 'credit_read_data_source.dart';

/// [CreditReadDataSource] backed directly by `cloud_firestore` (TASK-212) —
/// same "read-only via Rules, write only via Cloud Function" contract
/// `FirestoreBuyerCollaborationReadDataSource` (TASK-211) already follows.
@LazySingleton(as: CreditReadDataSource)
final class FirestoreCreditReadDataSource implements CreditReadDataSource {
  FirestoreCreditReadDataSource(FirebaseFirestore firestore)
    : _profiles = FirestoreCollectionDataSource<CustomerCreditProfileDto>(
        firestore: firestore,
        collectionName: 'creditProfiles',
        converter: FirestoreConverter<CustomerCreditProfileDto>(
          fromJson: (data, id) =>
              CustomerCreditProfileDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<CustomerCreditProfileDto> _profiles;

  @override
  Stream<CustomerCreditProfileDto?> watchProfile({
    required String organizationId,
    required String customerId,
  }) {
    return _profiles.getStream(organizationId: organizationId, id: customerId);
  }
}

import '../../../../core/utils/utils.dart';
import '../entities/consent_record.dart';

abstract interface class ConsentRepository {
  Future<AppResult<List<ConsentRecord>>> listUserConsents({
    required String organizationId,
    required String userId,
  });

  Stream<AppResult<List<ConsentRecord>>> watchUserConsents({
    required String organizationId,
    required String userId,
  });

  Future<AppResult<void>> appendConsentRecord(ConsentRecord record);
}

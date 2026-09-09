import '../../../../core/utils/utils.dart';
import '../entities/commission_entry.dart';

abstract interface class CommissionRepository {
  Stream<AppResult<List<CommissionEntry>>> watchEntries({
    required String organizationId,
    required String companyId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    CommissionEntryStatus? status,
  });
}

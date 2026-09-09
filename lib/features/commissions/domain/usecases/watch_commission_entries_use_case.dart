import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/commission_entry.dart';
import '../repositories/commission_repository.dart';

@injectable
final class WatchCommissionEntriesUseCase {
  const WatchCommissionEntriesUseCase(this._repository);

  final CommissionRepository _repository;

  Stream<AppResult<List<CommissionEntry>>> call({
    required String organizationId,
    required String companyId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    CommissionEntryStatus? status,
  }) {
    return _repository.watchEntries(
      organizationId: organizationId,
      companyId: companyId,
      from: from,
      to: to,
      sellerId: sellerId,
      status: status,
    );
  }
}

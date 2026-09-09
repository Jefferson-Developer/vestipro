import '../dtos/commission_entry_dto.dart';

abstract interface class CommissionEntryDataSource {
  Stream<List<CommissionEntryDto>> watchEntries({
    required String organizationId,
    required String companyId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    String? status,
  });
}

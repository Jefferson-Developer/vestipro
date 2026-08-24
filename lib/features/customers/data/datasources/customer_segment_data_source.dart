import '../dtos/customer_segment_dto.dart';

/// Raw persistence contract for [CustomerSegmentDto]s, scoped per
/// organization. See `SharedPreferencesCustomerSegmentDataSource` for the
/// current implementation.
abstract interface class CustomerSegmentDataSource {
  Future<List<CustomerSegmentDto>> listByOrganization(String organizationId);

  Future<void> upsert(CustomerSegmentDto dto);

  Future<void> delete({required String organizationId, required String id});
}

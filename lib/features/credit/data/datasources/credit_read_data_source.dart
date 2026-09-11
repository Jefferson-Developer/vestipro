import '../dtos/customer_credit_profile_dto.dart';

/// Read-only, direct-Firestore access to `creditProfiles` (TASK-212) —
/// `firestore.rules`' own `creditProfiles` match block denies this stream
/// outright for any Membership without `finance.view`, so this datasource
/// never needs to re-check the caller's role itself: an unauthorized caller
/// simply never resolves a value (the stream errors, mapped by the
/// repository into an `AppFailure`).
abstract interface class CreditReadDataSource {
  Stream<CustomerCreditProfileDto?> watchProfile({
    required String organizationId,
    required String customerId,
  });
}

import '../dtos/receivable_dto.dart';

/// Read-only, direct-Firestore access to `receivables` (TASK-213) —
/// `firestore.rules`' own `receivables` match block denies this stream
/// outright for any Membership without `finance.view`, so this datasource
/// never needs to re-check the caller's role itself: an unauthorized caller
/// simply never resolves a value (the stream errors, mapped by the
/// repository into an `AppFailure`). Mirrors `CreditReadDataSource`
/// (TASK-212).
abstract interface class ReceivablesReadDataSource {
  Stream<List<ReceivableDto>> watchReceivables({
    required String organizationId,
    required String customerId,
    String? orderId,
  });
}

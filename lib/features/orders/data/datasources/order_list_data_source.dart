import '../dtos/order_dto.dart';
import '../dtos/order_list_page_dto.dart';

/// Data access contract for the paginated `organizations/{organizationId}/
/// orders` listing query (TASK-102). [FirestoreOrderListDataSource] is the
/// only implementation today.
abstract interface class OrderListDataSource {
  /// Lists one cursor page of [organizationId]/[companyId]'s Orders, newest
  /// first. [before] filters on `createdAt` for pagination; [from]/[to]
  /// narrow to a period; [status]/[customerId]/[orderNumber] are exact-match
  /// filters; [sellerIds] restricts to those sellers (a single id becomes an
  /// equality filter, more than one a `whereIn`, capped at Firestore's own
  /// 30-value limit — [OrderVisibilityService] callers are expected to stay
  /// within that in practice, a wider result is a documented limitation, not
  /// a security issue: `firestore.rules` still denies any document outside
  /// the caller's real visibility regardless of this query's shape).
  Future<OrderListPageDto> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    String? status,
    String? customerId,
    String? orderNumber,
    Set<String> sellerIds = const <String>{},
  });

  /// Single-document read of one Order (TASK-104's history/duplication
  /// flows), `null` when it does not exist.
  Future<OrderDto?> getById({
    required String organizationId,
    required String id,
  });
}

import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_list_filters.dart';
import '../entities/order_list_page_result.dart';

/// Contract for the server-side, cursor-paginated Order listing screen
/// (TASK-102) — deliberately separate from [OrderDraftRepository] (100%
/// local, autosave-only) and [OrderSubmissionRepository] (the one-shot
/// `submitOrder` call): this is the read-only, filterable/paginated view
/// over every Order the organization already has in Firestore.
///
/// [before] pages backwards through the list without leaking any
/// Firestore-specific cursor type into `domain/`: pass the previous page's
/// [OrderListPageResult.nextCursor] to fetch the next (strictly older) page —
/// same precedent `AuditLogRepository.listPageByOrganization`/
/// `StockAlertRepository.listPageByOrganization` already establish.
abstract interface class OrderListRepository {
  Future<AppResult<OrderListPageResult>> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    OrderListFilters filters = OrderListFilters.empty,
  });

  /// The single `Order` [id] of [organizationId]/[companyId], or `null` when
  /// it does not exist, belongs to a different company or is soft-deleted
  /// (TASK-104's history/duplication flows, both of which need a fresh,
  /// single-document read rather than paging through
  /// [listPageByCompany] looking for one id). `firestore.rules`'
  /// `canReadOrder` independently re-checks the same per-document
  /// visibility this already applies to a `get`, exactly like it does for
  /// every page [listPageByCompany] fetches.
  Future<AppResult<Order?>> getById({
    required String organizationId,
    required String companyId,
    required String id,
  });
}

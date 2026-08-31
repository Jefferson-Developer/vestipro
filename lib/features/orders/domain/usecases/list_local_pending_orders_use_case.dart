import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../repositories/order_draft_repository.dart';
import '../value_objects/order_sync_status.dart';

/// Lists every Order still pending sync on this device (TASK-102): a
/// `draft`/`pendingSync`/`syncing`/`failed`/`conflict` Order only exists
/// locally until `submitOrder` (TASK-101) actually confirms it, so the
/// pedidos listing screen must surface it separately from — and merged
/// with — the server's own paginated result, or it would simply be
/// invisible to the seller who just created it while offline.
///
/// Always scoped to [userId]: only ever reads [OrderDraftRepository]'s
/// local cache, which itself only ever holds Orders this exact device
/// created/edited as [Order.sellerId] — the filter here is defense-in-depth,
/// not the reason offline isolation holds.
@injectable
final class ListLocalPendingOrdersUseCase {
  const ListLocalPendingOrdersUseCase(this._repository);

  final OrderDraftRepository _repository;

  Future<AppResult<List<Order>>> call({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final result = await _repository.getLocalOrdersForCompany(
      organizationId: organizationId,
      companyId: companyId,
    );
    return result.fold(
      onSuccess: (orders) => AppSuccess<List<Order>>(
        orders
            .where(
              (order) =>
                  order.sellerId == userId &&
                  order.syncStatus != OrderSyncStatus.synced,
            )
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      ),
      onFailure: AppFailure<List<Order>>.new,
    );
  }
}

// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_draft_repository.dart';
import '../mappers/order_local_mapper.dart';

/// Drift-backed implementation of [OrderDraftRepository] (TASK-096).
///
/// Reuses the exact `OrdersTable`/`OrderItemsTable` schema and
/// [OrderLocalMapper] TASK-095 already introduced — this is that cache's
/// first read/write caller, not a new local store. [saveDraft] performs the
/// order row upsert and the full item-row replace inside a single Drift
/// transaction so a draft is never left with an order row whose item rows
/// do not match it, mirroring the same all-or-nothing guarantee
/// `AppDatabase.replaceOrders` already gives the initial-load path.
@LazySingleton(as: OrderDraftRepository)
final class DriftOrderDraftRepository implements OrderDraftRepository {
  const DriftOrderDraftRepository(this._database, this._mapper);

  final AppDatabase _database;
  final OrderLocalMapper _mapper;

  @override
  Future<AppResult<void>> saveDraft({required Order order}) async {
    try {
      final orderRow = _mapper.toOrderRow(order);
      final itemRows = _mapper.toItemRows(order);
      await _database.transaction(() async {
        await _database.upsertOrder(orderRow);
        await _database.replaceOrderItems(
          orderId: order.id,
          itemRows: itemRows,
        );
      });
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving local order draft.',
          code: 'order_draft_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    try {
      final row = await _database.getOrderById(
        organizationId: organizationId,
        companyId: companyId,
        id: id,
      );
      if (row == null) return const AppSuccess<Order?>(null);
      return AppSuccess<Order?>(_mapper.fromRow(row));
    } catch (exception) {
      return AppFailure<Order?>(
        UnexpectedFailure(
          'Unexpected error loading local order draft.',
          code: 'order_draft_read_unexpected',
          cause: exception,
        ),
      );
    }
  }
}

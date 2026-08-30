import '../../../../core/utils/utils.dart';
import '../entities/order.dart';

/// Domain contract for the fully offline persistence of an `Order` draft
/// (EPIC-13, TASK-096).
///
/// Deliberately the only entry point either the draft creation flow or the
/// autosave flow ever calls to persist an `Order`: both are 100% local —
/// neither this contract nor any of its implementations may perform a
/// network call. Submitting a draft (turning it into a `pendingSync`/
/// `submitted` Order the sync engine picks up) is a later EPIC-13/EPIC-14
/// task's concern, not this one.
abstract interface class OrderDraftRepository {
  /// Persists [order] locally — insert on first save, full replace of its
  /// own row and every one of its item rows on every subsequent save
  /// (mirrors `AppDatabase.upsertOrder`/`replaceOrderItems`). Never contacts
  /// the network.
  Future<AppResult<void>> saveDraft({required Order order});

  /// The locally stored `Order` [id] scoped to [organizationId]/[companyId],
  /// or `null` when no such draft exists (already submitted/synced orders
  /// remain readable through this same method — it is not restricted to
  /// [OrderStatus.draft] alone, callers decide what to do with the status
  /// they get back).
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  });
}

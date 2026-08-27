import '../../../../core/utils/utils.dart';
import '../entities/price_list.dart';

/// Domain contract for the on-device Price List cache (TASK-083), the
/// offline counterpart of [PriceListRepository] — same shape as
/// `CustomerLocalStoreRepository` (TASK-054).
///
/// Implementations must never persist a Price List outside the
/// `organizationId`/`companyId` scope of the call.
abstract interface class PriceListLocalStoreRepository {
  /// Replaces every locally stored Price List for [organizationId]/
  /// [companyId] with exactly [priceLists] — the "carga inicial" primitive,
  /// a full idempotent replace rather than an incremental merge.
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PriceList> priceLists,
  });

  /// Inserts or updates exactly one locally stored Price List — the
  /// incremental-update primitive the future sync engine (EPIC-14) uses to
  /// keep the local cache fresh after the initial load without replacing
  /// the whole set.
  Future<AppResult<void>> upsert({required PriceList priceList});

  /// Every Price List currently stored locally for [organizationId]/
  /// [companyId], in no particular order.
  Future<AppResult<List<PriceList>>> getAll({
    required String organizationId,
    required String companyId,
  });

  /// Number of Price Lists currently stored locally for [organizationId]/
  /// [companyId], without materializing every row.
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  });
}

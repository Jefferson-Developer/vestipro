import '../../../../core/utils/utils.dart';
import '../entities/commercial_pack.dart';

/// Domain contract for the on-device `CommercialPack` cache (TASK-207), the
/// offline counterpart of [CommercialPackRepository] — same shape as
/// `PriceListLocalStoreRepository` (TASK-083).
///
/// Implementations must never persist a `CommercialPack` outside the
/// `organizationId`/`companyId` scope of the call.
abstract interface class CommercialPackLocalStoreRepository {
  /// Replaces every locally stored `CommercialPack` for [organizationId]
  /// (optionally narrowed further to [companyId], mirroring
  /// [CommercialPackRepository.listByOrganization]'s own optional
  /// narrowing) with exactly [packs] — the "carga inicial" primitive, a
  /// full idempotent replace rather than an incremental merge.
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    String? companyId,
    required List<CommercialPack> packs,
  });

  /// Inserts or updates exactly one locally stored `CommercialPack` — the
  /// incremental-update primitive the future sync engine (EPIC-14) uses to
  /// keep the local cache fresh after the initial load without replacing
  /// the whole set.
  Future<AppResult<void>> upsert({required CommercialPack pack});

  /// Every `CommercialPack` currently stored locally for [organizationId]
  /// (optionally narrowed to [companyId]), in no particular order.
  Future<AppResult<List<CommercialPack>>> getAll({
    required String organizationId,
    String? companyId,
  });

  /// Number of `CommercialPack`s currently stored locally for
  /// [organizationId] (optionally narrowed to [companyId]), without
  /// materializing every row.
  Future<AppResult<int>> count({
    required String organizationId,
    String? companyId,
  });
}

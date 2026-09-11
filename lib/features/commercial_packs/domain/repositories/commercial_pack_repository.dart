import '../../../../core/utils/utils.dart';
import '../entities/commercial_pack.dart';

/// Domain contract for the remote (source-of-truth) `CommercialPack` store
/// (TASK-207, EPIC-32), backed today by
/// [SharedPreferencesCommercialPackRepository] (durable local mock, same
/// precedent `PriceListRepository`/`CustomerRepository`/`ProductRepository`
/// already follow until the real Firestore/outbox sync exists) and modeled
/// 1:1 with the eventual
/// `organizations/{organizationId}/commercialPacks/{commercialPackId}`
/// Firestore collection via [CommercialPackDto]/[CommercialPackMapper].
abstract interface class CommercialPackRepository {
  /// Persists a brand-new [pack]. Implementations must never allow two
  /// `CommercialPack`s with the same [CommercialPack.id] to coexist.
  Future<AppResult<CommercialPack>> create({required CommercialPack pack});

  /// Persists changes to an already-existing [pack]. Implementations must
  /// reject a [pack] whose [CommercialPack.packCode] differs from the
  /// currently stored value — `packCode` is immutable once a
  /// `CommercialPack` document exists (it is what groups every version of
  /// "the same" pack together); a version change always means creating a
  /// brand-new document (`ReviseCommercialPackUseCase`), never mutating an
  /// existing one's `packCode`.
  Future<AppResult<CommercialPack>> update({required CommercialPack pack});

  /// The `CommercialPack` [id] within [organizationId], or `null` if it does
  /// not exist (or exists but belongs to a different organization/is soft
  /// deleted).
  Future<AppResult<CommercialPack?>> getById({
    required String organizationId,
    required String id,
  });

  /// Every non-soft-deleted `CommercialPack` for [organizationId] — every
  /// version, every status (draft/active/expired/archived/superseded) — in
  /// no particular order. [companyId], when given, narrows the result to
  /// packs scoped to that company plus every organization-wide pack (whose
  /// [CommercialPack.companyId] is `null`), mirroring
  /// `ProductRepository`/`AppDatabase.getProductsForCompany`'s own optional
  /// `companyId` narrowing rather than `PriceListRepository.listByCompany`'s
  /// required one, since [CommercialPack.companyId] itself is optional.
  Future<AppResult<List<CommercialPack>>> listByOrganization({
    required String organizationId,
    String? companyId,
  });
}

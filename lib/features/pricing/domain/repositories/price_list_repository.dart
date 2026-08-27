import '../../../../core/utils/utils.dart';
import '../entities/price_list.dart';

/// Domain contract for the remote (source-of-truth) Price List store
/// (EPIC-11, TASK-083), backed today by [SharedPreferencesPriceListRepository]
/// (durable local mock, same precedent `CustomerRepository`/
/// `ProductRepository` already follow until the real Firestore/outbox sync
/// exists) and modeled 1:1 with the eventual
/// `organizations/{organizationId}/priceLists/{priceListId}` Firestore
/// collection via [PriceListDto]/[PriceListMapper].
abstract interface class PriceListRepository {
  /// Persists a brand-new [priceList]. Implementations must never allow two
  /// Price Lists with the same [PriceList.id] to coexist.
  Future<AppResult<PriceList>> create({required PriceList priceList});

  /// Persists changes to an already-existing [priceList]. Implementations
  /// must reject a [priceList] whose [PriceList.currency] differs from the
  /// currently stored value — currency is immutable once a Price List
  /// exists (TASK-083 business rule); callers that need a different
  /// currency must create a new Price List instead.
  Future<AppResult<PriceList>> update({required PriceList priceList});

  /// The Price List [id] within [organizationId], or `null` if it does not
  /// exist (or exists but belongs to a different organization/is soft
  /// deleted).
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  });

  /// Every non-soft-deleted Price List for [organizationId]/[companyId], in
  /// no particular order — including drafts/expired/archived ones. Callers
  /// that need only currently-applicable tables must filter further (see
  /// `ResolveApplicablePriceListsUseCase`); this method never applies that
  /// filter itself.
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  });
}

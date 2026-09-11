import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/commercial_pack.dart';
import '../repositories/commercial_pack_repository.dart';
import '../value_objects/commercial_pack_status.dart';

/// Every `CommercialPack` currently sellable to one customer context
/// (TASK-208, EPIC-32) — the query behind "exibir pacotes elegíveis no
/// catálogo, detalhe do produto, line sheet e pedido" (`tasks.md`).
///
/// Filters `CommercialPackRepository.listByOrganization`'s full result
/// (every version/status) down to exactly what
/// `CommercialPack.isApplicableAt`/`matchesCustomerContext` already define as
/// "sellable right now" — never re-implementing that logic, only applying
/// it. [collectionId], when the seller already narrowed the catalog/order to
/// one collection, further restricts to packs with no `collectionId` of
/// their own (sellable in every collection) or exactly matching one.
@injectable
final class ListEligibleCommercialPacksUseCase {
  const ListEligibleCommercialPacksUseCase(this._repository);

  final CommercialPackRepository _repository;

  Future<AppResult<List<CommercialPack>>> call({
    required String organizationId,
    String? companyId,
    String? customerSegment,
    String? channel,
    String? collectionId,
    DateTime? now,
  }) async {
    final result = await _repository.listByOrganization(
      organizationId: organizationId,
      companyId: companyId,
    );
    final effectiveNow = now ?? DateTime.now();

    return switch (result) {
      AppSuccess<List<CommercialPack>>(value: final packs) =>
        AppSuccess<List<CommercialPack>>(
          List<CommercialPack>.unmodifiable(
            packs.where(
              (pack) =>
                  // Only the pack version actually meant to be sold today —
                  // `superseded`/`expired`/`archived`/`draft` never surface
                  // here, mirroring `PriceList`'s own precedent of only
                  // exposing `active` entries to the sales flow.
                  pack.status == CommercialPackStatus.active &&
                  pack.isApplicableAt(effectiveNow) &&
                  pack.matchesCustomerContext(
                    candidateSegment: customerSegment,
                    candidateChannel: channel,
                  ) &&
                  (collectionId == null ||
                      pack.collectionId == null ||
                      pack.collectionId == collectionId),
            ),
          ),
        ),
      AppFailure<List<CommercialPack>>(failure: final failure) =>
        AppFailure<List<CommercialPack>>(failure),
    };
  }
}

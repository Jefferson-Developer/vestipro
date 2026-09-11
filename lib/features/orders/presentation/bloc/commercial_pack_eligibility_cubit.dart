import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../commercial_packs/domain/entities/commercial_pack.dart';
import '../../../commercial_packs/domain/usecases/list_eligible_commercial_packs_use_case.dart';
import 'commercial_pack_eligibility_state.dart';

/// Loads every kit/pacote/sortimento eligible for one order draft's own
/// customer context (TASK-208, EPIC-32) — behind the pack picker screen the
/// seller opens from "Adicionar kit/pacote" on the draft.
@injectable
final class CommercialPackEligibilityCubit
    extends Cubit<CommercialPackEligibilityState> {
  CommercialPackEligibilityCubit(this._listEligibleCommercialPacks)
    : super(const CommercialPackEligibilityState());

  final ListEligibleCommercialPacksUseCase _listEligibleCommercialPacks;

  Future<void> load({
    required String organizationId,
    String? companyId,
    String? customerSegment,
    String? channel,
    String? collectionId,
  }) async {
    emit(
      state.copyWith(
        status: CommercialPackEligibilityStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _listEligibleCommercialPacks(
      organizationId: organizationId,
      companyId: companyId,
      customerSegment: customerSegment,
      channel: channel,
      collectionId: collectionId,
    );
    switch (result) {
      case AppSuccess<List<CommercialPack>>(value: final packs):
        emit(
          CommercialPackEligibilityState(
            status: CommercialPackEligibilityStatus.success,
            packs: packs,
          ),
        );
      case AppFailure<List<CommercialPack>>(failure: final failure):
        emit(
          CommercialPackEligibilityState(
            status: CommercialPackEligibilityStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}

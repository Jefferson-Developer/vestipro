import '../../../../core/errors/errors.dart';
import '../../../commercial_packs/domain/entities/commercial_pack.dart';

enum CommercialPackEligibilityStatus { initial, loading, success, failure }

/// State of `CommercialPackEligibilityCubit` (TASK-208) — every
/// `CommercialPack` currently eligible for the order draft's own customer
/// context (`ListEligibleCommercialPacksUseCase`).
final class CommercialPackEligibilityState {
  const CommercialPackEligibilityState({
    this.status = CommercialPackEligibilityStatus.initial,
    this.packs = const <CommercialPack>[],
    this.failure,
  });

  final CommercialPackEligibilityStatus status;
  final List<CommercialPack> packs;
  final Failure? failure;

  CommercialPackEligibilityState copyWith({
    CommercialPackEligibilityStatus? status,
    List<CommercialPack>? packs,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CommercialPackEligibilityState(
      status: status ?? this.status,
      packs: packs ?? this.packs,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

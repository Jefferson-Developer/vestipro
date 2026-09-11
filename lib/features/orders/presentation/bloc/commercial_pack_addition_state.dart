import '../../../../core/errors/errors.dart';

enum CommercialPackAdditionStatus { idle, submitting, success, failure }

/// State of `CommercialPackAdditionCubit` (TASK-208) — orchestrates
/// expanding a `CommercialPack` into `OrderItem`s and persisting them onto an
/// existing `Order` draft, mirroring `OrderProductAdditionState`'s own shape
/// exactly.
final class CommercialPackAdditionState {
  const CommercialPackAdditionState({
    this.status = CommercialPackAdditionStatus.idle,
    this.failure,
  });

  final CommercialPackAdditionStatus status;
  final Failure? failure;

  CommercialPackAdditionState copyWith({
    CommercialPackAdditionStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CommercialPackAdditionState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

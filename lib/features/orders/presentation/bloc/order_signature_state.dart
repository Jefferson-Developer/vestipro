import '../../../../core/errors/errors.dart';
import '../../domain/entities/order_signature.dart';

/// Flow status of [OrderSignatureCubit] itself — distinct from
/// `OrderSignatureStatus` (the domain value object, `valid`/`invalidated`
/// lifecycle of the persisted `OrderSignature` document): this one only ever
/// describes what *this screen* is doing right now.
enum OrderSignatureFlowStatus {
  idle,
  loading,
  capturing,
  syncing,
  captured,
  synced,
  failure,
}

/// State behind [OrderSignatureCubit] (EPIC-13, TASK-180) — one instance per
/// `OrderHistoryPage`/`OrderSignatureCapturePage` pair, mirroring
/// `OrderDuplicationState`'s own single-purpose shape.
final class OrderSignatureState {
  const OrderSignatureState({
    this.status = OrderSignatureFlowStatus.idle,
    this.signature,
    this.failure,
  });

  final OrderSignatureFlowStatus status;

  /// The `OrderSignature` already on this device for the order in scope —
  /// `null` means "never signed from this device", regardless of [status].
  final OrderSignature? signature;
  final Failure? failure;

  bool get hasValidSignature => signature?.isValid ?? false;

  OrderSignatureState copyWith({
    OrderSignatureFlowStatus? status,
    OrderSignature? signature,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderSignatureState(
      status: status ?? this.status,
      signature: signature ?? this.signature,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

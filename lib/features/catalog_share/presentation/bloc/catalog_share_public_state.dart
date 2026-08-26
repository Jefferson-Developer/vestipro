import '../../../../core/errors/errors.dart';
import '../../domain/entities/catalog_share_preview.dart';
import '../../domain/value_objects/catalog_share_outcome.dart';

enum CatalogSharePublicStatus {
  /// Nothing requested yet / in flight.
  loading,

  /// [CatalogSharePublicState.preview] is safe to render (its own
  /// `outcome` is [CatalogShareOutcome.valid]).
  valid,

  /// An ordinary, expected "this link cannot be used" outcome —
  /// [CatalogSharePublicState.unavailableReason] picks the exact message
  /// (TASK-081: "nunca erro técnico cru").
  unavailable,

  /// A genuine technical failure (network, server error) — distinct from
  /// [unavailable] so the UI can offer a real retry instead of a dead end.
  error,
}

final class CatalogSharePublicState {
  const CatalogSharePublicState({
    this.status = CatalogSharePublicStatus.loading,
    this.token = '',
    this.preview,
    this.unavailableReason,
    this.failure,
  });

  final CatalogSharePublicStatus status;
  final String token;
  final CatalogSharePreview? preview;
  final CatalogShareOutcome? unavailableReason;
  final Failure? failure;

  CatalogSharePublicState copyWith({
    CatalogSharePublicStatus? status,
    String? token,
    CatalogSharePreview? preview,
    CatalogShareOutcome? unavailableReason,
    Failure? failure,
  }) {
    return CatalogSharePublicState(
      status: status ?? this.status,
      token: token ?? this.token,
      preview: preview ?? this.preview,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      failure: failure ?? this.failure,
    );
  }
}

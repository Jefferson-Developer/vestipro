import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_code_resolution.dart';

enum BarcodeScanStatus {
  /// Nothing scanned yet this session.
  idle,

  /// A code was detected/typed and `ResolveProductCodeUseCase` is running.
  resolving,

  /// Resolved to exactly one variant (or a variant-less product) — see
  /// `ProductCodeResolution.singleMatchOrNull`.
  resolved,

  /// Resolved to a product with more than one active variant — the caller
  /// opens that product the same way a tapped catalog card would.
  multipleMatches,

  /// No product, variant or registered alternate code matched.
  notFound,

  /// Blank/unclassifiable code (also used for a manual entry submitted
  /// empty) — never reaches `ResolveProductCodeUseCase` at all.
  invalid,

  /// The camera reported it has no permission to use.
  permissionDenied,

  /// `ResolveProductCodeUseCase` itself failed (connectivity, unexpected
  /// error) — distinct from [notFound], which is a *successful* "no match".
  failure,
}

final class BarcodeScanState {
  const BarcodeScanState({
    this.status = BarcodeScanStatus.idle,
    this.lastCode,
    this.resolution,
    this.occurrenceCount = 0,
    this.failure,
  });

  final BarcodeScanStatus status;
  final String? lastCode;
  final ProductCodeResolution? resolution;

  /// How many times [lastCode] (exact same raw value) has been
  /// scanned/typed in this session — TASK-216 "leitura repetida ...
  /// feedback visível". Always `1` the first time a given code resolves.
  final int occurrenceCount;

  final Failure? failure;

  bool get isBusy => status == BarcodeScanStatus.resolving;

  BarcodeScanState copyWith({
    BarcodeScanStatus? status,
    String? lastCode,
    ProductCodeResolution? resolution,
    int? occurrenceCount,
    Failure? failure,
    bool clearFailure = false,
    bool clearResolution = false,
  }) {
    return BarcodeScanState(
      status: status ?? this.status,
      lastCode: lastCode ?? this.lastCode,
      resolution: clearResolution ? null : resolution ?? this.resolution,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

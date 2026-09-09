import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_recognition_result.dart';

enum ProductRecognitionStatus {
  /// Before the seller has captured/picked a photo yet.
  idle,

  /// Uploading the photo and waiting for `recognizeProductImage`.
  recognizing,

  /// A result came back — check [ProductRecognitionState.result] for
  /// whether it actually has candidates or is `belowThreshold`.
  ready,

  error,
}

/// State for [ProductRecognitionCubit] (TASK-191, EPIC-28).
final class ProductRecognitionState {
  const ProductRecognitionState({
    this.status = ProductRecognitionStatus.idle,
    this.result,
    this.failure,
    this.feedbackSubmitted = false,
  });

  final ProductRecognitionStatus status;
  final ProductRecognitionResult? result;
  final Failure? failure;

  /// Whether feedback was already sent for [result] — used to disable the
  /// "era este"/"nenhum destes" actions after one is tapped, so a seller
  /// never sends two different feedback answers for the same attempt (the
  /// server itself would reject the second one anyway).
  final bool feedbackSubmitted;

  ProductRecognitionState copyWith({
    ProductRecognitionStatus? status,
    ProductRecognitionResult? result,
    Failure? failure,
    bool? feedbackSubmitted,
    bool clearFailure = false,
    bool clearResult = false,
  }) {
    return ProductRecognitionState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      failure: clearFailure ? null : (failure ?? this.failure),
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }
}

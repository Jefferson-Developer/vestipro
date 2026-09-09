import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/usecases/recognize_product_image_use_case.dart';
import '../../domain/usecases/submit_product_recognition_feedback_use_case.dart';
import '../../domain/value_objects/product_recognition_feedback_outcome.dart';
import 'product_recognition_state.dart';

/// Drives the "Identificar produto por foto" screen (TASK-191, EPIC-28).
/// Starts at [ProductRecognitionStatus.idle] and only ever calls the backend
/// when [recognize] is invoked explicitly (a capture/pick action) — never
/// automatically, same "on-demand, never eager" contract
/// `ApproachSuggestionCubit` (TASK-187) already establishes for its own
/// LLM-backed feature.
@injectable
final class ProductRecognitionCubit extends Cubit<ProductRecognitionState> {
  ProductRecognitionCubit(this._recognizeProductImage, this._submitFeedback)
    : super(const ProductRecognitionState());

  final RecognizeProductImageUseCase _recognizeProductImage;
  final SubmitProductRecognitionFeedbackUseCase _submitFeedback;

  Future<void> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) async {
    if (state.status == ProductRecognitionStatus.recognizing) return;
    emit(
      state.copyWith(
        status: ProductRecognitionStatus.recognizing,
        clearFailure: true,
        clearResult: true,
        feedbackSubmitted: false,
      ),
    );
    final result = await _recognizeProductImage(
      organizationId: organizationId,
      companyId: companyId,
      imageBytes: imageBytes,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final recognitionResult):
        emit(
          state.copyWith(
            status: ProductRecognitionStatus.ready,
            result: recognitionResult,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ProductRecognitionStatus.error,
            failure: failure,
          ),
        );
    }
  }

  /// Sends "era este"/"não era nenhum" feedback for the current
  /// [ProductRecognitionState.result] — a no-op if there is no current
  /// result or feedback was already sent for it.
  Future<void> submitFeedback({
    required String organizationId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) async {
    final result = state.result;
    if (result == null || state.feedbackSubmitted) return;

    final feedbackResult = await _submitFeedback(
      organizationId: organizationId,
      attemptId: result.attemptId,
      outcome: outcome,
      matchedProductId: matchedProductId,
    );
    if (isClosed) return;
    // A feedback failure never blocks the seller from opening the product/
    // trying again — it only ever affects [feedbackSubmitted] on success,
    // silently skipping the toggle on failure so a retry stays possible.
    if (feedbackResult is AppSuccess<void>) {
      emit(state.copyWith(feedbackSubmitted: true));
    }
  }

  /// Returns to [ProductRecognitionStatus.idle] for a brand-new capture —
  /// used by both "tentar novamente" (error/belowThreshold) and "nenhum
  /// destes" (after feedback is sent).
  void reset() {
    if (state.status == ProductRecognitionStatus.recognizing) return;
    emit(const ProductRecognitionState());
  }
}

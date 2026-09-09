import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/product_recognition/product_recognition.dart';

class _FakeProductRecognitionRepository
    implements ProductRecognitionRepository {
  _FakeProductRecognitionRepository(this._feedbackResult);

  final AppResult<void> _feedbackResult;
  int feedbackCallCount = 0;
  ProductRecognitionFeedbackOutcome? lastOutcome;
  String? lastMatchedProductId;

  @override
  Future<AppResult<ProductRecognitionResult>> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> submitFeedback({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) async {
    feedbackCallCount += 1;
    lastOutcome = outcome;
    lastMatchedProductId = matchedProductId;
    return _feedbackResult;
  }
}

void main() {
  group('SubmitProductRecognitionFeedbackUseCase', () {
    test(
      'succeeds and logs productRecognitionFeedbackSubmitted for a matched outcome',
      () async {
        final repository = _FakeProductRecognitionRepository(
          const AppSuccess<void>(null),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitProductRecognitionFeedbackUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          attemptId: 'attempt-1',
          outcome: ProductRecognitionFeedbackOutcome.matched,
          matchedProductId: 'product-1',
        );

        expect(result, isA<AppSuccess<void>>());
        expect(repository.feedbackCallCount, 1);
        expect(repository.lastMatchedProductId, 'product-1');
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name ==
                AnalyticsEvents.productRecognitionFeedbackSubmitted,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails validation without calling the repository when matched has no matchedProductId',
      () async {
        final repository = _FakeProductRecognitionRepository(
          const AppSuccess<void>(null),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitProductRecognitionFeedbackUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          attemptId: 'attempt-1',
          outcome: ProductRecognitionFeedbackOutcome.matched,
        );

        expect(result, isA<AppFailure<void>>());
        expect(
          (result as AppFailure<void>).failure.code,
          'invalid_product_recognition_feedback_request',
        );
        expect(repository.feedbackCallCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'succeeds for a noneMatched outcome without a matchedProductId',
      () async {
        final repository = _FakeProductRecognitionRepository(
          const AppSuccess<void>(null),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitProductRecognitionFeedbackUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          attemptId: 'attempt-1',
          outcome: ProductRecognitionFeedbackOutcome.noneMatched,
        );

        expect(result, isA<AppSuccess<void>>());
        expect(
          repository.lastOutcome,
          ProductRecognitionFeedbackOutcome.noneMatched,
        );
      },
    );

    test(
      'propagates a repository failure without logging the success event',
      () async {
        final repository = _FakeProductRecognitionRepository(
          const AppFailure<void>(
            ConflictFailure('Feedback já registrado anteriormente.'),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitProductRecognitionFeedbackUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          attemptId: 'attempt-1',
          outcome: ProductRecognitionFeedbackOutcome.noneMatched,
        );

        expect(result, isA<AppFailure<void>>());
        expect(analytics.loggedEvents, isEmpty);
      },
    );
  });
}

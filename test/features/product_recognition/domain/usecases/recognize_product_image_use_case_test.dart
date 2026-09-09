import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/product_recognition/product_recognition.dart';

class _FakeProductRecognitionRepository
    implements ProductRecognitionRepository {
  _FakeProductRecognitionRepository(this._recognizeResult);

  final AppResult<ProductRecognitionResult> _recognizeResult;
  int recognizeCallCount = 0;

  @override
  Future<AppResult<ProductRecognitionResult>> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) async {
    recognizeCallCount += 1;
    return _recognizeResult;
  }

  @override
  Future<AppResult<void>> submitFeedback({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) async => const AppSuccess<void>(null);
}

ProductRecognitionResult _buildResult({bool belowThreshold = false}) {
  return ProductRecognitionResult(
    attemptId: 'attempt-1',
    candidates: belowThreshold
        ? const <ProductRecognitionCandidate>[]
        : const <ProductRecognitionCandidate>[
            ProductRecognitionCandidate(
              productId: 'product-1',
              productName: 'Camiseta Básica',
              thumbnailUrl: null,
              score: 0.92,
            ),
          ],
    belowThreshold: belowThreshold,
    generatedAt: DateTime.utc(2026, 9, 8, 10),
  );
}

void main() {
  group('RecognizeProductImageUseCase', () {
    test(
      'succeeds and logs productRecognitionCompleted for a valid request',
      () async {
        final repository = _FakeProductRecognitionRepository(
          AppSuccess<ProductRecognitionResult>(_buildResult()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = RecognizeProductImageUseCase(repository, analytics);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

        expect(result, isA<AppSuccess<ProductRecognitionResult>>());
        expect(repository.recognizeCallCount, 1);
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.productRecognitionCompleted,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails validation without calling the repository for empty imageBytes',
      () async {
        final repository = _FakeProductRecognitionRepository(
          AppSuccess<ProductRecognitionResult>(_buildResult()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = RecognizeProductImageUseCase(repository, analytics);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          imageBytes: Uint8List(0),
        );

        expect(result, isA<AppFailure<ProductRecognitionResult>>());
        expect(
          (result as AppFailure<ProductRecognitionResult>).failure.code,
          'invalid_product_recognition_request',
        );
        expect(repository.recognizeCallCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'succeeds with belowThreshold and still logs productRecognitionCompleted '
      '(never treated as a failure)',
      () async {
        final repository = _FakeProductRecognitionRepository(
          AppSuccess<ProductRecognitionResult>(
            _buildResult(belowThreshold: true),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = RecognizeProductImageUseCase(repository, analytics);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

        expect(result, isA<AppSuccess<ProductRecognitionResult>>());
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.productRecognitionCompleted,
          ),
          isTrue,
        );
      },
    );

    test(
      'propagates a repository failure and logs productRecognitionFailed',
      () async {
        final repository = _FakeProductRecognitionRepository(
          const AppFailure<ProductRecognitionResult>(
            UnexpectedFailure('O serviço está indisponível.'),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = RecognizeProductImageUseCase(repository, analytics);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        );

        expect(result, isA<AppFailure<ProductRecognitionResult>>());
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.productRecognitionFailed,
          ),
          isTrue,
        );
      },
    );
  });
}

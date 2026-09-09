import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/product_recognition/product_recognition.dart';

class _FakeProductRecognitionRepository
    implements ProductRecognitionRepository {
  _FakeProductRecognitionRepository({
    AppResult<ProductRecognitionResult> Function()? recognizeResult,
    AppResult<void> Function()? feedbackResult,
  }) : _recognizeResult =
           recognizeResult ??
           (() => AppSuccess<ProductRecognitionResult>(_buildResult())),
       _feedbackResult = feedbackResult ?? (() => const AppSuccess<void>(null));

  final AppResult<ProductRecognitionResult> Function() _recognizeResult;
  final AppResult<void> Function() _feedbackResult;
  int feedbackCallCount = 0;

  @override
  Future<AppResult<ProductRecognitionResult>> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  }) async => _recognizeResult();

  @override
  Future<AppResult<void>> submitFeedback({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) async {
    feedbackCallCount += 1;
    return _feedbackResult();
  }
}

ProductRecognitionResult _buildResult() {
  return ProductRecognitionResult(
    attemptId: 'attempt-1',
    candidates: const <ProductRecognitionCandidate>[
      ProductRecognitionCandidate(
        productId: 'product-1',
        productName: 'Camiseta Básica',
        thumbnailUrl: null,
        score: 0.92,
      ),
    ],
    belowThreshold: false,
    generatedAt: DateTime.utc(2026, 9, 8, 10),
  );
}

ProductRecognitionCubit _buildCubit({
  AppResult<ProductRecognitionResult> Function()? recognizeResult,
  AppResult<void> Function()? feedbackResult,
}) {
  final repository = _FakeProductRecognitionRepository(
    recognizeResult: recognizeResult,
    feedbackResult: feedbackResult,
  );
  final analytics = FakeAnalyticsService();
  return ProductRecognitionCubit(
    RecognizeProductImageUseCase(repository, analytics),
    SubmitProductRecognitionFeedbackUseCase(repository, analytics),
  );
}

void main() {
  group('ProductRecognitionCubit', () {
    test('starts idle', () {
      final cubit = _buildCubit();
      expect(cubit.state.status, ProductRecognitionStatus.idle);
      unawaited(cubit.close());
    });

    blocTest<ProductRecognitionCubit, ProductRecognitionState>(
      'emits [recognizing, ready] on a successful recognize()',
      build: _buildCubit,
      act: (cubit) => cubit.recognize(
        organizationId: 'org-1',
        companyId: 'company-1',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
      expect: () => <dynamic>[
        isA<ProductRecognitionState>().having(
          (state) => state.status,
          'status',
          ProductRecognitionStatus.recognizing,
        ),
        isA<ProductRecognitionState>()
            .having(
              (state) => state.status,
              'status',
              ProductRecognitionStatus.ready,
            )
            .having(
              (state) => state.result?.candidates.length,
              'candidates.length',
              1,
            ),
      ],
    );

    blocTest<ProductRecognitionCubit, ProductRecognitionState>(
      'emits [recognizing, error] when the repository fails',
      build: () => _buildCubit(
        recognizeResult: () => const AppFailure<ProductRecognitionResult>(
          ServerFailure('Provedor indisponível.', code: 'unavailable'),
        ),
      ),
      act: (cubit) => cubit.recognize(
        organizationId: 'org-1',
        companyId: 'company-1',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
      expect: () => <dynamic>[
        isA<ProductRecognitionState>().having(
          (state) => state.status,
          'status',
          ProductRecognitionStatus.recognizing,
        ),
        isA<ProductRecognitionState>()
            .having(
              (state) => state.status,
              'status',
              ProductRecognitionStatus.error,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'unavailable',
            ),
      ],
    );

    test('submitFeedback() marks feedbackSubmitted on success and is a no-op '
        'without a current result', () async {
      final cubit = _buildCubit();
      await cubit.submitFeedback(
        organizationId: 'org-1',
        outcome: ProductRecognitionFeedbackOutcome.noneMatched,
      );
      expect(cubit.state.feedbackSubmitted, isFalse);

      await cubit.recognize(
        organizationId: 'org-1',
        companyId: 'company-1',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );
      await cubit.submitFeedback(
        organizationId: 'org-1',
        outcome: ProductRecognitionFeedbackOutcome.matched,
        matchedProductId: 'product-1',
      );
      expect(cubit.state.feedbackSubmitted, isTrue);
      await cubit.close();
    });

    test('reset() returns to a brand-new idle state', () async {
      final cubit = _buildCubit();
      await cubit.recognize(
        organizationId: 'org-1',
        companyId: 'company-1',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );
      expect(cubit.state.status, ProductRecognitionStatus.ready);

      cubit.reset();

      expect(cubit.state.status, ProductRecognitionStatus.idle);
      expect(cubit.state.result, isNull);
      await cubit.close();
    });
  });
}

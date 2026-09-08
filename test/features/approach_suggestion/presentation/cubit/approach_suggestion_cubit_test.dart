import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/approach_suggestion/approach_suggestion.dart';

class _FakeApproachSuggestionRepository
    implements ApproachSuggestionRepository {
  _FakeApproachSuggestionRepository(this._result);

  final AppResult<ApproachSuggestion> Function() _result;

  @override
  Future<AppResult<ApproachSuggestion>> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async => _result();
}

ApproachSuggestion _buildSuggestion() {
  return ApproachSuggestion(
    suggestedText:
        'O último pedido foi de R\$ 255,00 [refs: order_1_total_amount].',
    references: const <ApproachSuggestionReference>[
      ApproachSuggestionReference(
        code: 'order_1_total_amount',
        label: 'Valor do pedido',
        value: '255.00',
        unit: 'BRL',
      ),
    ],
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: false,
  );
}

void main() {
  group('ApproachSuggestionCubit', () {
    test('starts idle', () {
      final useCase = GenerateApproachSuggestionUseCase(
        _FakeApproachSuggestionRepository(
          () => AppSuccess<ApproachSuggestion>(_buildSuggestion()),
        ),
        FakeAnalyticsService(),
      );
      final cubit = ApproachSuggestionCubit(useCase);
      expect(cubit.state.status, ApproachSuggestionStatus.idle);
      unawaited(cubit.close());
    });

    blocTest<ApproachSuggestionCubit, ApproachSuggestionState>(
      'emits [loading, ready] on a successful generate()',
      build: () => ApproachSuggestionCubit(
        GenerateApproachSuggestionUseCase(
          _FakeApproachSuggestionRepository(
            () => AppSuccess<ApproachSuggestion>(_buildSuggestion()),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
      ),
      expect: () => <dynamic>[
        isA<ApproachSuggestionState>().having(
          (state) => state.status,
          'status',
          ApproachSuggestionStatus.loading,
        ),
        isA<ApproachSuggestionState>()
            .having(
              (state) => state.status,
              'status',
              ApproachSuggestionStatus.ready,
            )
            .having(
              (state) => state.suggestion?.suggestedText,
              'suggestedText',
              isNotNull,
            ),
      ],
    );

    blocTest<ApproachSuggestionCubit, ApproachSuggestionState>(
      'emits [loading, error] when the repository fails',
      build: () => ApproachSuggestionCubit(
        GenerateApproachSuggestionUseCase(
          _FakeApproachSuggestionRepository(
            () => const AppFailure<ApproachSuggestion>(
              ServerFailure('Provedor indisponível.', code: 'unavailable'),
            ),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
      ),
      expect: () => <dynamic>[
        isA<ApproachSuggestionState>().having(
          (state) => state.status,
          'status',
          ApproachSuggestionStatus.loading,
        ),
        isA<ApproachSuggestionState>()
            .having(
              (state) => state.status,
              'status',
              ApproachSuggestionStatus.error,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'unavailable',
            ),
      ],
    );

    test('reset() returns to idle while keeping the last suggestion', () async {
      final useCase = GenerateApproachSuggestionUseCase(
        _FakeApproachSuggestionRepository(
          () => AppSuccess<ApproachSuggestion>(_buildSuggestion()),
        ),
        FakeAnalyticsService(),
      );
      final cubit = ApproachSuggestionCubit(useCase);
      await cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerId: 'customer-1',
      );
      expect(cubit.state.status, ApproachSuggestionStatus.ready);

      cubit.reset();

      expect(cubit.state.status, ApproachSuggestionStatus.idle);
      expect(cubit.state.suggestion, isNotNull);
      await cubit.close();
    });
  });
}

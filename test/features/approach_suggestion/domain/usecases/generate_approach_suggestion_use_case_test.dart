import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/approach_suggestion/approach_suggestion.dart';

class _FakeApproachSuggestionRepository
    implements ApproachSuggestionRepository {
  _FakeApproachSuggestionRepository(this._result);

  final AppResult<ApproachSuggestion> _result;
  int callCount = 0;
  String? lastCustomerId;

  @override
  Future<AppResult<ApproachSuggestion>> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    callCount += 1;
    lastCustomerId = customerId;
    return _result;
  }
}

ApproachSuggestion _buildSuggestion({bool fromCache = false}) {
  return ApproachSuggestion(
    suggestedText:
        'O último pedido foi de R\$ 255,00 [refs: order_1_total_amount].',
    references: const <ApproachSuggestionReference>[
      ApproachSuggestionReference(
        code: 'order_1_total_amount',
        label: 'Valor do pedido PED-002',
        value: '255.00',
        unit: 'BRL',
      ),
    ],
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: fromCache,
  );
}

void main() {
  group('GenerateApproachSuggestionUseCase', () {
    test(
      'succeeds and logs approachSuggestionGenerated for a valid request',
      () async {
        final repository = _FakeApproachSuggestionRepository(
          AppSuccess<ApproachSuggestion>(_buildSuggestion()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateApproachSuggestionUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<ApproachSuggestion>>());
        expect(repository.callCount, 1);
        expect(repository.lastCustomerId, 'customer-1');
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.approachSuggestionGenerated,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails validation without calling the repository for a blank customerId',
      () async {
        final repository = _FakeApproachSuggestionRepository(
          AppSuccess<ApproachSuggestion>(_buildSuggestion()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateApproachSuggestionUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerId: '   ',
        );

        expect(result, isA<AppFailure<ApproachSuggestion>>());
        expect(
          (result as AppFailure<ApproachSuggestion>).failure.code,
          'invalid_approach_suggestion_request',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'propagates a repository failure and logs approachSuggestionGenerationFailed',
      () async {
        final repository = _FakeApproachSuggestionRepository(
          const AppFailure<ApproachSuggestion>(
            ConflictFailure(
              'Não foi possível gerar uma sugestão confiável.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateApproachSuggestionUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppFailure<ApproachSuggestion>>());
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name ==
                AnalyticsEvents.approachSuggestionGenerationFailed,
          ),
          isTrue,
        );
      },
    );
  });
}

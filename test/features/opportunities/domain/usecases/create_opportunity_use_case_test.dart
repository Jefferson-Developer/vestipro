import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

void main() {
  group('CreateOpportunityUseCase', () {
    late _MockOpportunityRepository repository;
    late CreateOpportunityUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildFallbackOpportunity());
    });

    setUp(() {
      repository = _MockOpportunityRepository();
      useCase = CreateOpportunityUseCase(repository);
      when(
        () => repository.create(opportunity: any(named: 'opportunity')),
      ).thenAnswer((invocation) async {
        return AppSuccess<Opportunity>(
          invocation.namedArguments[#opportunity] as Opportunity,
        );
      });
    });

    Future<AppResult<Opportunity>> callUseCase({
      String? customerId = 'customer-1',
      String? leadId,
      double estimatedValue = 1000,
      int probability = 40,
    }) {
      return useCase.call(
        id: 'opportunity-1',
        organizationId: 'org-1',
        title: 'Reposição de inverno',
        customerId: customerId,
        leadId: leadId,
        estimatedValue: estimatedValue,
        probability: probability,
        responsibleUserId: 'user-1',
        stageId: 'stage-qualification',
        expectedCloseDate: DateTime.utc(2026, 2, 1),
        createdBy: 'user-1',
      );
    }

    test(
      'creates an open opportunity computing the revenue forecast',
      () async {
        final result = await callUseCase(estimatedValue: 2000, probability: 25);

        expect(result, isA<AppSuccess<Opportunity>>());
        final opportunity = (result as AppSuccess<Opportunity>).value;
        expect(opportunity.status, OpportunityStatus.open);
        expect(opportunity.revenueForecast, 500);
        expect(opportunity.version, 1);
        expect(opportunity.syncStatus, OpportunitySyncStatus.pending);
      },
    );

    test('allows a lead-only origin (no customerId yet)', () async {
      final result = await callUseCase(customerId: null, leadId: 'lead-1');

      expect(result, isA<AppSuccess<Opportunity>>());
      final opportunity = (result as AppSuccess<Opportunity>).value;
      expect(opportunity.customerId, isNull);
      expect(opportunity.leadId, 'lead-1');
    });

    test(
      'rejects an opportunity with both customerId and leadId null',
      () async {
        final result = await callUseCase(customerId: null, leadId: null);

        expect(result, isA<AppFailure<Opportunity>>());
        final failure = (result as AppFailure<Opportunity>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors,
          containsPair(
            'customerId',
            'Either customerId or leadId must be provided.',
          ),
        );
        verifyNever(
          () => repository.create(opportunity: any(named: 'opportunity')),
        );
      },
    );

    test('rejects a negative estimated value', () async {
      final result = await callUseCase(estimatedValue: -1);

      expect(result, isA<AppFailure<Opportunity>>());
      final failure = (result as AppFailure<Opportunity>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('estimatedValue', 'EstimatedValue cannot be negative.'),
      );
      verifyNever(
        () => repository.create(opportunity: any(named: 'opportunity')),
      );
    });

    test('rejects a probability above 100', () async {
      final result = await callUseCase(probability: 101);

      expect(result, isA<AppFailure<Opportunity>>());
      final failure = (result as AppFailure<Opportunity>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('probability', 'Probability must be between 0 and 100.'),
      );
    });

    test('rejects a negative probability', () async {
      final result = await callUseCase(probability: -1);

      expect(result, isA<AppFailure<Opportunity>>());
      final failure = (result as AppFailure<Opportunity>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('probability', 'Probability must be between 0 and 100.'),
      );
    });

    test('accepts the probability boundaries 0 and 100', () async {
      final zeroResult = await callUseCase(probability: 0);
      expect(zeroResult, isA<AppSuccess<Opportunity>>());
      expect((zeroResult as AppSuccess<Opportunity>).value.revenueForecast, 0);

      final fullResult = await callUseCase(
        probability: 100,
        estimatedValue: 3000,
      );
      expect(fullResult, isA<AppSuccess<Opportunity>>());
      expect(
        (fullResult as AppSuccess<Opportunity>).value.revenueForecast,
        3000,
      );
    });
  });
}

Opportunity _buildFallbackOpportunity() {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: 'fallback-opportunity',
    organizationId: 'org-1',
    title: 'Fallback',
    customerId: 'customer-1',
    estimatedValue: 0,
    probability: 0,
    revenueForecast: 0,
    responsibleUserId: 'user-1',
    stageId: 'stage-fallback',
    status: OpportunityStatus.open,
    expectedCloseDate: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
}

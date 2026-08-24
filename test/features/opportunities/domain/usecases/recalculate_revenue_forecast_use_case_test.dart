import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockOpportunityRepository extends Mock
    implements OpportunityRepository {}

void main() {
  group('RecalculateRevenueForecastUseCase', () {
    late _MockOpportunityRepository repository;
    late RecalculateRevenueForecastUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildOpportunity());
    });

    setUp(() {
      repository = _MockOpportunityRepository();
      useCase = RecalculateRevenueForecastUseCase(repository);
    });

    test(
      'recomputes the stored forecast after estimatedValue/probability drifted',
      () async {
        // revenueForecast was left stale at 100 even though estimatedValue
        // (2000) x probability (30%) should be 600 — simulating a direct
        // repository update that bypassed CreateOpportunityUseCase's formula.
        final opportunity = _buildOpportunity(
          estimatedValue: 2000,
          probability: 30,
          revenueForecast: 100,
        );
        when(
          () => repository.getById(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
          ),
        ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));
        when(
          () => repository.update(opportunity: any(named: 'opportunity')),
        ).thenAnswer((invocation) async {
          return AppSuccess<Opportunity>(
            invocation.namedArguments[#opportunity] as Opportunity,
          );
        });

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'opportunity-1',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Opportunity>>());
        final updated = (result as AppSuccess<Opportunity>).value;
        expect(updated.revenueForecast, 600);
        expect(updated.version, opportunity.version + 1);
      },
    );

    test('is a no-op when the stored forecast is already correct', () async {
      final opportunity = _buildOpportunity(
        estimatedValue: 1000,
        probability: 50,
        revenueForecast: 500,
      );
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Opportunity>(opportunity));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'opportunity-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Opportunity>>());
      final updated = (result as AppSuccess<Opportunity>).value;
      expect(updated.version, opportunity.version);
      verifyNever(
        () => repository.update(opportunity: any(named: 'opportunity')),
      );
    });
  });
}

Opportunity _buildOpportunity({
  double estimatedValue = 1000,
  int probability = 50,
  double revenueForecast = 500,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: 'opportunity-1',
    organizationId: 'org-1',
    title: 'Reposição de inverno',
    customerId: 'customer-1',
    estimatedValue: estimatedValue,
    probability: probability,
    revenueForecast: revenueForecast,
    responsibleUserId: 'user-1',
    stageId: 'stage-qualification',
    status: OpportunityStatus.open,
    expectedCloseDate: DateTime.utc(2026, 2, 1),
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
}

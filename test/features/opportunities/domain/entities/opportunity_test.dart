import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  group('Opportunity', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);
    final expectedCloseDate = DateTime.utc(2026, 2, 1);

    Opportunity buildOpportunity({
      String id = 'opportunity-1',
      String organizationId = 'org-1',
      OpportunityStatus status = OpportunityStatus.open,
      double estimatedValue = 1000,
      int probability = 50,
      double? revenueForecast,
    }) {
      return Opportunity(
        id: id,
        organizationId: organizationId,
        companyId: 'company-1',
        title: 'Reposição de inverno',
        customerId: 'customer-1',
        estimatedValue: estimatedValue,
        probability: probability,
        revenueForecast:
            revenueForecast ?? (estimatedValue * probability / 100),
        responsibleUserId: 'user-1',
        stageId: 'stage-qualification',
        status: status,
        expectedCloseDate: expectedCloseDate,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 1,
        syncStatus: OpportunitySyncStatus.pending,
      );
    }

    test('two opportunities with the same field values are equal', () {
      expect(buildOpportunity(), buildOpportunity());
    });

    test('opportunities with different ids are not equal', () {
      expect(
        buildOpportunity(id: 'opportunity-1'),
        isNot(buildOpportunity(id: 'opportunity-2')),
      );
    });

    test('opportunities from different organizations are not equal', () {
      expect(
        buildOpportunity(organizationId: 'org-1'),
        isNot(buildOpportunity(organizationId: 'org-2')),
      );
    });

    group('calculateRevenueForecast', () {
      test('is zero when probability is 0%', () {
        final opportunity = buildOpportunity(
          estimatedValue: 5000,
          probability: 0,
        );
        expect(opportunity.calculateRevenueForecast(), 0);
      });

      test('equals the estimated value when probability is 100%', () {
        final opportunity = buildOpportunity(
          estimatedValue: 5000,
          probability: 100,
        );
        expect(opportunity.calculateRevenueForecast(), 5000);
      });

      test('is proportional to probability in between', () {
        final opportunity = buildOpportunity(
          estimatedValue: 2000,
          probability: 25,
        );
        expect(opportunity.calculateRevenueForecast(), 500);
      });
    });

    group('canTransitionStatusTo (status FSM)', () {
      test('allows moving from open to won', () {
        final opportunity = buildOpportunity(status: OpportunityStatus.open);
        expect(
          opportunity.canTransitionStatusTo(OpportunityStatus.won),
          isTrue,
        );
      });

      test('allows moving from open to lost', () {
        final opportunity = buildOpportunity(status: OpportunityStatus.open);
        expect(
          opportunity.canTransitionStatusTo(OpportunityStatus.lost),
          isTrue,
        );
      });

      test('blocks any transition out of a won opportunity', () {
        final won = buildOpportunity(status: OpportunityStatus.won);
        expect(won.canTransitionStatusTo(OpportunityStatus.open), isFalse);
        expect(won.canTransitionStatusTo(OpportunityStatus.lost), isFalse);
      });

      test('blocks any transition out of a lost opportunity', () {
        final lost = buildOpportunity(status: OpportunityStatus.lost);
        expect(lost.canTransitionStatusTo(OpportunityStatus.open), isFalse);
        expect(lost.canTransitionStatusTo(OpportunityStatus.won), isFalse);
      });
    });

    group('canChangeStage', () {
      test('is true while the opportunity is open', () {
        expect(
          buildOpportunity(status: OpportunityStatus.open).canChangeStage,
          isTrue,
        );
      });

      test('is false once the opportunity is won', () {
        expect(
          buildOpportunity(status: OpportunityStatus.won).canChangeStage,
          isFalse,
        );
      });

      test('is false once the opportunity is lost', () {
        expect(
          buildOpportunity(status: OpportunityStatus.lost).canChangeStage,
          isFalse,
        );
      });
    });
  });
}

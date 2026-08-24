import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/leads/leads.dart';

void main() {
  group('Lead', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Lead buildLead({
      String id = 'lead-1',
      String organizationId = 'org-1',
      LeadStatus status = LeadStatus.newLead,
    }) {
      return Lead(
        id: id,
        organizationId: organizationId,
        companyId: 'company-1',
        name: 'Loja Vitrine Moda',
        source: LeadSource.referral,
        responsibleUserId: 'user-1',
        status: status,
        score: 10,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 1,
        syncStatus: LeadSyncStatus.pending,
      );
    }

    test('two leads with the same field values are equal', () {
      expect(buildLead(), buildLead());
    });

    test('leads with different ids are not equal', () {
      expect(buildLead(id: 'lead-1'), isNot(buildLead(id: 'lead-2')));
    });

    test('leads from different organizations are not equal', () {
      expect(
        buildLead(organizationId: 'org-1'),
        isNot(buildLead(organizationId: 'org-2')),
      );
    });

    group('canTransitionTo (status FSM)', () {
      test('follows the standard newLead -> contacted -> qualified -> '
          'converted pipeline', () {
        final lead = buildLead();
        expect(lead.canTransitionTo(LeadStatus.contacted), isTrue);

        final contacted = buildLead(status: LeadStatus.contacted);
        expect(contacted.canTransitionTo(LeadStatus.qualified), isTrue);
        expect(contacted.canTransitionTo(LeadStatus.disqualified), isTrue);

        final qualified = buildLead(status: LeadStatus.qualified);
        expect(qualified.canTransitionTo(LeadStatus.converted), isTrue);
      });

      test('allows disqualifying a brand new lead directly', () {
        final lead = buildLead();
        expect(lead.canTransitionTo(LeadStatus.disqualified), isTrue);
      });

      test('blocks a disqualified lead from converting directly', () {
        final disqualified = buildLead(status: LeadStatus.disqualified);
        expect(disqualified.canTransitionTo(LeadStatus.converted), isFalse);
      });

      test('blocks any transition out of a disqualified lead', () {
        final disqualified = buildLead(status: LeadStatus.disqualified);
        expect(disqualified.canTransitionTo(LeadStatus.newLead), isFalse);
        expect(disqualified.canTransitionTo(LeadStatus.contacted), isFalse);
        expect(disqualified.canTransitionTo(LeadStatus.qualified), isFalse);
      });

      test('blocks any transition out of a converted lead', () {
        final converted = buildLead(status: LeadStatus.converted);
        expect(converted.canTransitionTo(LeadStatus.newLead), isFalse);
        expect(converted.canTransitionTo(LeadStatus.qualified), isFalse);
        expect(converted.canTransitionTo(LeadStatus.disqualified), isFalse);
      });

      test('blocks skipping straight from newLead to qualified', () {
        final lead = buildLead();
        expect(lead.canTransitionTo(LeadStatus.qualified), isFalse);
      });

      test('blocks skipping straight from newLead to converted', () {
        final lead = buildLead();
        expect(lead.canTransitionTo(LeadStatus.converted), isFalse);
      });

      test('blocks a qualified lead from being disqualified', () {
        final qualified = buildLead(status: LeadStatus.qualified);
        expect(qualified.canTransitionTo(LeadStatus.disqualified), isFalse);
      });
    });
  });
}

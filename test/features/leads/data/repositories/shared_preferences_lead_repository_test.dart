import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/data/mappers/lead_mapper.dart';
import 'package:vestipro/features/leads/data/repositories/shared_preferences_lead_repository.dart';
import 'package:vestipro/features/leads/leads.dart';

void main() {
  group('SharedPreferencesLeadRepository', () {
    late SharedPreferencesLeadRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesLeadRepository(LeadMapper());
    });

    test('persists a locally created lead as pending sync', () async {
      final lead = _lead(id: 'lead-1', name: 'Boutique Aurora');

      final createResult = await repository.create(lead: lead);
      final lookupResult = await repository.getById(
        organizationId: 'org-1',
        id: 'lead-1',
      );

      expect(createResult, isA<AppSuccess<Lead>>());
      expect(lookupResult, isA<AppSuccess<Lead>>());
      final loaded = (lookupResult as AppSuccess<Lead>).value;
      expect(loaded.name, 'Boutique Aurora');
      expect(loaded.syncStatus, LeadSyncStatus.pending);
    });

    test('getById fails with NotFoundFailure for an unknown lead', () async {
      final result = await repository.getById(
        organizationId: 'org-1',
        id: 'missing',
      );

      expect(result, isA<AppFailure<Lead>>());
      expect((result as AppFailure<Lead>).failure, isA<NotFoundFailure>());
    });

    test(
      'update replaces the stored lead and fails for an unknown id',
      () async {
        final lead = _lead(id: 'lead-1');
        await repository.create(lead: lead);

        final updated = lead.copyWith(status: LeadStatus.contacted, version: 2);
        final updateResult = await repository.update(lead: updated);

        expect(updateResult, isA<AppSuccess<Lead>>());
        final lookup = await repository.getById(
          organizationId: 'org-1',
          id: 'lead-1',
        );
        expect((lookup as AppSuccess<Lead>).value.status, LeadStatus.contacted);

        final missingResult = await repository.update(
          lead: _lead(id: 'missing'),
        );
        expect(missingResult, isA<AppFailure<Lead>>());
        expect(
          (missingResult as AppFailure<Lead>).failure,
          isA<NotFoundFailure>(),
        );
      },
    );

    test(
      'listPage filters by status/source/responsible and paginates',
      () async {
        await repository.create(
          lead: _lead(
            id: 'lead-1',
            name: 'Boutique Aurora',
            source: LeadSource.referral,
            status: LeadStatus.newLead,
            responsibleUserId: 'rep-1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await repository.create(
          lead: _lead(
            id: 'lead-2',
            name: 'Loja Zenit',
            source: LeadSource.event,
            status: LeadStatus.qualified,
            responsibleUserId: 'rep-2',
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await repository.create(
          lead: _lead(
            id: 'lead-3',
            name: 'Atelie Sul',
            source: LeadSource.referral,
            status: LeadStatus.qualified,
            responsibleUserId: 'rep-1',
            createdAt: DateTime.utc(2026, 1, 3),
          ),
        );

        final byStatus = await repository.listPage(
          organizationId: 'org-1',
          filters: const LeadListFilters(
            statuses: <LeadStatus>{LeadStatus.qualified},
          ),
          searchQuery: '',
          limit: 20,
        );
        final byStatusLeads =
            (byStatus as AppSuccess<LeadPageResult>).value.leads;
        expect(byStatusLeads.map((lead) => lead.id), <String>[
          'lead-3',
          'lead-2',
        ]);

        final bySource = await repository.listPage(
          organizationId: 'org-1',
          filters: LeadListFilters(
            sourceCodes: <String>{LeadSource.referral.code},
          ),
          searchQuery: '',
          limit: 20,
        );
        final bySourceLeads =
            (bySource as AppSuccess<LeadPageResult>).value.leads;
        expect(bySourceLeads.map((lead) => lead.id).toSet(), <String>{
          'lead-1',
          'lead-3',
        });

        final byResponsible = await repository.listPage(
          organizationId: 'org-1',
          filters: const LeadListFilters(responsibleUserIds: <String>{'rep-2'}),
          searchQuery: '',
          limit: 20,
        );
        final byResponsibleLeads =
            (byResponsible as AppSuccess<LeadPageResult>).value.leads;
        expect(byResponsibleLeads.single.id, 'lead-2');

        final firstPage = await repository.listPage(
          organizationId: 'org-1',
          filters: LeadListFilters.empty,
          searchQuery: '',
          limit: 2,
        );
        final firstPageResult = (firstPage as AppSuccess<LeadPageResult>).value;
        expect(firstPageResult.leads.map((lead) => lead.id), <String>[
          'lead-3',
          'lead-2',
        ]);
        expect(firstPageResult.hasMore, isTrue);

        final secondPage = await repository.listPage(
          organizationId: 'org-1',
          filters: LeadListFilters.empty,
          searchQuery: '',
          limit: 2,
          cursor: firstPageResult.nextCursor,
        );
        final secondPageResult =
            (secondPage as AppSuccess<LeadPageResult>).value;
        expect(secondPageResult.leads.map((lead) => lead.id), <String>[
          'lead-1',
        ]);
        expect(secondPageResult.hasMore, isFalse);
      },
    );

    test(
      'listPage searches by name and document, accent/case-insensitive',
      () async {
        await repository.create(
          lead: _lead(id: 'lead-1', name: 'Ateliê Aurora', document: '12345'),
        );
        await repository.create(
          lead: _lead(id: 'lead-2', name: 'Loja Zenit'),
        );

        final result = await repository.listPage(
          organizationId: 'org-1',
          filters: LeadListFilters.empty,
          searchQuery: 'atelie aurora',
          limit: 20,
        );

        final leads = (result as AppSuccess<LeadPageResult>).value.leads;
        expect(leads.single.id, 'lead-1');
      },
    );

    test('listPage never leaks leads across organizations', () async {
      await repository.create(
        lead: _lead(id: 'lead-1', organizationId: 'org-1'),
      );
      await repository.create(
        lead: _lead(id: 'lead-2', organizationId: 'org-2'),
      );

      final result = await repository.listPage(
        organizationId: 'org-1',
        filters: LeadListFilters.empty,
        searchQuery: '',
        limit: 20,
      );

      final leads = (result as AppSuccess<LeadPageResult>).value.leads;
      expect(leads.single.id, 'lead-1');
    });
  });
}

Lead _lead({
  required String id,
  String organizationId = 'org-1',
  String name = 'Lead de teste',
  String? document,
  LeadSource source = LeadSource.referral,
  LeadStatus status = LeadStatus.newLead,
  String responsibleUserId = 'rep-1',
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1);
  return Lead(
    id: id,
    organizationId: organizationId,
    name: name,
    document: document,
    source: source,
    responsibleUserId: responsibleUserId,
    status: status,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}

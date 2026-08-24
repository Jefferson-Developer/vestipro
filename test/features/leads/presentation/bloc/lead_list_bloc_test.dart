import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('LeadListBloc', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
    });

    ListOrganizationUsersUseCase buildUsersUseCase() {
      return ListOrganizationUsersUseCase(membershipRepository, teamRepository);
    }

    blocTest<LeadListBloc, LeadListState>(
      'loads the first page and the responsible roster on start',
      build: () {
        when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Membership>>([
            _membership(userId: 'rep-1', name: 'Ana Souza'),
          ]),
        );
        return LeadListBloc(
          listLeads: ListLeadsUseCase(
            _FakeLeadRepository(<AppResult<LeadPageResult>>[
              AppSuccess<LeadPageResult>(
                LeadPageResult(
                  leads: <Lead>[_leadA],
                  hasMore: true,
                  nextCursor: _leadA.id,
                  isFromLocalCache: true,
                ),
              ),
            ]),
          ),
          qualifyLead: QualifyLeadUseCase(_UnusedLeadRepository()),
          disqualifyLead: DisqualifyLeadUseCase(_UnusedLeadRepository()),
          listOrganizationUsers: buildUsersUseCase(),
        );
      },
      act: (bloc) => bloc.add(
        const LeadListStarted(organizationId: 'org-1', userId: 'rep-1'),
      ),
      expect: () => <Object>[
        isA<LeadListState>().having(
          (state) => state.status,
          'status',
          LeadListLoadStatus.loading,
        ),
        isA<LeadListState>().having(
          (state) => state.responsibleUsers.map((user) => user.userId),
          'responsibleUsers',
          <String>['rep-1'],
        ),
        isA<LeadListState>()
            .having((state) => state.status, 'status', LeadListLoadStatus.ready)
            .having((state) => state.leads, 'leads', <Lead>[_leadA])
            .having((state) => state.hasMore, 'hasMore', isTrue)
            .having(
              (state) => state.isFromLocalCache,
              'isFromLocalCache',
              isTrue,
            ),
      ],
    );

    blocTest<LeadListBloc, LeadListState>(
      'paginates without losing already loaded leads',
      build: () {
        when(
          () => membershipRepository.listByOrganization('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));
        return LeadListBloc(
          listLeads: ListLeadsUseCase(
            _FakeLeadRepository(<AppResult<LeadPageResult>>[
              AppSuccess<LeadPageResult>(
                LeadPageResult(leads: <Lead>[_leadB], hasMore: false),
              ),
            ]),
          ),
          qualifyLead: QualifyLeadUseCase(_UnusedLeadRepository()),
          disqualifyLead: DisqualifyLeadUseCase(_UnusedLeadRepository()),
          listOrganizationUsers: buildUsersUseCase(),
        );
      },
      seed: () => LeadListState(
        status: LeadListLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'rep-1',
        leads: <Lead>[_leadA],
        hasMore: true,
        nextCursor: _leadA.id,
      ),
      act: (bloc) => bloc.add(const LeadListNextPageRequested()),
      expect: () => <Object>[
        isA<LeadListState>().having(
          (state) => state.status,
          'status',
          LeadListLoadStatus.loadingMore,
        ),
        isA<LeadListState>()
            .having((state) => state.status, 'status', LeadListLoadStatus.ready)
            .having((state) => state.leads, 'leads', <Lead>[_leadA, _leadB])
            .having((state) => state.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<LeadListBloc, LeadListState>(
      'debounces search and ignores stale edits',
      build: () {
        when(
          () => membershipRepository.listByOrganization('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));
        return LeadListBloc(
          listLeads: ListLeadsUseCase(
            _FakeLeadRepository(<AppResult<LeadPageResult>>[
              AppSuccess<LeadPageResult>(
                LeadPageResult(leads: <Lead>[_leadB], hasMore: false),
              ),
            ]),
          ),
          qualifyLead: QualifyLeadUseCase(_UnusedLeadRepository()),
          disqualifyLead: DisqualifyLeadUseCase(_UnusedLeadRepository()),
          listOrganizationUsers: buildUsersUseCase(),
        );
      },
      seed: () => LeadListState(
        status: LeadListLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'rep-1',
        leads: <Lead>[_leadA],
      ),
      act: (bloc) => bloc
        ..add(const LeadListSearchChanged('al'))
        ..add(const LeadListSearchChanged('beta')),
      wait: LeadListBloc.searchDebounce * 2,
      expect: () => <Object>[
        isA<LeadListState>().having(
          (state) => state.searchQuery,
          'searchQuery',
          'al',
        ),
        isA<LeadListState>().having(
          (state) => state.searchQuery,
          'searchQuery',
          'beta',
        ),
        isA<LeadListState>().having(
          (state) => state.status,
          'status',
          LeadListLoadStatus.loading,
        ),
        isA<LeadListState>()
            .having((state) => state.status, 'status', LeadListLoadStatus.ready)
            .having((state) => state.leads, 'leads', <Lead>[_leadB]),
      ],
    );

    blocTest<LeadListBloc, LeadListState>(
      'qualifying a lead replaces it in place without a manual refresh',
      build: () {
        when(
          () => membershipRepository.listByOrganization('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));
        return LeadListBloc(
          listLeads: ListLeadsUseCase(
            _FakeLeadRepository(const <AppResult<LeadPageResult>>[]),
          ),
          qualifyLead: QualifyLeadUseCase(
            _StubLeadRepository(
              lead: _leadA.copyWith(status: LeadStatus.contacted),
            ),
          ),
          disqualifyLead: DisqualifyLeadUseCase(_UnusedLeadRepository()),
          listOrganizationUsers: buildUsersUseCase(),
        );
      },
      seed: () => LeadListState(
        status: LeadListLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'manager-1',
        leads: <Lead>[
          _leadA.copyWith(status: LeadStatus.contacted),
          _leadB,
        ],
      ),
      act: (bloc) => bloc.add(LeadListLeadQualified(_leadA.id)),
      expect: () => <Object>[
        isA<LeadListState>().having(
          (state) => state.actionStatus,
          'actionStatus',
          LeadListActionStatus.inProgress,
        ),
        isA<LeadListState>()
            .having(
              (state) => state.actionStatus,
              'actionStatus',
              LeadListActionStatus.idle,
            )
            .having(
              (state) => state.leads.first.status,
              'leads.first.status',
              LeadStatus.qualified,
            ),
      ],
    );

    blocTest<LeadListBloc, LeadListState>(
      'disqualifying without a reason surfaces a failure instead of updating '
      'the lead',
      build: () {
        when(
          () => membershipRepository.listByOrganization('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));
        return LeadListBloc(
          listLeads: ListLeadsUseCase(
            _FakeLeadRepository(const <AppResult<LeadPageResult>>[]),
          ),
          qualifyLead: QualifyLeadUseCase(_UnusedLeadRepository()),
          disqualifyLead: DisqualifyLeadUseCase(
            _StubLeadRepository(lead: _leadA),
          ),
          listOrganizationUsers: buildUsersUseCase(),
        );
      },
      seed: () => LeadListState(
        status: LeadListLoadStatus.ready,
        organizationId: 'org-1',
        userId: 'manager-1',
        leads: <Lead>[_leadA],
      ),
      act: (bloc) => bloc.add(
        const LeadListLeadDisqualified(leadId: 'lead-a', reason: ''),
      ),
      expect: () => <Object>[
        isA<LeadListState>().having(
          (state) => state.actionStatus,
          'actionStatus',
          LeadListActionStatus.inProgress,
        ),
        isA<LeadListState>()
            .having(
              (state) => state.actionStatus,
              'actionStatus',
              LeadListActionStatus.failure,
            )
            .having(
              (state) => state.actionFailure?.code,
              'actionFailure.code',
              'invalid_lead_disqualify_payload',
            )
            .having(
              (state) => state.leads.single.status,
              'leads.single.status',
              LeadStatus.newLead,
            ),
      ],
    );
  });
}

final _leadA = _lead(
  id: 'lead-a',
  name: 'Boutique Aurora',
  responsibleUserId: 'rep-1',
);
final _leadB = _lead(
  id: 'lead-b',
  name: 'Loja Zenit',
  responsibleUserId: 'rep-2',
);

Lead _lead({
  required String id,
  required String name,
  required String responsibleUserId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Lead(
    id: id,
    organizationId: 'org-1',
    name: name,
    source: LeadSource.referral,
    responsibleUserId: responsibleUserId,
    status: LeadStatus.newLead,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}

Membership _membership({required String userId, required String name}) {
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: SystemRoleName.salesRep.code,
    roleName: SystemRoleName.salesRep.code,
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'owner-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'owner-1',
    name: name,
    email: '$userId@vestipro.test',
  );
}

final class _FakeLeadRepository implements LeadRepository {
  _FakeLeadRepository(this._responses);

  final List<AppResult<LeadPageResult>> _responses;
  var _callIndex = 0;

  @override
  Future<AppResult<Lead>> create({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  }) async {
    final response = _responses[_callIndex];
    _callIndex = (_callIndex + 1).clamp(0, _responses.length - 1);
    return response;
  }
}

/// A [LeadRepository] whose `getById`/`update` are stubbed to always resolve
/// [lead], letting the qualify/disqualify use cases run for real against a
/// known starting point without a full fake persistence layer.
final class _StubLeadRepository implements LeadRepository {
  _StubLeadRepository({required this.lead});

  final Lead lead;

  @override
  Future<AppResult<Lead>> create({required Lead lead}) async {
    return AppSuccess<Lead>(lead);
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) async {
    return AppSuccess<Lead>(lead);
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<Lead>(lead);
  }

  @override
  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  }) {
    throw UnimplementedError();
  }
}

final class _UnusedLeadRepository implements LeadRepository {
  @override
  Future<AppResult<Lead>> create({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  }) {
    throw UnimplementedError();
  }
}

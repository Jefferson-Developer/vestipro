import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('LeadListPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _InMemoryLeadRepository leadRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      leadRepository = _InMemoryLeadRepository();
      permissionService = PermissionService(membershipRepository);

      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
      when(
        () => membershipRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));
    });

    LeadListBloc buildBloc() {
      return LeadListBloc(
        listLeads: ListLeadsUseCase(leadRepository),
        qualifyLead: QualifyLeadUseCase(leadRepository),
        disqualifyLead: DisqualifyLeadUseCase(leadRepository),
        listOrganizationUsers: ListOrganizationUsersUseCase(
          membershipRepository,
          teamRepository,
        ),
      );
    }

    Widget buildPage() {
      return LeadListPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders forbidden for a role without lead.view', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_ASSISTANT');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets('renders leads with status and source badges', (tester) async {
      _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
      leadRepository.seed(_lead(id: 'lead-1', name: 'Boutique Aurora'));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Boutique Aurora'), findsOneWidget);
      expect(find.text('Novo'), findsOneWidget);
      expect(find.text('Indicacao'), findsOneWidget);
    });

    testWidgets('shows the empty state when no lead matches', (tester) async {
      _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhum lead encontrado'), findsOneWidget);
    });

    testWidgets(
      'hides qualify/disqualify actions for a role without lead.qualify',
      (tester) async {
        // FINANCE can see the pipeline (lead.view, e.g. for forecasting) but
        // must never qualify/disqualify a lead (see RolePermissionMatrix).
        _stubMembership(membershipRepository, roleName: 'FINANCE');
        leadRepository.seed(_lead(id: 'lead-1', name: 'Boutique Aurora'));

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(find.text('Boutique Aurora'), findsOneWidget);
        expect(find.text('Qualificar'), findsNothing);
        expect(find.text('Desqualificar'), findsNothing);
      },
    );

    testWidgets(
      'qualifying a lead updates its badge in place without a manual refresh',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
        leadRepository.seed(
          _lead(
            id: 'lead-1',
            name: 'Boutique Aurora',
            status: LeadStatus.contacted,
          ),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Qualificar'));
        await tester.pumpAndSettle();

        expect(find.text('Qualificado'), findsOneWidget);
        expect(leadRepository.leads.single.status, LeadStatus.qualified);
      },
    );

    testWidgets(
      'disqualifying blocks an empty reason then applies a valid one',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
        leadRepository.seed(_lead(id: 'lead-1', name: 'Boutique Aurora'));

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Desqualificar'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Desqualificar').last);
        await tester.pumpAndSettle();

        expect(
          find.text('Informe o motivo da desqualificacao.'),
          findsOneWidget,
        );
        expect(leadRepository.leads.single.status, LeadStatus.newLead);

        final reasonField = find
            .byWidgetPredicate(
              (widget) => widget is AppTextField && widget.label == 'Motivo',
            )
            .last;
        await tester.enterText(
          find.descendant(of: reasonField, matching: find.byType(EditableText)),
          'Sem fit com o portfolio',
        );
        await tester.tap(find.widgetWithText(AppButton, 'Desqualificar').last);
        await tester.pumpAndSettle();

        expect(leadRepository.leads.single.status, LeadStatus.disqualified);
        expect(
          leadRepository.leads.single.disqualificationReason,
          'Sem fit com o portfolio',
        );
      },
    );
  });
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

Lead _lead({
  required String id,
  required String name,
  LeadStatus status = LeadStatus.newLead,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Lead(
    id: id,
    organizationId: 'org-1',
    name: name,
    source: LeadSource.referral,
    responsibleUserId: 'current-user',
    status: status,
    createdAt: now,
    createdBy: 'current-user',
    updatedAt: now,
    updatedBy: 'current-user',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}

final class _InMemoryLeadRepository implements LeadRepository {
  final List<Lead> leads = <Lead>[];

  void seed(Lead lead) => leads.add(lead);

  @override
  Future<AppResult<Lead>> create({required Lead lead}) async {
    leads.add(lead);
    return AppSuccess<Lead>(lead);
  }

  @override
  Future<AppResult<Lead>> update({required Lead lead}) async {
    final index = leads.indexWhere((existing) => existing.id == lead.id);
    if (index == -1) {
      return const AppFailure<Lead>(
        NotFoundFailure('Lead not found.', code: 'lead_not_found'),
      );
    }
    leads[index] = lead;
    return AppSuccess<Lead>(lead);
  }

  @override
  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final lead in leads) {
      if (lead.id == id) return AppSuccess<Lead>(lead);
    }
    return const AppFailure<Lead>(
      NotFoundFailure('Lead not found.', code: 'lead_not_found'),
    );
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
    final visible = leads
        .where((lead) => lead.organizationId == organizationId)
        .toList(growable: false);
    return AppSuccess<LeadPageResult>(
      LeadPageResult(leads: visible, hasMore: false),
    );
  }
}

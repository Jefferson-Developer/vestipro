import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
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
  group('LeadFormPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _InMemoryLeadRepository leadRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      leadRepository = _InMemoryLeadRepository();
      permissionService = PermissionService(membershipRepository);
      analyticsService = FakeAnalyticsService();

      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
    });

    LeadFormBloc buildBloc() {
      return LeadFormBloc(
        createLead: CreateLeadUseCase(leadRepository),
        listOrganizationUsers: ListOrganizationUsersUseCase(
          membershipRepository,
          teamRepository,
        ),
        analyticsService: analyticsService,
      );
    }

    Widget buildPage({void Function(Lead lead)? onSaved}) {
      return LeadFormPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
        onSaved: onSaved,
      );
    }

    testWidgets('renders forbidden for a role without lead.create', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'FINANCE');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets('shows a required-name error and never submits', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();
      await _tapSave(tester);
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome ou empresa do lead.'), findsOneWidget);
      expect(leadRepository.leads, isEmpty);
    });

    testWidgets('submits a valid lead assigned to the current user', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_REP');
      Lead? saved;

      await pumpApp(tester, buildPage(onSaved: (lead) => saved = lead));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Boutique Aurora');
      await _tapSave(tester);
      await tester.pumpAndSettle();

      expect(find.text('Lead cadastrado.'), findsOneWidget);
      expect(saved?.name, 'Boutique Aurora');
      expect(saved?.responsibleUserId, 'current-user');
      expect(leadRepository.leads.single.name, 'Boutique Aurora');
    });

    testWidgets('hides the responsible field for a role without team.manage', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate(_isResponsibleDropdown), findsNothing);
    });

    testWidgets('shows the responsible field for SALES_MANAGER', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
      when(
        () => membershipRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate(_isResponsibleDropdown), findsOneWidget);
    });
  });
}

bool _isResponsibleDropdown(Widget widget) {
  return widget is AppDropdown<String> &&
      widget.semanticLabel == 'Responsavel pelo lead';
}

Future<void> _enterName(WidgetTester tester, String value) async {
  final field = find
      .byWidgetPredicate(
        (widget) => widget is AppTextField && widget.label == 'Nome ou empresa',
      )
      .last;
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.enterText(editable.first, value);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final button = find.widgetWithText(AppButton, 'Salvar lead');
  await tester.ensureVisible(button);
  await tester.tap(button);
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

final class _InMemoryLeadRepository implements LeadRepository {
  final List<Lead> leads = <Lead>[];

  @override
  Future<AppResult<Lead>> create({required Lead lead}) async {
    leads.add(lead);
    return AppSuccess<Lead>(lead);
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

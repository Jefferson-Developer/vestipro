import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('LeadFormBloc', () {
    late _InMemoryLeadRepository leadRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      leadRepository = _InMemoryLeadRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      analyticsService = FakeAnalyticsService();

      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          _membership(userId: 'rep-2', name: 'Bruno Lima'),
        ]),
      );
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

    Future<LeadFormBloc> startedBloc({
      bool canChooseResponsible = false,
    }) async {
      final bloc = buildBloc()
        ..add(
          LeadFormStarted(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'user-1',
            canChooseResponsible: canChooseResponsible,
          ),
        );
      await _drainBloc();
      return bloc;
    }

    test(
      'submits a valid lead assigned to the current user by default',
      () async {
        final bloc = await startedBloc();

        bloc
          ..add(const LeadFormNameChanged('Boutique Aurora'))
          ..add(const LeadFormSubmitted());
        await _drainBloc();

        expect(bloc.state.submissionStatus, LeadFormSubmissionStatus.success);
        expect(bloc.state.savedLead?.responsibleUserId, 'user-1');
        expect(bloc.state.savedLead?.source, LeadSource.referral);
        expect(leadRepository.leads.single.name, 'Boutique Aurora');
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.leadCreated,
        );

        await bloc.close();
      },
    );

    test('rejects submission without a name and never touches the '
        'repository', () async {
      final bloc = await startedBloc();

      bloc.add(const LeadFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, LeadFormSubmissionStatus.failure);
      expect(
        bloc.state.fieldErrors['name'],
        'Informe o nome ou empresa do lead.',
      );
      expect(leadRepository.leads, isEmpty);

      await bloc.close();
    });

    test(
      'requires a responsible when the caller is allowed to reassign it',
      () async {
        final bloc = await startedBloc(canChooseResponsible: true);

        bloc
          ..add(const LeadFormNameChanged('Boutique Aurora'))
          ..add(const LeadFormSubmitted());
        await _drainBloc();

        expect(bloc.state.submissionStatus, LeadFormSubmissionStatus.failure);
        expect(
          bloc.state.fieldErrors['responsibleUserId'],
          'Selecione o responsavel pelo lead.',
        );
        expect(leadRepository.leads, isEmpty);

        await bloc.close();
      },
    );

    test('honors a reassigned responsible when RBAC allows it', () async {
      final bloc = await startedBloc(canChooseResponsible: true);

      bloc
        ..add(const LeadFormNameChanged('Boutique Aurora'))
        ..add(const LeadFormResponsibleSelected('rep-2'))
        ..add(const LeadFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, LeadFormSubmissionStatus.success);
      expect(leadRepository.leads.single.responsibleUserId, 'rep-2');

      await bloc.close();
    });

    test('builds a custom source from the free-text label', () async {
      final bloc = await startedBloc();

      bloc
        ..add(const LeadFormNameChanged('Boutique Aurora'))
        ..add(const LeadFormSourceSelected(LeadSource.other))
        ..add(const LeadFormCustomSourceLabelChanged('Feira ABest'))
        ..add(const LeadFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, LeadFormSubmissionStatus.success);
      expect(leadRepository.leads.single.source.label, 'Feira ABest');
      expect(leadRepository.leads.single.source.isCustom, isTrue);

      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/domain/services/representative_dashboard_visibility_service.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/wallet_summary/wallet_summary.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _FakeWalletSummaryRepository implements WalletSummaryRepository {
  _FakeWalletSummaryRepository(this._result);

  final AppResult<WalletSummary> _result;
  int callCount = 0;

  @override
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  }) async {
    callCount += 1;
    return _result;
  }
}

WalletSummary _buildSummary({bool fromCache = false}) {
  return WalletSummary(
    summaryText: 'Faturamento de R\$ 1000,00 [refs: revenue_current_month].',
    references: const <WalletSummaryReference>[
      WalletSummaryReference(
        code: 'revenue_current_month',
        label: 'Faturamento do mês',
        value: '1000.00',
        unit: 'BRL',
      ),
    ],
    periodKey: '2026-09',
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: fromCache,
  );
}

Membership _buildMembership({
  required String userId,
  required String roleName,
  List<String> teamIds = const <String>[],
}) {
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: roleName,
    roleName: roleName,
    teamIds: teamIds,
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: userId,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: userId,
  );
}

void main() {
  group('GenerateWalletSummaryUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late RepresentativeDashboardVisibilityService visibilityService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      visibilityService = RepresentativeDashboardVisibilityService(
        membershipRepository,
        teamRepository,
      );
    });

    test(
      'a seller requesting their own wallet succeeds and logs walletSummaryGenerated',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'seller-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            _buildMembership(userId: 'seller-1', roleName: 'SALES_REP'),
          ),
        );
        final repository = _FakeWalletSummaryRepository(
          AppSuccess<WalletSummary>(_buildSummary()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'seller-1',
          sellerId: 'seller-1',
        );

        expect(result, isA<AppSuccess<WalletSummary>>());
        expect(repository.callCount, 1);
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.walletSummaryGenerated,
          ),
          isTrue,
        );
      },
    );

    test(
      'denies a SALES_REP requesting a wallet other than their own, never calling the repository',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'other-rep',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            _buildMembership(userId: 'other-rep', roleName: 'SALES_REP'),
          ),
        );
        final repository = _FakeWalletSummaryRepository(
          AppSuccess<WalletSummary>(_buildSummary()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'other-rep',
          sellerId: 'seller-1',
        );

        expect(result, isA<AppFailure<WalletSummary>>());
        expect(
          (result as AppFailure<WalletSummary>).failure.code,
          'wallet_summary_view_denied',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test('allows a SALES_MANAGER who shares a team with the seller', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          _buildMembership(
            userId: 'manager-1',
            roleName: 'SALES_MANAGER',
            teamIds: const <String>['team-a'],
          ),
        ),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'seller-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          _buildMembership(
            userId: 'seller-1',
            roleName: 'SALES_REP',
            teamIds: const <String>['team-a'],
          ),
        ),
      );
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>(<Team>[]));
      final repository = _FakeWalletSummaryRepository(
        AppSuccess<WalletSummary>(_buildSummary()),
      );
      final analytics = FakeAnalyticsService();
      final useCase = GenerateWalletSummaryUseCase(
        repository,
        visibilityService,
        analytics,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        requesterUserId: 'manager-1',
        sellerId: 'seller-1',
      );

      expect(result, isA<AppSuccess<WalletSummary>>());
      expect(repository.callCount, 1);
    });

    test(
      'fails validation without calling the repository or membership lookup for a blank sellerId',
      () async {
        final repository = _FakeWalletSummaryRepository(
          AppSuccess<WalletSummary>(_buildSummary()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'seller-1',
          sellerId: '   ',
        );

        expect(result, isA<AppFailure<WalletSummary>>());
        expect(
          (result as AppFailure<WalletSummary>).failure.code,
          'invalid_wallet_summary_request',
        );
        expect(repository.callCount, 0);
        verifyNever(
          () => membershipRepository.getByUser(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );

    test(
      'propagates a repository failure and logs walletSummaryGenerationFailed',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'seller-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            _buildMembership(userId: 'seller-1', roleName: 'SALES_REP'),
          ),
        );
        final repository = _FakeWalletSummaryRepository(
          const AppFailure<WalletSummary>(
            ConflictFailure(
              'Não foi possível gerar um resumo confiável.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'seller-1',
          sellerId: 'seller-1',
        );

        expect(result, isA<AppFailure<WalletSummary>>());
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.walletSummaryGenerationFailed,
          ),
          isTrue,
        );
      },
    );
  });
}

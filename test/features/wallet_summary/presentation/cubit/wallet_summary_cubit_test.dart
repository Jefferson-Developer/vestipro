import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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

  final AppResult<WalletSummary> Function() _result;

  @override
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  }) async => _result();
}

WalletSummary _buildSummary() {
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
    fromCache: false,
  );
}

Membership _buildMembership(String userId) {
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: 'SALES_REP',
    roleName: 'SALES_REP',
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: userId,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: userId,
  );
}

void main() {
  group('WalletSummaryCubit', () {
    late _MockMembershipRepository membershipRepository;
    late RepresentativeDashboardVisibilityService visibilityService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      visibilityService = RepresentativeDashboardVisibilityService(
        membershipRepository,
        _MockTeamRepository(),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'seller-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(_buildMembership('seller-1')),
      );
    });

    test('starts idle', () {
      final useCase = GenerateWalletSummaryUseCase(
        _FakeWalletSummaryRepository(
          () => AppSuccess<WalletSummary>(_buildSummary()),
        ),
        visibilityService,
        FakeAnalyticsService(),
      );
      final cubit = WalletSummaryCubit(useCase);
      expect(cubit.state.status, WalletSummaryStatus.idle);
      unawaited(cubit.close());
    });

    blocTest<WalletSummaryCubit, WalletSummaryState>(
      'emits [loading, ready] on a successful generate()',
      build: () => WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          _FakeWalletSummaryRepository(
            () => AppSuccess<WalletSummary>(_buildSummary()),
          ),
          visibilityService,
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        requesterUserId: 'seller-1',
        sellerId: 'seller-1',
      ),
      expect: () => <dynamic>[
        isA<WalletSummaryState>().having(
          (state) => state.status,
          'status',
          WalletSummaryStatus.loading,
        ),
        isA<WalletSummaryState>()
            .having(
              (state) => state.status,
              'status',
              WalletSummaryStatus.ready,
            )
            .having(
              (state) => state.summary?.summaryText,
              'summaryText',
              isNotNull,
            ),
      ],
    );

    blocTest<WalletSummaryCubit, WalletSummaryState>(
      'emits [loading, error] when the repository fails',
      build: () => WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          _FakeWalletSummaryRepository(
            () => const AppFailure<WalletSummary>(
              ServerFailure('Provedor indisponível.', code: 'unavailable'),
            ),
          ),
          visibilityService,
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        requesterUserId: 'seller-1',
        sellerId: 'seller-1',
      ),
      expect: () => <dynamic>[
        isA<WalletSummaryState>().having(
          (state) => state.status,
          'status',
          WalletSummaryStatus.loading,
        ),
        isA<WalletSummaryState>()
            .having(
              (state) => state.status,
              'status',
              WalletSummaryStatus.error,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'unavailable',
            ),
      ],
    );

    test('reset() returns to idle while keeping the last summary', () async {
      final useCase = GenerateWalletSummaryUseCase(
        _FakeWalletSummaryRepository(
          () => AppSuccess<WalletSummary>(_buildSummary()),
        ),
        visibilityService,
        FakeAnalyticsService(),
      );
      final cubit = WalletSummaryCubit(useCase);
      await cubit.generate(
        organizationId: 'org-1',
        companyId: 'company-1',
        requesterUserId: 'seller-1',
        sellerId: 'seller-1',
      );
      expect(cubit.state.status, WalletSummaryStatus.ready);

      cubit.reset();

      expect(cubit.state.status, WalletSummaryStatus.idle);
      expect(cubit.state.summary, isNotNull);
      await cubit.close();
    });
  });
}

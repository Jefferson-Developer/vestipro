import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/domain/services/representative_dashboard_visibility_service.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/wallet_summary/wallet_summary.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _ControllableWalletSummaryRepository implements WalletSummaryRepository {
  final _completer = Completer<AppResult<WalletSummary>>();

  @override
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  }) => _completer.future;

  void complete(AppResult<WalletSummary> result) => _completer.complete(result);
}

WalletSummary _buildSummary() {
  return WalletSummary(
    summaryText:
        'Faturamento de R\$ 1000,00 no mês [refs: revenue_current_month].',
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

void main() {
  late _MockMembershipRepository membershipRepository;
  late RepresentativeDashboardVisibilityService visibilityService;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

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
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'seller-1',
          organizationId: 'org-1',
          userId: 'seller-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'seller-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'seller-1',
        ),
      ),
    );
  });

  group('WalletSummaryCard', () {
    testWidgets('idle state shows the call-to-action button', (tester) async {
      final repository = _ControllableWalletSummaryRepository();
      final cubit = WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          FakeAnalyticsService(),
        ),
      );

      await tester.pumpWidget(_wrap(cubit: cubit));

      expect(find.text('Gerar resumo'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
      await cubit.close();
    });

    testWidgets('loading state shows skeleton placeholders, no button', (
      tester,
    ) async {
      final repository = _ControllableWalletSummaryRepository();
      final cubit = WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          FakeAnalyticsService(),
        ),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(
        cubit.generate(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'seller-1',
          sellerId: 'seller-1',
        ),
      );
      await tester.pump();

      expect(find.text('Gerar resumo'), findsNothing);
      expect(find.byType(AppSkeleton), findsWidgets);

      repository.complete(AppSuccess<WalletSummary>(_buildSummary()));
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('error state shows the message and a retry button', (
      tester,
    ) async {
      final repository = _ControllableWalletSummaryRepository();
      final cubit = WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          repository,
          visibilityService,
          FakeAnalyticsService(),
        ),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(
        cubit.generate(
          organizationId: 'org-1',
          companyId: 'company-1',
          requesterUserId: 'seller-1',
          sellerId: 'seller-1',
        ),
      );
      repository.complete(
        const AppFailure<WalletSummary>(
          ServerFailure('Provedor indisponível.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provedor indisponível.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      await cubit.close();
    });

    testWidgets(
      'ready state shows the summary text without raw [refs: ...] markers and expandable references',
      (tester) async {
        final repository = _ControllableWalletSummaryRepository();
        final cubit = WalletSummaryCubit(
          GenerateWalletSummaryUseCase(
            repository,
            visibilityService,
            FakeAnalyticsService(),
          ),
        );
        await tester.pumpWidget(_wrap(cubit: cubit));

        unawaited(
          cubit.generate(
            organizationId: 'org-1',
            companyId: 'company-1',
            requesterUserId: 'seller-1',
            sellerId: 'seller-1',
          ),
        );
        repository.complete(AppSuccess<WalletSummary>(_buildSummary()));
        await tester.pumpAndSettle();

        expect(find.text('Faturamento de R\$ 1000,00 no mês.'), findsOneWidget);
        expect(find.textContaining('[refs:'), findsNothing);
        expect(find.text('Ver fontes dos dados (1)'), findsOneWidget);

        await tester.tap(find.text('Ver fontes dos dados (1)'));
        await tester.pumpAndSettle();

        expect(find.text('• Faturamento do mês: 1000.00 BRL'), findsOneWidget);
        await cubit.close();
      },
    );
  });
}

Widget _wrap({required WalletSummaryCubit cubit}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<WalletSummaryCubit>.value(
      value: cubit,
      child: const Scaffold(
        // A `SingleChildScrollView` here mirrors how `RepresentativeDashboardPage`
        // actually embeds this card (its own body is scrollable) — the card's
        // content column relies on an unbounded-height ancestor the same way.
        body: SingleChildScrollView(
          child: WalletSummaryCard(
            organizationId: 'org-1',
            companyId: 'company-1',
            requesterUserId: 'seller-1',
            sellerId: 'seller-1',
          ),
        ),
      ),
    ),
  );
}

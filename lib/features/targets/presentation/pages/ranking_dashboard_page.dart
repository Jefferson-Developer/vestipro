import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/ranking_board.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/value_objects/ranking_access_level.dart';
import '../../domain/value_objects/ranking_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../cubit/ranking_dashboard_cubit.dart';
import '../cubit/ranking_dashboard_state.dart';

final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

/// Ranking comercial (TASK-118, EPIC-15/VESTI-088): compara vendedores/
/// equipes por atingimento de meta no mesmo período, destacando a posição do
/// usuário logado e nunca expondo dados de outro vendedor a quem a
/// organização não autorizou (`RankingAccessLevel`, aplicada em
/// `RankingCalculationService` — camada de aplicação, não a UI).
///
/// Gated behind [Capability.targetView] — same two-layer shape
/// `TargetDashboardPage`/`PositivacaoDashboardPage` (TASK-116/117) use: this
/// only decides whether the page is reachable at all; who the caller's
/// *peers* are is `RankingPeerResolverService`'s job
/// (`RankingDashboardCubit`), never re-implemented here.
class RankingDashboardPage extends StatelessWidget {
  const RankingDashboardPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final RankingDashboardCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.targetView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<RankingDashboardCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            );
            return cubit;
          },
          child: const _RankingDashboardView(),
        );
      },
    );
  }
}

class _RankingDashboardView extends StatelessWidget {
  const _RankingDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RankingDashboardCubit, RankingDashboardState>(
      builder: (context, state) {
        final cubit = context.read<RankingDashboardCubit>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Ranking comercial',
            filtersBuilder: (context) =>
                _RankingDashboardFilters(state: state, cubit: cubit),
            content: _RankingDashboardContent(state: state, cubit: cubit),
          ),
        );
      },
    );
  }
}

class _RankingDashboardFilters extends StatelessWidget {
  const _RankingDashboardFilters({required this.state, required this.cubit});

  final RankingDashboardState state;
  final RankingDashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDropdown<TargetMetricType>(
          options: const <AppDropdownOption<TargetMetricType>>[
            AppDropdownOption(
              value: TargetMetricType.revenue,
              label: 'Faturamento',
            ),
            AppDropdownOption(
              value: TargetMetricType.quantity,
              label: 'Quantidade',
            ),
            AppDropdownOption(
              value: TargetMetricType.positivacao,
              label: 'Positivação',
            ),
          ],
          selectedValues: <TargetMetricType>{state.metricType},
          onChanged: (values) => cubit.selectDimension(
            dimensionType: state.dimensionType,
            metricType: values.first,
          ),
          closeSemanticLabel: 'Fechar seleção de métrica',
          label: 'Métrica',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        if (state.canPickDimension) ...<Widget>[
          AppDropdown<RankingDimensionType>(
            options: const <AppDropdownOption<RankingDimensionType>>[
              AppDropdownOption(
                value: RankingDimensionType.salesRep,
                label: 'Vendedor',
              ),
              AppDropdownOption(
                value: RankingDimensionType.team,
                label: 'Equipe',
              ),
            ],
            selectedValues: <RankingDimensionType>{state.dimensionType},
            onChanged: (values) => cubit.selectDimension(
              dimensionType: values.first,
              metricType: state.metricType,
            ),
            closeSemanticLabel: 'Fechar seleção de dimensão',
            label: 'Dimensão',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.periodCandidates.isNotEmpty) ...<Widget>[
          Text('Período', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.spacing8),
          for (final window in state.periodCandidates)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: AppButton(
                label:
                    '${_dateFormat.format(window.start)} - '
                    '${_dateFormat.format(window.end)}',
                variant: state.selectedPeriod == window
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: state.isBusy
                    ? null
                    : () => cubit.selectPeriod(window),
              ),
            ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.board != null &&
            state.board!.accessLevel == RankingAccessLevel.full) ...<Widget>[
          Text('Ordenar por', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.spacing8),
          AppDropdown<RankingSortCriterion>(
            options: const <AppDropdownOption<RankingSortCriterion>>[
              AppDropdownOption(
                value: RankingSortCriterion.achievementPercentage,
                label: 'Atingimento %',
              ),
              AppDropdownOption(
                value: RankingSortCriterion.absoluteValue,
                label: 'Valor absoluto',
              ),
            ],
            selectedValues: <RankingSortCriterion>{state.sortCriterion},
            onChanged: (values) => cubit.sortBy(values.first),
            closeSemanticLabel: 'Fechar seleção de ordenação',
            label: 'Ordenação',
          ),
        ],
      ],
    );
  }
}

class _RankingDashboardContent extends StatelessWidget {
  const _RankingDashboardContent({required this.state, required this.cubit});

  final RankingDashboardState state;
  final RankingDashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case RankingDashboardStatus.initial:
      case RankingDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case RankingDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso a este ranking',
          description:
              'Você não tem permissão para ver o ranking desta dimensão. '
              'Fale com seu gestor caso acredite que isso é um engano.',
        );
      case RankingDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o ranking',
          message: state.failureMessage ?? 'Tente novamente em breve.',
        );
      case RankingDashboardStatus.empty:
        return const AppEmptyState(
          icon: Icons.leaderboard_outlined,
          title: 'Nenhuma meta cadastrada para este período',
          description:
              'Cadastre metas para esta dimensão e métrica para acompanhar '
              'o ranking aqui.',
        );
      case RankingDashboardStatus.notCalculated:
        return const AppEmptyState(
          icon: Icons.hourglass_empty_outlined,
          title: 'Cálculo do ranking ainda não disponível',
          description:
              'Ainda não há atingimento calculado para nenhum participante '
              'neste período — volte após a próxima sincronização.',
        );
      case RankingDashboardStatus.ready:
        return _RankingDashboardBody(state: state);
    }
  }
}

class _RankingDashboardBody extends StatelessWidget {
  const _RankingDashboardBody({required this.state});

  final RankingDashboardState state;

  @override
  Widget build(BuildContext context) {
    final board = state.board;
    if (board == null) {
      return const AppEmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'Selecione um período',
        description: 'Escolha um período nos filtros para ver o ranking.',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PositionHighlightCard(board: board),
          const SizedBox(height: AppSpacing.spacing24),
          if (board.accessLevel == RankingAccessLevel.full) ...<Widget>[
            Text('Ranking completo', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.spacing8),
            AppDataTable<RankingEntry>(
              status: AppDataTableStatus.idle,
              rows: state.sortedEntriesForDisplay,
              rowIdBuilder: (entry) => entry.dimensionId,
              selectedIds: <Object>{
                for (final entry in state.sortedEntriesForDisplay)
                  if (entry.isCurrentUser) entry.dimensionId,
              },
              mobileCardTitleBuilder: (context, entry) =>
                  _EntryTitle(entry: entry),
              columns: <AppDataColumn<RankingEntry>>[
                AppDataColumn(
                  label: 'Posição',
                  cellBuilder: (context, entry) => Text('${entry.rank}º'),
                ),
                AppDataColumn(
                  label: 'Nome',
                  cellBuilder: (context, entry) => _EntryTitle(entry: entry),
                ),
                AppDataColumn(
                  label: 'Atingimento',
                  numeric: true,
                  cellBuilder: (context, entry) => Text(
                    '${entry.achievementPercentage.toStringAsFixed(1)}%',
                  ),
                ),
                AppDataColumn(
                  label: 'Realizado',
                  numeric: true,
                  cellBuilder: (context, entry) =>
                      Text(_currencyFormat.format(entry.realizedValue)),
                ),
              ],
            ),
          ] else
            const AppEmptyState(
              icon: Icons.visibility_off_outlined,
              title: 'Ranking nominal restrito',
              description:
                  'Sua organização configurou este ranking para mostrar '
                  'apenas sua posição relativa — nomes e valores de outros '
                  'vendedores não são exibidos.',
            ),
        ],
      ),
    );
  }
}

class _EntryTitle extends StatelessWidget {
  const _EntryTitle({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(entry.displayName, overflow: TextOverflow.ellipsis),
        ),
        if (entry.isCurrentUser) ...<Widget>[
          const SizedBox(width: AppSpacing.spacing8),
          const AppStatusBadge(
            label: 'Você',
            variant: AppStatusBadgeVariant.info,
          ),
        ],
      ],
    );
  }
}

class _PositionHighlightCard extends StatelessWidget {
  const _PositionHighlightCard({required this.board});

  final RankingBoard board;

  @override
  Widget build(BuildContext context) {
    final rank = board.currentUserRank;
    final total = board.totalParticipants;

    return AppKpiCard(
      label: 'Sua posição',
      value: rank == null
          ? 'Sem atingimento calculado ainda'
          : '$rankº de $total',
      icon: Icons.emoji_events_outlined,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/funnel_dashboard_filters.dart';
import '../../domain/entities/funnel_dashboard_snapshot.dart';
import '../bloc/funnel_dashboard_bloc.dart';
import '../bloc/funnel_dashboard_event.dart';
import '../bloc/funnel_dashboard_state.dart';

class FunnelDashboardPage extends StatelessWidget {
  const FunnelDashboardPage({
    super.key,
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
    required this.createBloc,
    required this.onOpenStageOpportunities,
    this.onFiltersChanged,
  });

  final String organizationId;
  final String userId;
  final FunnelDashboardFilters initialFilters;
  final FunnelDashboardBloc Function() createBloc;
  final ValueChanged<String> onOpenStageOpportunities;
  final ValueChanged<FunnelDashboardFilters>? onFiltersChanged;

  @override
  Widget build(BuildContext context) => BlocProvider<FunnelDashboardBloc>(
    create: (_) => createBloc()
      ..add(
        FunnelDashboardStarted(
          organizationId: organizationId,
          userId: userId,
          filters: initialFilters,
        ),
      ),
    child: _FunnelDashboardView(
      onOpenStageOpportunities: onOpenStageOpportunities,
      onFiltersChanged: onFiltersChanged,
    ),
  );
}

class _FunnelDashboardView extends StatelessWidget {
  const _FunnelDashboardView({
    required this.onOpenStageOpportunities,
    required this.onFiltersChanged,
  });

  final ValueChanged<String> onOpenStageOpportunities;
  final ValueChanged<FunnelDashboardFilters>? onFiltersChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard de funil')),
    body: BlocBuilder<FunnelDashboardBloc, FunnelDashboardState>(
      builder: (context, state) => switch (state.status) {
        FunnelDashboardStatus.initial || FunnelDashboardStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        FunnelDashboardStatus.forbidden => const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Funil sem acesso',
          description: 'Escolha apenas seu funil ou uma equipe sob sua gestão.',
        ),
        FunnelDashboardStatus.failure => AppErrorState(
          title: 'Não foi possível carregar o funil',
          message: state.failure?.message ?? 'Tente novamente.',
          retryLabel: 'Tentar novamente',
          onRetry: () => context.read<FunnelDashboardBloc>().add(
            const FunnelDashboardRetried(),
          ),
        ),
        FunnelDashboardStatus.ready => _Content(
          snapshot: state.snapshot!,
          filters: state.filters!,
          onOpenStageOpportunities: onOpenStageOpportunities,
          onFiltersChanged: (filters) {
            onFiltersChanged?.call(filters);
            context.read<FunnelDashboardBloc>().add(
              FunnelDashboardFiltersChanged(filters),
            );
          },
        ),
      },
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.snapshot,
    required this.filters,
    required this.onOpenStageOpportunities,
    required this.onFiltersChanged,
  });

  final FunnelDashboardSnapshot snapshot;
  final FunnelDashboardFilters filters;
  final ValueChanged<String> onOpenStageOpportunities;
  final ValueChanged<FunnelDashboardFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    if (snapshot.stages.isEmpty) {
      return const AppEmptyState(
        icon: Icons.filter_alt_off,
        title: 'Funil ainda não configurado',
        description:
            'Cadastre as etapas do pipeline para acompanhar conversão e aging.',
      );
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        children: <Widget>[
          Text('Saúde do pipeline', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.spacing12),
          AppResponsiveBuilder(
            builder: (context, breakpoint) => GridView.count(
              key: const Key('funnel-kpi-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: breakpoint == AppBreakpoint.mobile ? 1 : 3,
              childAspectRatio: breakpoint == AppBreakpoint.mobile ? 2.5 : 1.8,
              crossAxisSpacing: AppSpacing.spacing12,
              mainAxisSpacing: AppSpacing.spacing12,
              children: <Widget>[
                AppKpiCard(
                  label: 'Pipeline ponderado',
                  value: _currency(snapshot.pipelineWeightedValue),
                ),
                AppKpiCard(
                  label: 'Oportunidades',
                  value:
                      '${snapshot.stages.fold<int>(0, (sum, row) => sum + row.opportunityCount)}',
                ),
                AppKpiCard(
                  label: 'Aging médio aberto',
                  value:
                      '${_overallAging(snapshot.stages).toStringAsFixed(1)} dias',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text('Conversão por etapa', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.spacing8),
          AppResponsiveBuilder(
            builder: (context, breakpoint) {
              final mobile = breakpoint == AppBreakpoint.mobile;
              if (mobile) {
                return Column(
                  key: const Key('funnel-mobile-stage-list'),
                  children: snapshot.stages
                      .map(
                        (stage) => _StageCard(
                          stage: stage,
                          onTap: () => onOpenStageOpportunities(stage.stageId),
                        ),
                      )
                      .toList(growable: false),
                );
              }
              return SingleChildScrollView(
                key: const Key('funnel-desktop-stacked-stages'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.stages
                      .map(
                        (stage) => SizedBox(
                          width: 220,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.spacing12,
                            ),
                            child: _StageCard(
                              stage: stage,
                              onTap: () =>
                                  onOpenStageOpportunities(stage.stageId),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Motivos de perda',
                  style: AppTypography.titleLarge,
                ),
              ),
              DropdownButton<String?>(
                value: filters.lossStageId,
                hint: const Text('Todas as etapas'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas as etapas'),
                  ),
                  ...snapshot.stages.map(
                    (stage) => DropdownMenuItem<String?>(
                      value: stage.stageId,
                      child: Text(stage.name),
                    ),
                  ),
                ],
                onChanged: (value) => onFiltersChanged(
                  filters.copyWith(
                    lossStageId: value,
                    clearLossStageId: value == null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          if (snapshot.lossReasons.isEmpty)
            const Text(
              'Nenhuma oportunidade perdida no período e escopo selecionados.',
            )
          else
            ...snapshot.lossReasons.indexed.map(
              (entry) => ListTile(
                leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
                title: Text(entry.$2.description),
                trailing: Text('${entry.$2.count}'),
              ),
            ),
        ],
      ),
    );
  }

  double _overallAging(List<FunnelStageSnapshot> rows) {
    final open = rows.where((row) => row.opportunityCount > 0).toList();
    if (open.isEmpty) return 0;
    return open.fold<double>(0, (sum, row) => sum + row.averageAgingDays) /
        open.length;
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage, required this.onTap});
  final FunnelStageSnapshot stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(stage.name, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              '${stage.opportunityCount} oportunidades • ${_currency(stage.totalValue)}',
            ),
            Text('Ponderado: ${_currency(stage.weightedValue)}'),
            Text(
              'Aging aberto: ${stage.averageAgingDays.toStringAsFixed(1)} dias',
            ),
            Text(
              stage.conversionToNext == null
                  ? 'Etapa final'
                  : 'Conversão: ${stage.conversionToNext!.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: AppSpacing.spacing8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('Ver oportunidades'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _currency(double value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);

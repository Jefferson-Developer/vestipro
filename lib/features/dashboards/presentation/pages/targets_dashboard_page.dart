import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/targets_dashboard_filters.dart';
import '../../domain/entities/targets_dashboard_snapshot.dart';
import '../bloc/targets_dashboard_bloc.dart';
import '../bloc/targets_dashboard_event.dart';
import '../bloc/targets_dashboard_state.dart';

class TargetsDashboardPage extends StatelessWidget {
  const TargetsDashboardPage({
    super.key,
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
    required this.createBloc,
    required this.onOpenOpportunities,
  });

  final String organizationId;
  final String userId;
  final TargetsDashboardFilters initialFilters;
  final TargetsDashboardBloc Function() createBloc;
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) => BlocProvider<TargetsDashboardBloc>(
    create: (_) => createBloc()
      ..add(
        TargetsDashboardStarted(
          organizationId: organizationId,
          userId: userId,
          filters: initialFilters,
        ),
      ),
    child: _TargetsDashboardView(onOpenOpportunities: onOpenOpportunities),
  );
}

class _TargetsDashboardView extends StatelessWidget {
  const _TargetsDashboardView({required this.onOpenOpportunities});
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard de metas')),
    body: BlocBuilder<TargetsDashboardBloc, TargetsDashboardState>(
      builder: (context, state) => switch (state.status) {
        TargetsDashboardStatus.initial || TargetsDashboardStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        TargetsDashboardStatus.forbidden => const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Dashboard sem acesso',
          description:
              'As metas exibidas respeitam seu perfil, equipe e organização.',
        ),
        TargetsDashboardStatus.error => AppErrorState(
          title: 'Não foi possível carregar as metas',
          message: state.failure?.message ?? 'Tente novamente.',
          retryLabel: 'Tentar novamente',
          onRetry: () => context.read<TargetsDashboardBloc>().add(
            const TargetsDashboardRetried(),
          ),
        ),
        TargetsDashboardStatus.ready => _ReadyBody(
          state: state,
          onOpenOpportunities: onOpenOpportunities,
        ),
      },
    ),
  );
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state, required this.onOpenOpportunities});
  final TargetsDashboardState state;
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Filters(state: state),
              const SizedBox(height: AppSpacing.spacing16),
              _Freshness(snapshot: snapshot),
              const SizedBox(height: AppSpacing.spacing16),
              _Kpis(metric: snapshot.root.metric),
              const SizedBox(height: AppSpacing.spacing24),
              Text(
                'Organização → equipe → vendedor',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              if (desktop)
                _DesktopHierarchy(
                  root: snapshot.root,
                  onOpenOpportunities: onOpenOpportunities,
                )
              else
                _MobileHierarchy(
                  state: state,
                  onOpenOpportunities: onOpenOpportunities,
                ),
              const SizedBox(height: AppSpacing.spacing24),
              Text('Ranking por atingimento', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.spacing8),
              if (snapshot.ranking.isEmpty)
                const Text('Nenhuma meta calculada para o período.')
              else
                ...snapshot.ranking
                    .take(10)
                    .map(
                      (entry) => ListTile(
                        leading: CircleAvatar(child: Text('${entry.rank}')),
                        title: Text(entry.displayName),
                        trailing: Text(
                          '${entry.achievementPercentage.toStringAsFixed(1)}%',
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});
  final TargetsDashboardState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TargetsDashboardBloc>();
    final filters = state.filters;
    final snapshot = state.snapshot!;
    return Wrap(
      spacing: AppSpacing.spacing12,
      runSpacing: AppSpacing.spacing8,
      children: <Widget>[
        DropdownButton<String?>(
          key: const Key('targets-team-filter'),
          value: filters.teamId,
          hint: const Text('Todas as equipes'),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas as equipes'),
            ),
            ...snapshot.availableTeamIds.map(
              (id) => DropdownMenuItem<String?>(value: id, child: Text(id)),
            ),
          ],
          onChanged: (value) => bloc.add(
            TargetsDashboardFiltersChanged(
              filters.copyWith(
                teamId: value,
                clearTeamId: value == null,
                clearSellerId: true,
              ),
            ),
          ),
        ),
        DropdownButton<String?>(
          key: const Key('targets-seller-filter'),
          value: filters.sellerId,
          hint: const Text('Todos os vendedores'),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos os vendedores'),
            ),
            ...snapshot.availableSellerIds.map(
              (id) => DropdownMenuItem<String?>(value: id, child: Text(id)),
            ),
          ],
          onChanged: (value) => bloc.add(
            TargetsDashboardFiltersChanged(
              filters.copyWith(sellerId: value, clearSellerId: value == null),
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const Key('targets-previous-period'),
          onPressed: () {
            final previous = DateTime.utc(filters.year, filters.month - 1);
            bloc.add(
              TargetsDashboardFiltersChanged(
                filters.copyWith(year: previous.year, month: previous.month),
              ),
            );
          },
          icon: const Icon(Icons.chevron_left),
          label: const Text('Período anterior'),
        ),
        Chip(label: Text(DateFormat('MM/yyyy').format(filters.periodStart))),
        OutlinedButton.icon(
          key: const Key('targets-next-period'),
          onPressed: () {
            final next = DateTime.utc(filters.year, filters.month + 1);
            bloc.add(
              TargetsDashboardFiltersChanged(
                filters.copyWith(year: next.year, month: next.month),
              ),
            );
          },
          icon: const Icon(Icons.chevron_right),
          label: const Text('Próximo período'),
        ),
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.metric});
  final TargetsDashboardMetric? metric;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final item = metric;
    if (item == null) {
      return const AppEmptyState(
        icon: Icons.flag_outlined,
        title: 'Meta não cadastrada para o período',
        description:
            'O realizado continua disponível nos níveis com meta ativa.',
      );
    }
    return Wrap(
      spacing: AppSpacing.spacing12,
      runSpacing: AppSpacing.spacing12,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: AppKpiCard(
            label: 'Realizado / meta',
            value:
                '${currency.format(item.realizedValue)} / ${currency.format(item.targetValue)}',
          ),
        ),
        SizedBox(
          width: 220,
          child: AppKpiCard(
            label: 'Atingimento',
            value: '${item.achievementPercentage.toStringAsFixed(1)}%',
          ),
        ),
        SizedBox(
          width: 220,
          child: AppKpiCard(
            label: 'Previsão de fechamento',
            value: currency.format(item.projectedValue),
            trendLabel:
                '${item.projectedAchievementPercentage.toStringAsFixed(1)}% da meta',
          ),
        ),
        SizedBox(
          width: 220,
          child: AppKpiCard(label: 'Gap', value: currency.format(item.gap)),
        ),
      ],
    );
  }
}

class _DesktopHierarchy extends StatelessWidget {
  const _DesktopHierarchy({
    required this.root,
    required this.onOpenOpportunities,
  });
  final TargetsDashboardRow root;
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('targets-desktop-hierarchy'),
    child: ExpansionTile(
      initiallyExpanded: true,
      title: _RowSummary(row: root, onOpenOpportunities: onOpenOpportunities),
      children: root.children
          .map(
            (team) => ExpansionTile(
              key: ValueKey<String>('team-${team.id}'),
              title: _RowSummary(
                row: team,
                onOpenOpportunities: onOpenOpportunities,
              ),
              children: team.children
                  .map(
                    (seller) => ListTile(
                      title: _RowSummary(
                        row: seller,
                        onOpenOpportunities: onOpenOpportunities,
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    ),
  );
}

class _MobileHierarchy extends StatelessWidget {
  const _MobileHierarchy({
    required this.state,
    required this.onOpenOpportunities,
  });
  final TargetsDashboardState state;
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TargetsDashboardBloc>();
    final row = state.drilledRow ?? state.snapshot!.root;
    return Column(
      key: const Key('targets-mobile-hierarchy'),
      children: <Widget>[
        if (state.drillPath.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => bloc.add(const TargetsDashboardDrilledUp()),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar um nível'),
            ),
          ),
        _RowSummary(row: row, onOpenOpportunities: onOpenOpportunities),
        ...row.children.map(
          (child) => Card(
            child: ListTile(
              key: ValueKey<String>('drill-${child.id}'),
              onTap: child.children.isEmpty
                  ? null
                  : () => bloc.add(TargetsDashboardDrilledDown(child.id)),
              title: _RowSummary(
                row: child,
                onOpenOpportunities: onOpenOpportunities,
              ),
              trailing: child.children.isEmpty
                  ? null
                  : const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}

class _RowSummary extends StatelessWidget {
  const _RowSummary({required this.row, required this.onOpenOpportunities});
  final TargetsDashboardRow row;
  final ValueChanged<String> onOpenOpportunities;

  @override
  Widget build(BuildContext context) {
    final metric = row.metric;
    return Row(
      children: <Widget>[
        if (row.isBelowTargetInsightActive) ...<Widget>[
          Tooltip(
            message: 'Abaixo da meta — abrir Central de Oportunidades',
            child: IconButton(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: context.colors.warning,
              ),
              onPressed: row.level == TargetsDashboardLevel.seller
                  ? () => onOpenOpportunities(row.id)
                  : null,
            ),
          ),
        ],
        Expanded(child: Text(row.label)),
        Text(
          metric == null
              ? 'Sem meta'
              : '${metric.achievementPercentage.toStringAsFixed(1)}%',
        ),
      ],
    );
  }
}

class _Freshness extends StatelessWidget {
  const _Freshness({required this.snapshot});
  final TargetsDashboardSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Text(
    snapshot.generatedAt == null
        ? 'Aguardando a primeira agregação do período.'
        : '${snapshot.isFromLocalCache ? 'Dados offline. ' : ''}Atualizado em ${DateFormat('dd/MM/yyyy HH:mm').format(snapshot.generatedAt!.toLocal())}',
    style: AppTypography.bodySmall,
  );
}

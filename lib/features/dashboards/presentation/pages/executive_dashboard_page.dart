import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../insights/domain/entities/insight.dart';
import '../../domain/entities/executive_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../../domain/entities/executive_dashboard_snapshot.dart';
import '../bloc/executive_dashboard_bloc.dart';
import '../bloc/executive_dashboard_event.dart';
import '../bloc/executive_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final DateFormat _monthLabelFormat = DateFormat('MMMM/yyyy', 'pt_BR');
final DateFormat _dayLabelFormat = DateFormat('dd/MM');

const String _noTeamOptionValue = '';

/// Executive Dashboard (TASK-134, EPIC-17): the highest-level BI screen —
/// faturamento/pedidos/ticket médio/clientes ativos/clientes novos/
/// crescimento YoY e MoM/atingimento de meta consolidado/positivação de
/// carteira, all read exclusively from `ExecutiveDashboardBloc`
/// (`AggregationRepository`/`PositivacaoRepository`/`TargetRepository`/
/// `TargetAchievementRepository` snapshots — TASK-133/TASK-116/TASK-117 —
/// never a raw query), plus a shortcut into the Central de Oportunidades
/// (TASK-132) highlighting the filtered period's highest-impact insights.
///
/// Gated behind [Capability.reportViewSensitive] — the same capability
/// `firestore.rules` already requires to read any of the five TASK-133
/// aggregation collections, so a role that cannot reach this page could not
/// have read its data anyway. *Which* companies/teams the caller may then
/// pick as scope is `ExecutiveDashboardVisibilityService`'s job
/// (`ExecutiveDashboardBloc`), never re-implemented here — same two-layer
/// shape `TargetDashboardPage`/`OpportunityCenterPage` already use for their
/// own capability + visibility-service pair.
class ExecutiveDashboardPage extends StatelessWidget {
  const ExecutiveDashboardPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialFilters,
    required this.onOpenOpportunityCenter,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ExecutiveDashboardBloc Function() createBloc;
  final ExecutiveDashboardFilters initialFilters;

  /// Called when the caller taps the "atalho para a Central de
  /// Oportunidades" shortcut — the composition root (`bootstrap.dart`)
  /// decides the actual navigation, same "this page never hard-codes
  /// another feature's route" contract `OpportunityCenterPage
  /// .onActionExecuted` already sets.
  final VoidCallback onOpenOpportunityCenter;

  /// Called whenever [ExecutiveDashboardFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `OpportunityCenterPage.onUrlStateChanged` already sets.
  final void Function(ExecutiveDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ExecutiveDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              ExecutiveDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _ExecutiveDashboardView(
            onOpenOpportunityCenter: onOpenOpportunityCenter,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _ExecutiveDashboardView extends StatelessWidget {
  const _ExecutiveDashboardView({
    required this.onOpenOpportunityCenter,
    this.onUrlStateChanged,
  });

  final VoidCallback onOpenOpportunityCenter;
  final void Function(ExecutiveDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<ExecutiveDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard executivo',
            filtersTitle: 'Filtros do dashboard executivo',
            filtersBuilder: (_) => _ExecutiveDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(ExecutiveDashboardFiltersChanged(filters)),
            ),
            content: _ExecutiveDashboardContent(
              state: state,
              onRetry: () => bloc.add(const ExecutiveDashboardRetried()),
              onOpenOpportunityCenter: onOpenOpportunityCenter,
            ),
          ),
        );
      },
    );
  }
}

class _ExecutiveDashboardFiltersForm extends StatelessWidget {
  const _ExecutiveDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final ExecutiveDashboardState state;
  final ValueChanged<ExecutiveDashboardFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    final now = DateTime.now();
    final nextMonth = DateTime.utc(filters.year, filters.month + 1);
    final nextMonthFilters = filters.copyWith(
      year: nextMonth.year,
      month: nextMonth.month,
    );
    final isNextMonthInTheFuture = nextMonthFilters.isAfter(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Período de referência', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.spacing8),
        Row(
          children: <Widget>[
            AppIconButton(
              icon: Icons.chevron_left,
              semanticLabel: 'Mês anterior',
              onPressed: () => onChanged(filters.previousMonth),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(filters),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            AppIconButton(
              icon: Icons.chevron_right,
              semanticLabel: 'Próximo mês',
              onPressed: isNextMonthInTheFuture
                  ? null
                  : () => onChanged(nextMonthFilters),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        if (state.companyOptions.length > 1) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              for (final option in state.companyOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.companyId},
            onChanged: (values) =>
                onChanged(filters.copyWith(companyId: values.first)),
            closeSemanticLabel: 'Fechar seleção de empresa',
            label: 'Empresa',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.teamOptions.isNotEmpty)
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              const AppDropdownOption(
                value: _noTeamOptionValue,
                label: 'Toda a empresa',
              ),
              for (final option in state.teamOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.teamId ?? _noTeamOptionValue},
            onChanged: (values) {
              final selected = values.first;
              onChanged(
                selected == _noTeamOptionValue
                    ? filters.copyWith(clearTeamId: true)
                    : filters.copyWith(teamId: selected),
              );
            },
            closeSemanticLabel: 'Fechar seleção de equipe',
            label: 'Equipe',
          ),
      ],
    );
  }

  String _monthLabel(ExecutiveDashboardFilters filters) {
    final label = _monthLabelFormat.format(
      DateTime.utc(filters.year, filters.month),
    );
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _ExecutiveDashboardContent extends StatelessWidget {
  const _ExecutiveDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onOpenOpportunityCenter,
  });

  final ExecutiveDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onOpenOpportunityCenter;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ExecutiveDashboardStatus.initial:
      case ExecutiveDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ExecutiveDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard executivo',
          description:
              'Você não tem permissão para ver esta visão consolidada. '
              'Fale com um administrador caso acredite que isso é um '
              'engano.',
        );
      case ExecutiveDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard executivo',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case ExecutiveDashboardStatus.ready:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ExecutiveDashboardBody(
          filters: state.filters,
          snapshot: snapshot,
          topInsights: state.topInsights,
          onOpenOpportunityCenter: onOpenOpportunityCenter,
        );
    }
  }
}

class _ExecutiveDashboardBody extends StatelessWidget {
  const _ExecutiveDashboardBody({
    required this.filters,
    required this.snapshot,
    required this.topInsights,
    required this.onOpenOpportunityCenter,
  });

  final ExecutiveDashboardFilters filters;
  final ExecutiveDashboardSnapshot snapshot;
  final List<Insight> topInsights;
  final VoidCallback onOpenOpportunityCenter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Todos os valores abaixo referem-se a '
            '${filters.monthKey} (${filters.companyId}${filters.teamId != null ? ' · equipe ${filters.teamId}' : ''}).',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: _kpiCards(),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Este gráfico responde: o faturamento diário está subindo ou '
            'caindo ao longo do mês filtrado?',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppManagementChart(
            type: AppChartType.line,
            series: <AppChartSeries>[
              AppChartSeries(
                label: 'Faturamento diário',
                points: <AppChartPoint>[
                  for (final point in snapshot.revenueTrend)
                    AppChartPoint(
                      x: point.day.day.toDouble(),
                      y: point.value,
                      label: _dayLabelFormat.format(point.day),
                    ),
                ],
              ),
            ],
            valueFormatter: (value) => _currencyFormat.format(value),
            emptyDescription:
                'Ainda não há faturamento registrado neste período.',
          ),
          const SizedBox(height: AppSpacing.spacing24),
          _OpportunityShortcutCard(
            topInsights: topInsights,
            onOpenOpportunityCenter: onOpenOpportunityCenter,
          ),
        ],
      ),
    );
  }

  List<Widget> _kpiCards() {
    return <Widget>[
      _metricCard(
        label: 'Faturamento',
        metric: snapshot.revenue,
        format: _currencyFormat.format,
        icon: Icons.payments_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Pedidos',
        metric: snapshot.orders,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.receipt_long_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Ticket médio',
        metric: snapshot.averageTicket,
        format: _currencyFormat.format,
        icon: Icons.local_offer_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Clientes ativos',
        metric: snapshot.activeCustomers,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.groups_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Clientes novos',
        metric: snapshot.newCustomers,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.person_add_alt_outlined,
        trendLabel: 'vs. mês anterior',
        notCalculatedLabel: 'Cálculo ainda não disponível',
      ),
      _metricCard(
        label: 'Positivação de carteira',
        metric: snapshot.positivacaoPercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Atingimento de meta',
        metric: snapshot.targetAchievementPercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.flag_outlined,
        notCalculatedLabel: 'Sem meta cadastrada para o período',
      ),
      _metricCard(
        label: 'Crescimento MoM',
        metric: snapshot.revenueGrowthMoM,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
        notCalculatedLabel: 'Sem dados do mês anterior',
      ),
      _metricCard(
        label: 'Crescimento YoY',
        metric: snapshot.revenueGrowthYoY,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.calendar_month_outlined,
        notCalculatedLabel: 'Sem dados do mesmo mês do ano anterior',
      ),
    ];
  }

  Widget _metricCard({
    required String label,
    required ExecutiveDashboardMetric metric,
    required String Function(double) format,
    required IconData icon,
    String? trendLabel,
    String notCalculatedLabel = 'Cálculo ainda não disponível',
  }) {
    final value = switch (metric.status) {
      ExecutiveDashboardMetricStatus.available => format(metric.value!),
      ExecutiveDashboardMetricStatus.notCalculated => notCalculatedLabel,
      ExecutiveDashboardMetricStatus.failed => 'Indisponível no momento',
    };
    final change = metric.changePercentage;
    return SizedBox(
      width: 240,
      child: AppKpiCard(
        label: label,
        value: value,
        icon: icon,
        trend: change == null
            ? AppKpiTrend.neutral
            : (change >= 0 ? AppKpiTrend.up : AppKpiTrend.down),
        trendPercentage: metric.isAvailable ? change : null,
        trendLabel: metric.isAvailable && change != null ? trendLabel : null,
        semanticLabel: metric.status == ExecutiveDashboardMetricStatus.failed
            ? '$label: não foi possível carregar (${metric.failureMessage})'
            : null,
      ),
    );
  }
}

class _OpportunityShortcutCard extends StatelessWidget {
  const _OpportunityShortcutCard({
    required this.topInsights,
    required this.onOpenOpportunityCenter,
  });

  final List<Insight> topInsights;
  final VoidCallback onOpenOpportunityCenter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Maiores oportunidades do período',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Ver oportunidades',
            semanticLabel: 'Ver Central de Oportunidades',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onOpenOpportunityCenter,
          ),
          const SizedBox(height: AppSpacing.spacing12),
          if (topInsights.isEmpty)
            Text(
              'Nenhuma oportunidade de maior impacto identificada para este '
              'período ainda.',
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            )
          else
            for (final insight in topInsights)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(insight.title, style: AppTypography.labelLarge),
                          Text(
                            insight.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _impactLabel(insight),
                      style: AppTypography.labelLarge,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _impactLabel(Insight insight) {
    final impact = insight.estimatedImpact;
    if (impact.amount != null) {
      return _currencyFormat.format(impact.amount);
    }
    if (impact.percentage != null) {
      return '${impact.percentage!.toStringAsFixed(1)}%';
    }
    return '—';
  }
}

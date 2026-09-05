import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../crm/domain/entities/crm_task.dart';
import '../../../insights/domain/entities/insight.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../../domain/entities/representative_customer_highlight.dart';
import '../../domain/entities/representative_dashboard_filters.dart';
import '../../domain/entities/representative_dashboard_snapshot.dart';
import '../bloc/representative_dashboard_bloc.dart';
import '../bloc/representative_dashboard_event.dart';
import '../bloc/representative_dashboard_state.dart';

class RepresentativeDashboardPage extends StatelessWidget {
  const RepresentativeDashboardPage({
    super.key,
    required this.organizationId,
    required this.requesterUserId,
    required this.initialFilters,
    required this.createBloc,
    required this.onOpenCrmActivity,
    required this.onOpenCustomer,
    required this.onOpenInsight,
  });

  final String organizationId;
  final String requesterUserId;
  final RepresentativeDashboardFilters initialFilters;
  final RepresentativeDashboardBloc Function() createBloc;
  final ValueChanged<CrmTask> onOpenCrmActivity;
  final ValueChanged<String> onOpenCustomer;
  final ValueChanged<Insight> onOpenInsight;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RepresentativeDashboardBloc>(
      create: (_) => createBloc()
        ..add(
          RepresentativeDashboardStarted(
            organizationId: organizationId,
            requesterUserId: requesterUserId,
            initialFilters: initialFilters,
          ),
        ),
      child: _RepresentativeDashboardView(
        onOpenCrmActivity: onOpenCrmActivity,
        onOpenCustomer: onOpenCustomer,
        onOpenInsight: onOpenInsight,
      ),
    );
  }
}

class _RepresentativeDashboardView extends StatelessWidget {
  const _RepresentativeDashboardView({
    required this.onOpenCrmActivity,
    required this.onOpenCustomer,
    required this.onOpenInsight,
  });

  final ValueChanged<CrmTask> onOpenCrmActivity;
  final ValueChanged<String> onOpenCustomer;
  final ValueChanged<Insight> onOpenInsight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu dashboard')),
      body: BlocBuilder<RepresentativeDashboardBloc, RepresentativeDashboardState>(
        builder: (context, state) {
          return switch (state.status) {
            RepresentativeDashboardStatus.initial ||
            RepresentativeDashboardStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            RepresentativeDashboardStatus.forbidden => const AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Dashboard sem acesso',
              description:
                  'Você só pode consultar seu próprio painel ou vendedores da sua equipe.',
            ),
            RepresentativeDashboardStatus.error => AppErrorState(
              title: 'Não foi possível carregar seu dashboard',
              message: state.failure?.message ?? 'Tente novamente.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<RepresentativeDashboardBloc>().add(
                const RepresentativeDashboardRetried(),
              ),
            ),
            RepresentativeDashboardStatus.ready => _DashboardBody(
              snapshot: state.snapshot!,
              onOpenCrmActivity: onOpenCrmActivity,
              onOpenCustomer: onOpenCustomer,
              onOpenInsight: onOpenInsight,
            ),
          };
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.snapshot,
    required this.onOpenCrmActivity,
    required this.onOpenCustomer,
    required this.onOpenInsight,
  });

  final RepresentativeDashboardSnapshot snapshot;
  final ValueChanged<CrmTask> onOpenCrmActivity;
  final ValueChanged<String> onOpenCustomer;
  final ValueChanged<Insight> onOpenInsight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _FreshnessBanner(snapshot: snapshot),
            const SizedBox(height: AppSpacing.spacing16),
            AppResponsiveBuilder(
              builder: (context, breakpoint) {
                final columns = const AppResponsiveValue<int>(
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                  largeDesktop: 5,
                ).resolve(breakpoint);
                return GridView.count(
                  key: const Key('representative-kpi-grid'),
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.spacing12,
                  mainAxisSpacing: AppSpacing.spacing12,
                  childAspectRatio: columns == 1 ? 2.2 : 1.55,
                  children: <Widget>[
                    _metricCard('Venda hoje', snapshot.salesToday, true),
                    _metricCard('Venda no mês', snapshot.salesMonth, true),
                    _metricCard(
                      'Atingimento da meta',
                      snapshot.targetAchievement,
                      false,
                    ),
                    _metricCard(
                      'Positivação da carteira',
                      snapshot.portfolioPositivation,
                      false,
                    ),
                    _metricCard(
                      'Ranking na equipe',
                      snapshot.teamRank,
                      false,
                      rank: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text('Ações de agora', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.spacing8),
            if (snapshot.followUps.isEmpty)
              const AppEmptyState(
                icon: Icons.task_alt,
                title: 'Tudo em dia',
                description: 'Nenhum follow-up pendente.',
              )
            else
              ...snapshot.followUps.map(
                (task) => _FollowUpTile(
                  task: task,
                  onTap: () => onOpenCrmActivity(task),
                ),
              ),
            const SizedBox(height: AppSpacing.spacing24),
            Text('Carteira em destaque', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.spacing8),
            if (snapshot.customers.isEmpty)
              const Text('Nenhum cliente disponível na carteira.')
            else
              ...snapshot.customers.map(
                (customer) => _CustomerTile(
                  customer: customer,
                  onOpenCustomer: () => onOpenCustomer(customer.customerId),
                  onOpenInsight: customer.insight == null
                      ? null
                      : () => onOpenInsight(customer.insight!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    String label,
    ExecutiveDashboardMetric metric,
    bool currency, {
    bool rank = false,
  }) {
    final value = switch (metric.status) {
      ExecutiveDashboardMetricStatus.failed => 'Indisponível',
      ExecutiveDashboardMetricStatus.notCalculated =>
        label == 'Atingimento da meta' ? 'Sem meta cadastrada' : 'A calcular',
      ExecutiveDashboardMetricStatus.available when rank =>
        '${metric.value!.toInt()}º',
      ExecutiveDashboardMetricStatus.available when currency =>
        NumberFormat.simpleCurrency(locale: 'pt_BR').format(metric.value),
      ExecutiveDashboardMetricStatus.available =>
        '${metric.value!.toStringAsFixed(1)}%',
    };
    return AppKpiCard(label: label, value: value);
  }
}

class _FreshnessBanner extends StatelessWidget {
  const _FreshnessBanner({required this.snapshot});
  final RepresentativeDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final updated = snapshot.lastUpdatedAt;
    final text = updated == null
        ? 'Aguardando a primeira atualização dos indicadores.'
        : '${snapshot.isFromLocalCache ? 'Você está offline. ' : ''}Última atualização: '
              '${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(updated.toLocal())}';
    return Semantics(
      liveRegion: snapshot.isFromLocalCache,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: snapshot.isFromLocalCache
              ? context.colors.warning.withValues(alpha: 0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              snapshot.isFromLocalCache ? Icons.cloud_off : Icons.sync,
              color: context.colors.outline,
            ),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(child: Text(text, style: AppTypography.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({required this.task, required this.onTap});
  final CrmTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue(DateTime.now());
    return Card(
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: AppSpacing.spacing12,
        leading: Icon(overdue ? Icons.warning_amber : Icons.schedule),
        title: Text(task.title),
        subtitle: Text(
          '${overdue ? 'Vencido' : 'Vence'} em '
          '${DateFormat('dd/MM HH:mm', 'pt_BR').format(task.dueAt.toLocal())}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onOpenCustomer,
    required this.onOpenInsight,
  });
  final RepresentativeCustomerHighlight customer;
  final VoidCallback onOpenCustomer;
  final VoidCallback? onOpenInsight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpenCustomer,
        title: Text(customer.customerName),
        subtitle: customer.insight == null
            ? const Text('Abrir cliente')
            : Text(customer.insight!.title),
        trailing: customer.insight == null
            ? const Icon(Icons.chevron_right)
            : IconButton(
                tooltip: 'Abrir insight',
                onPressed: onOpenInsight,
                icon: const Icon(Icons.lightbulb_outline),
              ),
      ),
    );
  }
}

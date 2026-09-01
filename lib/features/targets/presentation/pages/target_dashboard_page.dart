import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/target.dart';
import '../../domain/entities/target_progress_view_model.dart';
import '../../domain/services/closing_projection_service.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../cubit/target_dashboard_cubit.dart';
import '../cubit/target_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
final DateFormat _periodButtonDateFormat = DateFormat('MM/yy');

/// Dashboard de atingimento de metas (TASK-116, EPIC-15/VESTI-085): realizado
/// vs. meta, gap e uma projeção linear simples de fechamento, por
/// dimensão/período/métrica.
///
/// Gated behind [Capability.targetView] the same two-layer shape
/// `TargetFormPage` uses for [Capability.targetManage]: this only decides
/// whether the page is reachable at all — which dimension the caller may
/// then actually see is `TargetVisibilityFilter`'s job
/// (`TargetDashboardCubit`), never re-implemented here.
class TargetDashboardPage extends StatelessWidget {
  const TargetDashboardPage({
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
  final TargetDashboardCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.targetView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<TargetDashboardCubit>(
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
          child: const _TargetDashboardView(),
        );
      },
    );
  }
}

class _TargetDashboardView extends StatefulWidget {
  const _TargetDashboardView();

  @override
  State<_TargetDashboardView> createState() => _TargetDashboardViewState();
}

class _TargetDashboardViewState extends State<_TargetDashboardView> {
  final _dimensionIdController = TextEditingController();

  @override
  void dispose() {
    _dimensionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TargetDashboardCubit, TargetDashboardState>(
      builder: (context, state) {
        if (_dimensionIdController.text != state.dimensionId) {
          _dimensionIdController.text = state.dimensionId;
        }
        final cubit = context.read<TargetDashboardCubit>();

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Atingimento de metas',
            filtersBuilder: (context) => _TargetDashboardFilters(
              state: state,
              cubit: cubit,
              dimensionIdController: _dimensionIdController,
            ),
            content: _TargetDashboardContent(state: state, cubit: cubit),
          ),
        );
      },
    );
  }
}

class _TargetDashboardFilters extends StatelessWidget {
  const _TargetDashboardFilters({
    required this.state,
    required this.cubit,
    required this.dimensionIdController,
  });

  final TargetDashboardState state;
  final TargetDashboardCubit cubit;
  final TextEditingController dimensionIdController;

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
            dimensionId: state.dimensionId,
            metricType: values.first,
          ),
          closeSemanticLabel: 'Fechar seleção de métrica',
          label: 'Métrica',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        if (state.canPickDimension) ...<Widget>[
          AppDropdown<TargetDimensionType>(
            options: const <AppDropdownOption<TargetDimensionType>>[
              AppDropdownOption(
                value: TargetDimensionType.salesRep,
                label: 'Vendedor',
              ),
              AppDropdownOption(
                value: TargetDimensionType.team,
                label: 'Equipe',
              ),
              AppDropdownOption(
                value: TargetDimensionType.company,
                label: 'Empresa',
              ),
              AppDropdownOption(
                value: TargetDimensionType.collection,
                label: 'Coleção',
              ),
              AppDropdownOption(
                value: TargetDimensionType.category,
                label: 'Categoria',
              ),
            ],
            selectedValues: <TargetDimensionType>{state.dimensionType},
            onChanged: (values) => cubit.selectDimension(
              dimensionType: values.first,
              dimensionId: state.dimensionId,
              metricType: state.metricType,
            ),
            closeSemanticLabel: 'Fechar seleção de dimensão',
            label: 'Dimensão',
          ),
          const SizedBox(height: AppSpacing.spacing12),
          AppTextField(
            controller: dimensionIdController,
            label: _dimensionIdLabel(state.dimensionType),
            semanticLabel: _dimensionIdLabel(state.dimensionType),
            onChanged: (_) {},
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Ver atingimento',
            variant: AppButtonVariant.secondary,
            isLoading: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () => cubit.selectDimension(
                    dimensionType: state.dimensionType,
                    dimensionId: dimensionIdController.text,
                    metricType: state.metricType,
                  ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.candidates.isNotEmpty) ...<Widget>[
          Text('Período', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.spacing8),
          for (final target in state.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: AppButton(
                label:
                    '${_periodButtonDateFormat.format(target.startDate)} - '
                    '${_periodButtonDateFormat.format(target.endDate)}',
                semanticLabel:
                    '${_dateFormat.format(target.startDate)} a '
                    '${_dateFormat.format(target.endDate)}',
                variant: state.selectedTarget?.id == target.id
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: state.isBusy
                    ? null
                    : () => cubit.selectPeriod(target),
              ),
            ),
        ],
      ],
    );
  }

  String _dimensionIdLabel(TargetDimensionType dimensionType) {
    return switch (dimensionType) {
      TargetDimensionType.salesRep => 'Id do vendedor',
      TargetDimensionType.team => 'Id da equipe',
      TargetDimensionType.company => 'Id da empresa',
      TargetDimensionType.collection => 'Id da coleção',
      TargetDimensionType.category => 'Id da categoria',
    };
  }
}

class _TargetDashboardContent extends StatelessWidget {
  const _TargetDashboardContent({required this.state, required this.cubit});

  final TargetDashboardState state;
  final TargetDashboardCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case TargetDashboardStatus.initial:
      case TargetDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TargetDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso a esta meta',
          description:
              'Você não tem permissão para ver o atingimento desta '
              'dimensão. Fale com seu gestor caso acredite que isso é um '
              'engano.',
        );
      case TargetDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o atingimento',
          message: state.failureMessage ?? 'Tente novamente em breve.',
        );
      case TargetDashboardStatus.empty:
        return const AppEmptyState(
          icon: Icons.flag_outlined,
          title: 'Nenhuma meta cadastrada para este período',
          description:
              'Cadastre uma meta para esta dimensão e métrica para '
              'acompanhar o atingimento aqui.',
        );
      case TargetDashboardStatus.notCalculated:
      case TargetDashboardStatus.ready:
        return _TargetDashboardBody(state: state);
    }
  }
}

class _TargetDashboardBody extends StatelessWidget {
  const _TargetDashboardBody({required this.state});

  final TargetDashboardState state;

  @override
  Widget build(BuildContext context) {
    final target = state.selectedTarget;
    if (target == null) {
      return const AppEmptyState(
        icon: Icons.flag_outlined,
        title: 'Selecione um período',
        description: 'Escolha um período nos filtros para ver o atingimento.',
      );
    }
    final progress = state.progress;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Período de referência: ${_dateFormat.format(target.startDate)} '
            'a ${_dateFormat.format(target.endDate)}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            progress?.calculatedAt != null
                ? 'Último cálculo: '
                      '${_dateTimeFormat.format(progress!.calculatedAt!.toLocal())}'
                : 'Cálculo do realizado ainda não disponível para este '
                      'período — os valores abaixo podem estar desatualizados '
                      'ou zerados até a próxima sincronização.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: _kpiCards(target, progress),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          _ClosingProjectionCard(
            target: target,
            projection: state.closingProjection,
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Este gráfico responde: estou no ritmo para bater a meta deste '
            'período?',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppManagementChart(
            type: AppChartType.line,
            series: _chartSeries(target, progress),
            valueFormatter: (value) => _currencyFormat.format(value),
          ),
        ],
      ),
    );
  }

  List<Widget> _kpiCards(Target target, TargetProgressViewModel? progress) {
    final currencyOrCount = target.metricType == TargetMetricType.revenue
        ? _currencyFormat.format
        : (double value) => value.toStringAsFixed(0);

    return <Widget>[
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Meta',
          value: currencyOrCount(target.targetValue),
          icon: Icons.flag_outlined,
        ),
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Realizado',
          value: currencyOrCount(progress?.realizedValue ?? 0),
          icon: Icons.trending_up,
          trend: progress == null
              ? AppKpiTrend.neutral
              : (progress.isOnPace ? AppKpiTrend.up : AppKpiTrend.down),
          trendPercentage: progress == null
              ? null
              : progress.achievementPercentage - progress.elapsedTimePercentage,
          trendLabel: 'vs. ritmo esperado do período',
        ),
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Gap para a meta',
          value: currencyOrCount(progress?.gapAbsolute ?? target.targetValue),
          icon: Icons.flag_circle_outlined,
          trend: progress == null
              ? AppKpiTrend.neutral
              : (progress.gapAbsolute <= 0 ? AppKpiTrend.up : AppKpiTrend.down),
        ),
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Atingimento',
          value:
              '${(progress?.achievementPercentage ?? 0).toStringAsFixed(1)}%',
          icon: Icons.percent_outlined,
          trend: progress == null
              ? AppKpiTrend.neutral
              : (progress.isOnPace ? AppKpiTrend.up : AppKpiTrend.down),
          trendPercentage: progress?.elapsedTimePercentage,
          trendLabel: 'do período decorrido',
        ),
      ),
    ];
  }

  List<AppChartSeries> _chartSeries(
    Target target,
    TargetProgressViewModel? progress,
  ) {
    final realized = progress?.realizedValue ?? 0;
    final projected = progress?.projectedValue ?? realized;

    return <AppChartSeries>[
      AppChartSeries(
        label: 'Meta',
        points: <AppChartPoint>[
          AppChartPoint(x: 0, y: target.targetValue, label: 'Início'),
          AppChartPoint(x: 1, y: target.targetValue, label: 'Hoje'),
          AppChartPoint(x: 2, y: target.targetValue, label: 'Fim do período'),
        ],
      ),
      AppChartSeries(
        label: 'Realizado',
        points: <AppChartPoint>[
          const AppChartPoint(x: 0, y: 0, label: 'Início'),
          AppChartPoint(x: 1, y: realized, label: 'Hoje'),
        ],
      ),
      AppChartSeries(
        label: 'Projeção',
        points: <AppChartPoint>[
          AppChartPoint(x: 1, y: realized, label: 'Hoje'),
          AppChartPoint(x: 2, y: projected, label: 'Fim do período'),
        ],
      ),
    ];
  }
}

/// Closing-result estimate (TASK-119, EPIC-15), shown right after the
/// achievement KPI cards. Always labeled "Projeção"/"estimativa" and styled
/// distinctly (italicized, muted color) from `Realizado`'s solid headline in
/// `_kpiCards` above — the value must never be mistaken for what actually
/// happened. The methodology text ([ClosingProjectionResult
/// .methodologyDescription]) is always rendered next to the number, per the
/// "nunca uma caixa preta" rule (`docs/architecture/closing-projection-methodology.md`).
class _ClosingProjectionCard extends StatelessWidget {
  const _ClosingProjectionCard({
    required this.target,
    required this.projection,
  });

  final Target target;
  final ClosingProjectionResult? projection;

  @override
  Widget build(BuildContext context) {
    final result = projection;
    if (result == null) return const SizedBox.shrink();

    final colors = context.colors;
    final currencyOrCount = target.metricType == TargetMetricType.revenue
        ? _currencyFormat.format
        : (double value) => value.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.query_stats,
                size: AppIconSizes.lg,
                color: colors.outline,
              ),
              const SizedBox(width: AppSpacing.spacing8),
              const Expanded(
                child: Text(
                  'Projeção de fechamento (estimativa)',
                  style: AppTypography.labelLarge,
                ),
              ),
              if (result.isFinalResult)
                const AppStatusBadge(
                  label: 'Período encerrado',
                  variant: AppStatusBadgeVariant.neutral,
                  icon: Icons.flag_outlined,
                )
              else if (result.isLowConfidence)
                const AppStatusBadge(
                  label: 'Baixa confiabilidade',
                  variant: AppStatusBadgeVariant.warning,
                  icon: Icons.warning_amber_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            'Estimativa: ${currencyOrCount(result.projectedValue)}',
            style: AppTypography.headlineMedium.copyWith(
              color: colors.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Row(
            children: <Widget>[
              Icon(
                result.isAboveTarget ? Icons.trending_up : Icons.trending_down,
                size: AppIconSizes.sm,
                color: result.isAboveTarget ? colors.success : colors.error,
              ),
              const SizedBox(width: AppSpacing.spacing4),
              Flexible(
                child: Text(
                  result.isAboveTarget
                      ? 'Projeção acima da meta '
                            '(${result.projectedAchievementPercentage.toStringAsFixed(1)}%)'
                      : 'Projeção abaixo da meta '
                            '(${result.projectedAchievementPercentage.toStringAsFixed(1)}%)',
                  style: AppTypography.labelMedium.copyWith(
                    color: result.isAboveTarget ? colors.success : colors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Metodologia: ${result.methodologyDescription}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          if (result.isLowConfidence) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              'Poucos dias decorridos neste período — esta projeção ainda '
              'tem baixa confiabilidade e pode mudar bastante conforme mais '
              'vendas forem registradas.',
              style: AppTypography.bodySmall.copyWith(color: colors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

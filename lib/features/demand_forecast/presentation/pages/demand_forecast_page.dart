import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/demand_forecast.dart';
import '../../domain/entities/demand_forecast_period_projection.dart';
import '../../domain/value_objects/demand_forecast_scope_type.dart';
import '../../domain/value_objects/demand_forecast_status.dart';
import '../bloc/demand_forecast_bloc.dart';
import '../bloc/demand_forecast_event.dart';
import '../bloc/demand_forecast_state.dart';

/// Tela de previsão de demanda (TASK-185, EPIC-27): histórico real +
/// projeção com intervalo de confiança para um produto/coleção/região,
/// sempre com a data/versão do modelo visível — nunca um número
/// apresentado sem sua evidência (`tasks.md`/TASK-185).
///
/// Gated behind [Capability.reportViewSensitive] — mesma capability
/// [ReplenishmentSuggestionsPage] (TASK-184) já usa, já que ambas expõem a
/// mesma classe de dado sensível de planejamento/estoque.
class DemandForecastPage extends StatelessWidget {
  const DemandForecastPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialScopeType = DemandForecastScopeType.product,
    this.initialScopeId,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final DemandForecastBloc Function() createBloc;
  final DemandForecastScopeType initialScopeType;
  final String? initialScopeId;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        final scopeId = initialScopeId?.trim();
        return BlocProvider<DemandForecastBloc>(
          create: (_) {
            final bloc = createBloc();
            if (scopeId != null && scopeId.isNotEmpty) {
              bloc.add(
                DemandForecastRequested(
                  organizationId: organizationId,
                  companyId: companyId,
                  userId: userId,
                  scopeType: initialScopeType,
                  scopeId: scopeId,
                ),
              );
            }
            return bloc;
          },
          child: _DemandForecastView(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
            initialScopeType: initialScopeType,
            initialScopeId: scopeId,
          ),
        );
      },
    );
  }
}

class _DemandForecastView extends StatelessWidget {
  const _DemandForecastView({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.initialScopeType,
    this.initialScopeId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final DemandForecastScopeType initialScopeType;
  final String? initialScopeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DemandForecastBloc, DemandForecastState>(
      builder: (context, state) {
        final bloc = context.read<DemandForecastBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Previsão de demanda',
            filtersBuilder: (context) => _Filters(
              state: state,
              organizationId: organizationId,
              companyId: companyId,
              userId: userId,
              initialScopeType: initialScopeType,
              initialScopeId: initialScopeId,
            ),
            content: _Content(state: state, bloc: bloc),
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.bloc});

  final DemandForecastState state;
  final DemandForecastBloc bloc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (state.loadStatus == DemandForecastLoadStatus.initial) {
      return const AppEmptyState(
        title: 'Selecione um escopo',
        description:
            'Escolha produto, coleção ou região e informe o identificador '
            'para ver a previsão de demanda.',
        icon: Icons.query_stats_outlined,
      );
    }

    if (state.loadStatus == DemandForecastLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadStatus == DemandForecastLoadStatus.failure) {
      return AppEmptyState(
        title: 'Não foi possível carregar a previsão',
        description: state.failure?.message ?? 'Tente novamente em breve.',
        icon: Icons.error_outline,
        actionLabel: 'Tentar novamente',
        onAction: () => bloc.add(const DemandForecastRefreshRequested()),
      );
    }

    final forecast = state.forecast;
    if (forecast == null) {
      return const AppEmptyState(
        title: 'Nenhuma previsão gerada ainda',
        description:
            'Este escopo ainda não teve uma previsão calculada pelo job '
            'mensal. Tente novamente após o próximo ciclo de cálculo.',
        icon: Icons.hourglass_empty_outlined,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${forecast.scopeLabel} · gerado em '
            '${_formatDate(forecast.generatedAt)}'
            '${forecast.modelVersion != null ? ' · modelo ${forecast.modelVersion}' : ''}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Método: suavização exponencial com tendência (Holt). Não '
            'considera sazonalidade nem eventos externos (campanhas, '
            'feriados, ruptura de fornecedor). Sensível a poucos dados — '
            'por isso previsões nunca são geradas sem histórico mínimo. '
            'Sempre exibida com intervalo de confiança, nunca como número '
            'absoluto.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          if (!forecast.isAvailable)
            AppEmptyState(
              title: 'Previsão não disponível',
              description: _insufficientDataDescription(forecast),
              icon: Icons.info_outline,
            )
          else ...[
            Text(
              'Histórico realizado',
              style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            AppManagementChart(
              type: AppChartType.line,
              series: <AppChartSeries>[
                AppChartSeries(
                  label: 'Quantidade vendida',
                  points: <AppChartPoint>[
                    for (var i = 0; i < forecast.history.length; i++)
                      AppChartPoint(
                        x: i.toDouble(),
                        y: forecast.history[i].quantity,
                        label: forecast.history[i].periodKey,
                      ),
                  ],
                ),
              ],
              emptyTitle: 'Sem histórico para exibir',
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Projeção (com intervalo de confiança)',
              style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            AppManagementChart(
              type: AppChartType.line,
              series: _forecastSeries(forecast.forecastPeriods, colors),
              emptyTitle: 'Sem projeção para exibir',
            ),
          ],
        ],
      ),
    );
  }

  List<AppChartSeries> _forecastSeries(
    List<DemandForecastPeriodProjection> periods,
    AppColors colors,
  ) {
    return <AppChartSeries>[
      AppChartSeries(
        label: 'Limite superior',
        color: colors.outline,
        points: <AppChartPoint>[
          for (var i = 0; i < periods.length; i++)
            AppChartPoint(
              x: i.toDouble(),
              y: periods[i].upperBound,
              label: periods[i].periodKey,
            ),
        ],
      ),
      AppChartSeries(
        label: 'Previsto',
        color: colors.primary,
        points: <AppChartPoint>[
          for (var i = 0; i < periods.length; i++)
            AppChartPoint(
              x: i.toDouble(),
              y: periods[i].predictedQuantity,
              label: periods[i].periodKey,
            ),
        ],
      ),
      AppChartSeries(
        label: 'Limite inferior',
        color: colors.outline,
        points: <AppChartPoint>[
          for (var i = 0; i < periods.length; i++)
            AppChartPoint(
              x: i.toDouble(),
              y: periods[i].lowerBound,
              label: periods[i].periodKey,
            ),
        ],
      ),
    ];
  }

  String _insufficientDataDescription(DemandForecast forecast) {
    final reason = forecast.insufficientDataReason;
    final base = switch (reason) {
      DemandForecastInsufficientDataReason.noHistory =>
        'Não há nenhum histórico de vendas registrado para este escopo.',
      DemandForecastInsufficientDataReason.notEnoughHistory =>
        'Este escopo tem apenas ${forecast.observedPeriodsCount} mês(es) '
            'com vendas registradas — histórico insuficiente para um '
            'modelo confiável.',
      null => 'Histórico insuficiente para gerar uma previsão confiável.',
    };
    return '$base Nenhum número é fabricado nessa condição.';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _Filters extends StatefulWidget {
  const _Filters({
    required this.state,
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.initialScopeType,
    this.initialScopeId,
  });

  final DemandForecastState state;
  final String organizationId;
  final String companyId;
  final String userId;
  final DemandForecastScopeType initialScopeType;
  final String? initialScopeId;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late final TextEditingController _scopeIdController;
  late DemandForecastScopeType _scopeType;

  @override
  void initState() {
    super.initState();
    _scopeType = widget.state.loadStatus == DemandForecastLoadStatus.initial
        ? widget.initialScopeType
        : widget.state.scopeType;
    _scopeIdController = TextEditingController(
      text: widget.state.loadStatus == DemandForecastLoadStatus.initial
          ? (widget.initialScopeId ?? '')
          : widget.state.scopeId,
    );
  }

  @override
  void dispose() {
    _scopeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Escopo',
            style: AppTypography.labelLarge.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              for (final scopeType in DemandForecastScopeType.values)
                AppFilterChip(
                  label: _scopeTypeLabel(scopeType),
                  selected: _scopeType == scopeType,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _scopeType = scopeType);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            key: const ValueKey('demand_forecast_scope_id_filter'),
            controller: _scopeIdController,
            label: _scopeIdLabel(_scopeType),
            hintText: 'Informe o identificador',
            prefixIcon: const Icon(Icons.search),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(context),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Buscar previsão',
            leadingIcon: Icons.query_stats_outlined,
            isDisabled: _scopeIdController.text.trim().isEmpty,
            onPressed: () => _apply(context),
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext context) {
    final scopeId = _scopeIdController.text.trim();
    if (scopeId.isEmpty) return;
    context.read<DemandForecastBloc>().add(
      DemandForecastRequested(
        organizationId: widget.organizationId,
        companyId: widget.companyId,
        userId: widget.userId,
        scopeType: _scopeType,
        scopeId: scopeId,
      ),
    );
  }

  String _scopeTypeLabel(DemandForecastScopeType scopeType) {
    return switch (scopeType) {
      DemandForecastScopeType.product => 'Produto',
      DemandForecastScopeType.collection => 'Coleção',
      DemandForecastScopeType.region => 'Região',
    };
  }

  String _scopeIdLabel(DemandForecastScopeType scopeType) {
    return switch (scopeType) {
      DemandForecastScopeType.product => 'ID do produto',
      DemandForecastScopeType.collection => 'ID da coleção',
      DemandForecastScopeType.region => 'Sigla da região (UF)',
    };
  }
}

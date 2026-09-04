import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/collection_dashboard_category_mix.dart';
import '../../domain/entities/collection_dashboard_entry.dart';
import '../../domain/entities/collection_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../bloc/collection_dashboard_bloc.dart';
import '../bloc/collection_dashboard_event.dart';
import '../bloc/collection_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

/// Collection Dashboard (TASK-138, EPIC-17): "performance por
/// coleção/estação, com comparação entre coleções" — faturamento,
/// quantidade vendida, ticket médio, margem, mix médio de categorias e
/// sell-through de até [CollectionDashboardFilters.maxComparedCollections]
/// Collections lado a lado, cada uma sobre o seu próprio período real
/// (`Collection.startDate`–`endDate`, TASK-066), mais drill-down até o
/// Product Dashboard (TASK-137) filtrado por coleção.
///
/// Reads exclusively from [CollectionDashboardBloc]
/// (`LoadCollectionDashboardEntriesUseCase`, TASK-133's `productMonthly` +
/// TASK-094's giro de estoque por coleção — never a raw query against
/// `orders`/`products`). Gated behind [Capability.reportViewSensitive] —
/// mesma capability que todo outro dashboard do EPIC-17 já exige.
class CollectionDashboardPage extends StatelessWidget {
  const CollectionDashboardPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialFilters,
    required this.onDrillDownToCollection,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final CollectionDashboardBloc Function() createBloc;
  final CollectionDashboardFilters initialFilters;

  /// Called when the caller drills down from a coleção into the Product
  /// Dashboard (TASK-137) filtered by that coleção — the composition root
  /// (`bootstrap.dart`) decides the actual navigation, same "this page never
  /// hard-codes another feature's route" contract
  /// `ProductDashboardPage.onDrillDownToProduct` already sets.
  final ValueChanged<String> onDrillDownToCollection;

  /// Called whenever [CollectionDashboardFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `ProductDashboardPage.onUrlStateChanged` already sets.
  final void Function(CollectionDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CollectionDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              CollectionDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _CollectionDashboardView(
            onDrillDownToCollection: onDrillDownToCollection,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _CollectionDashboardView extends StatelessWidget {
  const _CollectionDashboardView({
    required this.onDrillDownToCollection,
    this.onUrlStateChanged,
  });

  final ValueChanged<String> onDrillDownToCollection;
  final void Function(CollectionDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CollectionDashboardBloc, CollectionDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<CollectionDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard de coleção',
            filtersTitle: 'Filtros do dashboard de coleção',
            filtersBuilder: (_) => _CollectionDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(CollectionDashboardFiltersChanged(filters)),
            ),
            content: _CollectionDashboardContent(
              state: state,
              onRetry: () => bloc.add(const CollectionDashboardRetried()),
              onDrillDownToCollection: onDrillDownToCollection,
            ),
          ),
        );
      },
    );
  }
}

class _CollectionDashboardFiltersForm extends StatelessWidget {
  const _CollectionDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final CollectionDashboardState state;
  final ValueChanged<CollectionDashboardFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
        AppDropdown<String>(
          options: <AppDropdownOption<String>>[
            for (final option in state.collectionOptions)
              AppDropdownOption(
                value: option.id,
                label: option.name,
                enabled:
                    filters.collectionIds.contains(option.id) ||
                    filters.collectionIds.length <
                        CollectionDashboardFilters.maxComparedCollections,
              ),
          ],
          selectedValues: filters.collectionIds.toSet(),
          multiple: true,
          onChanged: (values) => onChanged(
            filters.copyWith(
              collectionIds: values
                  .take(CollectionDashboardFilters.maxComparedCollections)
                  .toList(growable: false),
            ),
          ),
          closeSemanticLabel: 'Fechar seleção de coleções',
          label: 'Coleções em comparação',
          hintText:
              'Selecione até '
              '${CollectionDashboardFilters.maxComparedCollections} coleções',
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Apenas coleções não excluídas entram na comparação. Cada coleção '
          'é analisada sobre o seu próprio período de vigência.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
      ],
    );
  }
}

class _CollectionDashboardContent extends StatelessWidget {
  const _CollectionDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onDrillDownToCollection,
  });

  final CollectionDashboardState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onDrillDownToCollection;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CollectionDashboardStatus.initial:
      case CollectionDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CollectionDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard de coleção',
          description:
              'Você não tem permissão para ver esta análise de coleções. '
              'Fale com um administrador caso acredite que isso é um '
              'engano.',
        );
      case CollectionDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard de coleção',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case CollectionDashboardStatus.ready:
        if (state.entries.isEmpty) {
          return const AppEmptyState(
            icon: Icons.style_outlined,
            title: 'Nenhuma coleção selecionada',
            description:
                'Use o filtro "Coleções em comparação" para escolher uma ou '
                'mais coleções e ver o desempenho de cada lançamento '
                'sazonal.',
          );
        }
        return _CollectionComparisonLayout(
          entries: state.entries,
          onDrillDownToCollection: onDrillDownToCollection,
        );
    }
  }
}

/// Renders every [CollectionDashboardEntry] lado a lado on desktop/large
/// desktop and empilhada (stacked) on mobile/tablet, this task's own
/// "comparação lado a lado" + widget-test requirement — resolved through
/// [AppResponsiveBuilder] (never an ad hoc `MediaQuery` width check), same
/// precedent every other Design System layout already sets.
class _CollectionComparisonLayout extends StatelessWidget {
  const _CollectionComparisonLayout({
    required this.entries,
    required this.onDrillDownToCollection,
  });

  final List<CollectionDashboardEntry> entries;
  final ValueChanged<String> onDrillDownToCollection;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final cards = <Widget>[
          for (final entry in entries)
            _CollectionDashboardCard(
              entry: entry,
              onDrillDownToCollection: onDrillDownToCollection,
            ),
        ];
        if (breakpoint == AppBreakpoint.mobile || entries.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final card in cards) ...<Widget>[
                card,
                const SizedBox(height: AppSpacing.spacing16),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < cards.length; i++) ...<Widget>[
                Expanded(child: cards[i]),
                if (i != cards.length - 1)
                  const SizedBox(width: AppSpacing.spacing16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CollectionDashboardCard extends StatelessWidget {
  const _CollectionDashboardCard({
    required this.entry,
    required this.onDrillDownToCollection,
  });

  final CollectionDashboardEntry entry;
  final ValueChanged<String> onDrillDownToCollection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(entry.collectionName, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              _periodLabel(),
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            if (!entry.hasDefinedPeriod)
              Text(
                'Período não definido: esta coleção ainda não tem data de '
                'início cadastrada (TASK-066), então nenhum KPI pôde ser '
                'calculado.',
                style: AppTypography.bodySmall.copyWith(color: colors.error),
              )
            else ...<Widget>[
              _kpiRow(
                'Faturamento (líquido)',
                _currencyFormat.format(entry.revenueNet),
              ),
              _kpiRow('Quantidade vendida', '${entry.quantitySold}'),
              _kpiRow(
                'Ticket médio',
                _currencyFormat.format(entry.averageTicket),
              ),
              _kpiRow(
                'Desconto médio',
                '${entry.discountPercentage.toStringAsFixed(1)}%',
              ),
              _metricRow(
                'Margem',
                entry.margin,
                'Sem dado de custo/margem disponível',
              ),
              _metricRow(
                'Sell-through',
                entry.sellThrough,
                'Sem giro de estoque calculado para esta coleção/período',
                format: (value) => '${value.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Text('Mix médio de categorias', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.spacing8),
              if (!entry.hasSalesData || entry.categoryMix.isEmpty)
                Text(
                  'Nenhuma venda registrada nesta coleção no período.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                )
              else
                for (final mix in entry.categoryMix)
                  _categoryMixRow(context, mix),
            ],
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Ver produtos desta coleção',
              semanticLabel: 'Ver produtos da coleção ${entry.collectionName}',
              variant: AppButtonVariant.secondary,
              onPressed: () => onDrillDownToCollection(entry.collectionId),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel() {
    if (!entry.hasDefinedPeriod) return 'Sem período definido';
    final start = entry.periodStart;
    final end = entry.periodEnd;
    final startLabel = start == null ? '—' : _dateFormat.format(start);
    final endLabel = end == null ? 'em andamento' : _dateFormat.format(end);
    return '$startLabel a $endLabel';
  }

  Widget _kpiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _metricRow(
    String label,
    ExecutiveDashboardMetric metric,
    String notCalculatedLabel, {
    String Function(double)? format,
  }) {
    final value = switch (metric.status) {
      ExecutiveDashboardMetricStatus.available =>
        (format ?? (v) => v.toStringAsFixed(1))(metric.value!),
      ExecutiveDashboardMetricStatus.notCalculated => notCalculatedLabel,
      ExecutiveDashboardMetricStatus.failed => 'Indisponível no momento',
    };
    return _kpiRow(label, value);
  }

  Widget _categoryMixRow(
    BuildContext context,
    CollectionDashboardCategoryMix mix,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(mix.categoryName, style: AppTypography.bodySmall),
          ),
          Text(
            '${mix.percentage.toStringAsFixed(1)}%',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

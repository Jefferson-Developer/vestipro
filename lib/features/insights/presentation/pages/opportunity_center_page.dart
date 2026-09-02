import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/insight_action.dart';
import '../../domain/entities/opportunity_center_filters.dart';
import '../../domain/value_objects/insight_action_type.dart';
import '../../domain/value_objects/insight_severity.dart';
import '../../domain/value_objects/insight_sort_by.dart';
import '../../domain/value_objects/insight_status.dart';
import '../../domain/value_objects/insight_type.dart';
import '../bloc/opportunity_center_bloc.dart';
import '../bloc/opportunity_center_event.dart';
import '../bloc/opportunity_center_state.dart';

/// Central de Oportunidades (TASK-132, EPIC-16): the single screen
/// aggregating every `Insight` type (TASK-122 a TASK-131) the caller may
/// see, prioritized by `estimatedImpact` by default, with a quick action,
/// discard/resolve (with undo) and an expandable evidence detail directly
/// on each row.
///
/// Gated behind [Capability.insightView], the same two-layer shape
/// `TargetDashboardPage` uses for [Capability.targetView]: this only
/// decides whether the page is reachable at all — *which* insights the
/// caller then actually sees is `InsightVisibilityService`'s job
/// (`OpportunityCenterBloc`), never re-implemented here.
///
/// [onActionExecuted] is the only way this page ever navigates anywhere:
/// exactly like `OrderListPage.onOrderDraftSelected`/
/// `CustomerPortfolioPage.onCustomerSelected`, the composition root
/// (`bootstrap.dart`) decides which already-existing route each
/// `InsightActionType` resolves to, so this feature never hard-codes
/// another feature's route.
class OpportunityCenterPage extends StatelessWidget {
  const OpportunityCenterPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.onActionExecuted,
    this.initialFilters = OpportunityCenterFilters.empty,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final OpportunityCenterBloc Function() createBloc;

  /// Called right after logging `insight_action_clicked` for [action] on
  /// [insight] — always the same fluxo already validated on the insight's
  /// origin task (ex.: abrir cliente, iniciar pedido, agendar contato),
  /// never a new navigation implemented by this page.
  final void Function(Insight insight, InsightAction action) onActionExecuted;

  final OpportunityCenterFilters initialFilters;

  /// Called whenever [OpportunityCenterFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `OrderListPage.onUrlStateChanged` already sets.
  final void Function(OpportunityCenterFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.insightView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<OpportunityCenterBloc>(
          create: (_) => createBloc()
            ..add(
              OpportunityCenterStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                filters: initialFilters,
              ),
            ),
          child: _OpportunityCenterView(
            onActionExecuted: onActionExecuted,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _OpportunityCenterView extends StatelessWidget {
  const _OpportunityCenterView({
    required this.onActionExecuted,
    this.onUrlStateChanged,
  });

  final void Function(Insight insight, InsightAction action) onActionExecuted;
  final void Function(OpportunityCenterFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OpportunityCenterBloc, OpportunityCenterState>(
      listenWhen: (previous, current) =>
          previous.pendingUndo != current.pendingUndo ||
          previous.filters != current.filters,
      listener: (context, state) {
        if (onUrlStateChanged != null &&
            state.filters != const OpportunityCenterFilters()) {
          onUrlStateChanged!(state.filters);
        }
        final pendingUndo = state.pendingUndo;
        if (pendingUndo != null) {
          final bloc = context.read<OpportunityCenterBloc>();
          AppSnackbar.show(
            context,
            message: pendingUndo.appliedStatus == InsightStatus.dismissed
                ? 'Insight descartado.'
                : 'Insight marcado como resolvido.',
            variant: AppSnackbarVariant.neutral,
            actionLabel: 'Desfazer',
            onAction: () => bloc.add(
              OpportunityCenterUndoRequested(pendingUndo.insight.id),
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<OpportunityCenterBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Central de oportunidades',
            filtersTitle: 'Filtros de oportunidades',
            filtersBuilder: (_) => _OpportunityCenterFiltersForm(
              filters: state.filters,
              onChanged: (filters) =>
                  bloc.add(OpportunityCenterFiltersChanged(filters)),
            ),
            content: _OpportunityCenterContent(
              state: state,
              onActionExecuted: onActionExecuted,
            ),
          ),
        );
      },
    );
  }
}

class _OpportunityCenterContent extends StatelessWidget {
  const _OpportunityCenterContent({
    required this.state,
    required this.onActionExecuted,
  });

  final OpportunityCenterState state;
  final void Function(Insight insight, InsightAction action) onActionExecuted;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OpportunityCenterBloc>();
    final visibleInsights = state.visibleInsights;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDataTable<Insight>(
            status: _tableStatus(state, visibleInsights),
            rows: visibleInsights,
            rowIdBuilder: (insight) => insight.id,
            emptyTitle: 'Nenhuma oportunidade no momento',
            emptyDescription:
                'Quando a Inteligência Comercial identificar uma '
                'oportunidade para sua carteira, ela aparece aqui.',
            errorTitle: 'Não foi possível carregar as oportunidades',
            errorMessage: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () => bloc.add(const OpportunityCenterRetried()),
            mobileCardTitleBuilder: (context, insight) => Text(insight.title),
            columns: <AppDataColumn<Insight>>[
              AppDataColumn(
                label: 'Tipo',
                cellBuilder: (context, insight) =>
                    _InsightTypeBadge(type: insight.type),
              ),
              AppDataColumn(
                label: 'Oportunidade',
                cellBuilder: (context, insight) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      insight.title,
                      style: AppTypography.labelLarge.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      insight.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              AppDataColumn(
                label: 'Impacto estimado',
                numeric: true,
                cellBuilder: (context, insight) => Text(_impactLabel(insight)),
              ),
              AppDataColumn(
                label: 'Recomendação',
                cellBuilder: (context, insight) => Text(
                  insight.recommendation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            rowActions: <AppDataTableAction<Insight>>[
              AppDataTableAction<Insight>(
                icon: Icons.bolt_outlined,
                semanticLabel: 'Executar ação rápida',
                iconBuilder: (insight) =>
                    _quickActionIcon(insight.quickAction.type),
                semanticLabelBuilder: (insight) => insight.quickAction.label,
                onPressed: (insight) {
                  bloc.add(
                    OpportunityCenterActionExecuted(
                      insightId: insight.id,
                      action: insight.quickAction,
                    ),
                  );
                  onActionExecuted(insight, insight.quickAction);
                },
              ),
              AppDataTableAction<Insight>(
                icon: Icons.visibility_outlined,
                semanticLabel: 'Ver evidência completa',
                onPressed: (insight) {
                  bloc.add(OpportunityCenterInsightOpened(insight.id));
                  _showEvidenceModal(context, insight, onActionExecuted, bloc);
                },
              ),
              AppDataTableAction<Insight>(
                icon: Icons.check_circle_outline,
                semanticLabel: 'Marcar como resolvido',
                onPressed: (insight) =>
                    bloc.add(OpportunityCenterInsightResolved(insight.id)),
              ),
              AppDataTableAction<Insight>(
                icon: Icons.close_outlined,
                semanticLabel: 'Descartar insight',
                onPressed: (insight) =>
                    bloc.add(OpportunityCenterInsightDismissed(insight.id)),
              ),
            ],
          ),
          if (state.status == OpportunityCenterLoadStatus.ready ||
              state.status == OpportunityCenterLoadStatus.loadingMore) ...[
            const SizedBox(height: AppSpacing.spacing8),
            AppPagination(
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () =>
                  bloc.add(const OpportunityCenterNextPageRequested()),
            ),
          ],
        ],
      ),
    );
  }

  AppDataTableStatus _tableStatus(
    OpportunityCenterState state,
    List<Insight> visibleInsights,
  ) {
    return switch (state.status) {
      OpportunityCenterLoadStatus.initial ||
      OpportunityCenterLoadStatus.loading => AppDataTableStatus.loading,
      OpportunityCenterLoadStatus.failure => AppDataTableStatus.error,
      OpportunityCenterLoadStatus.ready ||
      OpportunityCenterLoadStatus.loadingMore =>
        visibleInsights.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  void _showEvidenceModal(
    BuildContext context,
    Insight insight,
    void Function(Insight insight, InsightAction action) onActionExecuted,
    OpportunityCenterBloc bloc,
  ) {
    unawaited(
      AppModal.show<void>(
        context: context,
        title: insight.title,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(insight.description, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.spacing16),
              Text('Evidência', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.spacing8),
              for (final evidence in insight.evidence)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
                  child: Text(
                    '${evidence.label}: ${evidence.value}',
                    style: AppTypography.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.spacing16),
              Text('Recomendação', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.spacing8),
              Text(insight.recommendation, style: AppTypography.bodyMedium),
            ],
          ),
        ),
        primaryAction: AppModalAction(
          label: insight.quickAction.label,
          onPressed: () {
            Navigator.of(context).pop();
            bloc.add(
              OpportunityCenterActionExecuted(
                insightId: insight.id,
                action: insight.quickAction,
              ),
            );
            onActionExecuted(insight, insight.quickAction);
          },
        ),
        secondaryAction: AppModalAction(
          label: 'Fechar',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  String _impactLabel(Insight insight) {
    final impact = insight.estimatedImpact;
    if (impact.amount != null) {
      return 'R\$ ${impact.amount!.toStringAsFixed(2)}';
    }
    if (impact.percentage != null) {
      return '${impact.percentage!.toStringAsFixed(1)}%';
    }
    return '—';
  }

  IconData _quickActionIcon(InsightActionType type) {
    return switch (type) {
      InsightActionType.openCustomer => Icons.storefront_outlined,
      InsightActionType.startOrder => Icons.add_shopping_cart_outlined,
      InsightActionType.scheduleContact => Icons.event_available_outlined,
      InsightActionType.viewCategory => Icons.category_outlined,
      InsightActionType.viewOrderHistory => Icons.history_outlined,
      InsightActionType.viewOpportunities => Icons.trending_up_outlined,
      InsightActionType.expandGrid => Icons.grid_view_outlined,
      InsightActionType.suggestCampaign => Icons.campaign_outlined,
      InsightActionType.notifyReplenishment => Icons.inventory_2_outlined,
      InsightActionType.resumeOrder => Icons.play_circle_outline,
      InsightActionType.viewSellerDetail => Icons.badge_outlined,
    };
  }
}

class _InsightTypeBadge extends StatelessWidget {
  const _InsightTypeBadge({required this.type});

  final InsightType type;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: insightTypeLabel(type),
      variant: AppStatusBadgeVariant.info,
      icon: _typeIcon(type),
    );
  }

  IconData _typeIcon(InsightType type) {
    return switch (type) {
      InsightType.inactiveCustomer => Icons.person_off_outlined,
      InsightType.revenueDrop => Icons.trending_down_outlined,
      InsightType.customerGrowth => Icons.trending_up_outlined,
      InsightType.crossSell => Icons.add_circle_outline,
      InsightType.upSell => Icons.upgrade_outlined,
      InsightType.insufficientMix => Icons.checklist_outlined,
      InsightType.highStockLowTurnover => Icons.warehouse_outlined,
      InsightType.replenishmentSuggestion => Icons.autorenew_outlined,
      InsightType.churnRisk => Icons.warning_amber_outlined,
      InsightType.abandonedOrder => Icons.remove_shopping_cart_outlined,
      InsightType.sellerBelowTarget => Icons.flag_outlined,
    };
  }
}

/// Human-readable label for [InsightType] — reused by the type badge and
/// the type filter so they never drift apart.
String insightTypeLabel(InsightType type) {
  return switch (type) {
    InsightType.inactiveCustomer => 'Cliente inativo',
    InsightType.revenueDrop => 'Queda de faturamento',
    InsightType.customerGrowth => 'Cliente em crescimento',
    InsightType.crossSell => 'Cross-sell',
    InsightType.upSell => 'Up-sell',
    InsightType.insufficientMix => 'Mix insuficiente',
    InsightType.highStockLowTurnover => 'Estoque alto/giro baixo',
    InsightType.replenishmentSuggestion => 'Sugestão de reposição',
    InsightType.churnRisk => 'Risco de churn',
    InsightType.abandonedOrder => 'Pedido abandonado',
    InsightType.sellerBelowTarget => 'Vendedor abaixo da meta',
  };
}

String _severityLabel(InsightSeverity severity) {
  return switch (severity) {
    InsightSeverity.low => 'Baixa',
    InsightSeverity.medium => 'Média',
    InsightSeverity.high => 'Alta',
    InsightSeverity.critical => 'Crítica',
  };
}

class _OpportunityCenterFiltersForm extends StatelessWidget {
  const _OpportunityCenterFiltersForm({
    required this.filters,
    required this.onChanged,
  });

  final OpportunityCenterFilters filters;
  final ValueChanged<OpportunityCenterFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDropdown<InsightSortBy>(
            options: const <AppDropdownOption<InsightSortBy>>[
              AppDropdownOption(
                value: InsightSortBy.estimatedImpact,
                label: 'Impacto estimado',
              ),
              AppDropdownOption(
                value: InsightSortBy.generatedAt,
                label: 'Data de geração',
              ),
              AppDropdownOption(
                value: InsightSortBy.relatedEntity,
                label: 'Cliente/vendedor relacionado',
              ),
            ],
            selectedValues: <InsightSortBy>{filters.sortBy},
            onChanged: (values) =>
                onChanged(filters.copyWith(sortBy: values.first)),
            closeSemanticLabel: 'Fechar seleção de ordenação',
            label: 'Ordenar por',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<InsightType>(
            options: <AppDropdownOption<InsightType>>[
              for (final type in InsightType.values)
                AppDropdownOption(value: type, label: insightTypeLabel(type)),
            ],
            selectedValues: filters.types,
            multiple: true,
            onChanged: (types) => onChanged(filters.copyWith(types: types)),
            closeSemanticLabel: 'Fechar seleção de tipo de insight',
            label: 'Tipo de insight',
            hintText: 'Todos os tipos',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<InsightSeverity>(
            options: <AppDropdownOption<InsightSeverity>>[
              for (final severity in InsightSeverity.values)
                AppDropdownOption(
                  value: severity,
                  label: _severityLabel(severity),
                ),
            ],
            selectedValues: filters.severities,
            multiple: true,
            onChanged: (severities) =>
                onChanged(filters.copyWith(severities: severities)),
            closeSemanticLabel: 'Fechar seleção de faixa de impacto',
            label: 'Faixa de impacto',
            hintText: 'Todas as faixas',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Limpar filtros',
            leadingIcon: Icons.clear_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: filters == const OpportunityCenterFilters(),
            onPressed: () => onChanged(const OpportunityCenterFilters()),
          ),
        ],
      ),
    );
  }
}

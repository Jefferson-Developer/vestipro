import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/replenishment_suggestion.dart';
import '../../domain/value_objects/replenishment_decision_action.dart';
import '../../domain/value_objects/replenishment_suggestion_status.dart';
import '../bloc/replenishment_suggestions_bloc.dart';
import '../bloc/replenishment_suggestions_event.dart';
import '../bloc/replenishment_suggestions_state.dart';

/// Sugestões de reposição (TASK-184, EPIC-27): every server-computed
/// `ReplenishmentSuggestion` this gestor/comprador may review, always with
/// the evidence it was computed from (giro médio, cobertura, saldo, ponto de
/// ressuprimento) visible alongside the quantity — never a number without
/// explanation (`tasks.md`/TASK-184).
///
/// Gated behind [Capability.reportViewSensitive] — the same gestor-level
/// capability [StockAlertsPage] already uses for the sibling stock-alerts
/// screen, since a replenishment suggestion is the same class of sensitive,
/// aggregated stock data. This only decides whether the page is reachable
/// at all: `decideReplenishmentSuggestion` (OWNER/ADMIN/SALES_MANAGER only)
/// remains the real, independent authorization for actually deciding one.
class ReplenishmentSuggestionsPage extends StatelessWidget {
  const ReplenishmentSuggestionsPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialWarehouseId,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ReplenishmentSuggestionsBloc Function() createBloc;

  /// Pre-fills the `warehouseId` filter — set when this screen is reached
  /// via an `Insight`'s `notifyReplenishment` deep link (TASK-128).
  final String? initialWarehouseId;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ReplenishmentSuggestionsBloc>(
          create: (_) => createBloc()
            ..add(
              ReplenishmentSuggestionsStarted(
                organizationId: organizationId,
                userId: userId,
                initialWarehouseId: initialWarehouseId,
              ),
            ),
          child: const _ReplenishmentSuggestionsView(),
        );
      },
    );
  }
}

class _ReplenishmentSuggestionsView extends StatelessWidget {
  const _ReplenishmentSuggestionsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      ReplenishmentSuggestionsBloc,
      ReplenishmentSuggestionsState
    >(
      listenWhen: (previous, current) =>
          previous.decisionFailure != current.decisionFailure &&
          current.decisionFailure != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.decisionFailure?.message ??
                  'Não foi possível registrar a decisão.',
            ),
          ),
        );
      },
      builder: (context, state) {
        final bloc = context.read<ReplenishmentSuggestionsBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Sugestões de reposição',
            filtersBuilder: (context) => _Filters(state: state),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Sugestões automáticas de reposição por variante, com base '
                  'no giro histórico e no saldo atual. Nenhum pedido é criado '
                  'sem sua confirmação.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child: SingleChildScrollView(
                    child: AppDataTable<ReplenishmentSuggestion>(
                      status: _tableStatus(state),
                      rows: state.suggestions,
                      rowIdBuilder: (suggestion) => suggestion.id,
                      emptyTitle: 'Nenhuma sugestão de reposição encontrada',
                      emptyDescription:
                          'Ajuste os filtros ou aguarde o próximo cálculo semanal.',
                      errorTitle: 'Não foi possível carregar as sugestões',
                      errorMessage:
                          state.failure?.message ?? 'Tente novamente em breve.',
                      retryLabel: 'Tentar novamente',
                      onRetry: () => bloc.add(
                        const ReplenishmentSuggestionsRefreshRequested(),
                      ),
                      mobileCardTitleBuilder: (context, suggestion) =>
                          Text(_statusLabel(suggestion.status)),
                      columns: <AppDataColumn<ReplenishmentSuggestion>>[
                        AppDataColumn(
                          label: 'Variante',
                          cellBuilder: (context, suggestion) => Text(
                            '${suggestion.productId}\n${suggestion.variantId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppDataColumn(
                          label: 'Depósito',
                          cellBuilder: (context, suggestion) =>
                              Text(suggestion.warehouseId),
                        ),
                        AppDataColumn(
                          label: 'Status',
                          cellBuilder: (context, suggestion) =>
                              Text(_statusLabel(suggestion.status)),
                        ),
                        AppDataColumn(
                          label: 'Giro médio (un/dia)',
                          numeric: true,
                          cellBuilder: (context, suggestion) => Text(
                            suggestion
                                    .turnoverEvidence
                                    ?.averageDailySalesQuantity
                                    .toStringAsFixed(2) ??
                                '—',
                          ),
                        ),
                        AppDataColumn(
                          label: 'Cobertura (dias)',
                          numeric: true,
                          cellBuilder: (context, suggestion) => Text(
                            suggestion.turnoverEvidence?.stockCoverageDays
                                    .toStringAsFixed(1) ??
                                '—',
                          ),
                        ),
                        AppDataColumn(
                          label: 'Saldo atual',
                          numeric: true,
                          cellBuilder: (context, suggestion) =>
                              Text('${suggestion.currentSellableQuantity}'),
                        ),
                        AppDataColumn(
                          label: 'Qtd. sugerida',
                          numeric: true,
                          cellBuilder: (context, suggestion) =>
                              Text('${suggestion.suggestedQuantity}'),
                        ),
                        AppDataColumn(
                          label: 'Decisão',
                          cellBuilder: (context, suggestion) => Text(
                            suggestion.isDecided
                                ? '${suggestion.finalQuantity ?? '—'} '
                                      '(${suggestion.decidedByName ?? '—'})'
                                : 'Pendente',
                          ),
                        ),
                      ],
                      rowActions: <AppDataTableAction<ReplenishmentSuggestion>>[
                        AppDataTableAction<ReplenishmentSuggestion>(
                          icon: Icons.check_circle_outline,
                          semanticLabel: 'Aceitar sugestão',
                          onPressed: (suggestion) =>
                              _accept(context, suggestion, state),
                        ),
                        AppDataTableAction<ReplenishmentSuggestion>(
                          icon: Icons.edit_outlined,
                          semanticLabel: 'Ajustar quantidade',
                          onPressed: (suggestion) =>
                              _adjust(context, suggestion, state),
                        ),
                        AppDataTableAction<ReplenishmentSuggestion>(
                          icon: Icons.cancel_outlined,
                          semanticLabel: 'Descartar sugestão',
                          onPressed: (suggestion) =>
                              _discard(context, suggestion, state),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.loadStatus ==
                    ReplenishmentSuggestionsLoadStatus.ready) ...[
                  const SizedBox(height: AppSpacing.spacing8),
                  AppPagination(
                    hasMore: state.hasMore,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: () => bloc.add(
                      const ReplenishmentSuggestionsNextPageRequested(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  AppDataTableStatus _tableStatus(ReplenishmentSuggestionsState state) {
    return switch (state.loadStatus) {
      ReplenishmentSuggestionsLoadStatus.initial ||
      ReplenishmentSuggestionsLoadStatus.loading => AppDataTableStatus.loading,
      ReplenishmentSuggestionsLoadStatus.failure => AppDataTableStatus.error,
      ReplenishmentSuggestionsLoadStatus.ready ||
      ReplenishmentSuggestionsLoadStatus.loadingMore =>
        state.suggestions.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  Future<void> _accept(
    BuildContext context,
    ReplenishmentSuggestion suggestion,
    ReplenishmentSuggestionsState state,
  ) async {
    if (!_canDecide(context, suggestion, state)) return;
    final bloc = context.read<ReplenishmentSuggestionsBloc>();
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Aceitar sugestão de reposição?',
      message:
          'Será criado um rascunho de reposição com a quantidade sugerida '
          '(${suggestion.suggestedQuantity} unidade(s)).',
      confirmLabel: 'Aceitar',
    );
    if (!confirmed) return;
    bloc.add(
      ReplenishmentSuggestionsDecided(
        suggestionId: suggestion.id,
        action: ReplenishmentDecisionAction.accept,
      ),
    );
  }

  Future<void> _adjust(
    BuildContext context,
    ReplenishmentSuggestion suggestion,
    ReplenishmentSuggestionsState state,
  ) async {
    if (!_canDecide(context, suggestion, state)) return;
    final bloc = context.read<ReplenishmentSuggestionsBloc>();
    final quantity = await _AdjustQuantityDialog.show(
      context,
      suggestion: suggestion,
    );
    if (quantity == null) return;
    bloc.add(
      ReplenishmentSuggestionsDecided(
        suggestionId: suggestion.id,
        action: ReplenishmentDecisionAction.adjust,
        adjustedQuantity: quantity,
      ),
    );
  }

  Future<void> _discard(
    BuildContext context,
    ReplenishmentSuggestion suggestion,
    ReplenishmentSuggestionsState state,
  ) async {
    if (!_canDecide(context, suggestion, state)) return;
    final bloc = context.read<ReplenishmentSuggestionsBloc>();
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Descartar sugestão de reposição?',
      message: 'Nenhum rascunho de reposição será criado para esta sugestão.',
      confirmLabel: 'Descartar',
    );
    if (!confirmed) return;
    bloc.add(
      ReplenishmentSuggestionsDecided(
        suggestionId: suggestion.id,
        action: ReplenishmentDecisionAction.discard,
      ),
    );
  }

  bool _canDecide(
    BuildContext context,
    ReplenishmentSuggestion suggestion,
    ReplenishmentSuggestionsState state,
  ) {
    if (state.decidingSuggestionId != null) return false;
    if (suggestion.isDecided) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta sugestão já foi decidida por '
            '${suggestion.decidedByName ?? 'outro usuário'}.',
          ),
        ),
      );
      return false;
    }
    return true;
  }
}

class _Filters extends StatefulWidget {
  const _Filters({required this.state});

  final ReplenishmentSuggestionsState state;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late final TextEditingController _warehouseController;
  ReplenishmentSuggestionStatus? _status;

  @override
  void initState() {
    super.initState();
    _warehouseController = TextEditingController(
      text: widget.state.warehouseId,
    );
    _status = widget.state.status;
  }

  @override
  void didUpdateWidget(covariant _Filters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.warehouseId != widget.state.warehouseId) {
      _warehouseController.text = widget.state.warehouseId;
    }
    if (oldWidget.state.status != widget.state.status) {
      _status = widget.state.status;
    }
  }

  @override
  void dispose() {
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReplenishmentSuggestionsBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Status',
            style: AppTypography.labelLarge.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              AppFilterChip(
                label: 'Todas',
                selected: _status == null,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _status = null);
                },
              ),
              for (final status in ReplenishmentSuggestionStatus.values)
                AppFilterChip(
                  label: _statusLabel(status),
                  selected: _status == status,
                  onSelected: (selected) {
                    setState(() => _status = selected ? status : null);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            key: const ValueKey('replenishment_warehouse_filter'),
            controller: _warehouseController,
            label: 'Depósito',
            hintText: 'ID do depósito',
            prefixIcon: const Icon(Icons.warehouse_outlined),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(context),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Aplicar',
            leadingIcon: Icons.check_outlined,
            onPressed: () => _apply(context),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Limpar',
            leadingIcon: Icons.clear_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled:
                !widget.state.hasActiveFilters &&
                _warehouseController.text.isEmpty &&
                _status == null,
            onPressed: () {
              _warehouseController.clear();
              setState(() => _status = null);
              bloc.add(const ReplenishmentSuggestionsFiltersCleared());
            },
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext context) {
    context.read<ReplenishmentSuggestionsBloc>().add(
      ReplenishmentSuggestionsFiltersApplied(
        status: _status,
        warehouseId: _warehouseController.text,
      ),
    );
  }
}

class _AdjustQuantityDialog extends StatefulWidget {
  const _AdjustQuantityDialog({required this.suggestion});

  final ReplenishmentSuggestion suggestion;

  static Future<int?> show(
    BuildContext context, {
    required ReplenishmentSuggestion suggestion,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AdjustQuantityDialog(suggestion: suggestion),
    );
  }

  @override
  State<_AdjustQuantityDialog> createState() => _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends State<_AdjustQuantityDialog> {
  late final TextEditingController _quantityController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.suggestion.suggestedQuantity}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _confirm() {
    final raw = _quantityController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      setState(
        () => _errorText =
            'Informe uma quantidade inteira maior ou igual a zero.',
      );
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.breakpoint == AppBreakpoint.mobile;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.spacing16 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.edit_outlined, color: colors.primary),
                  const SizedBox(width: AppSpacing.spacing12),
                  const Expanded(child: Text('Ajustar quantidade sugerida')),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Sugestão original: ${widget.suggestion.suggestedQuantity} '
                'unidade(s).',
                style: AppTypography.bodyMedium.copyWith(color: colors.outline),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppTextField(
                controller: _quantityController,
                label: 'Quantidade final',
                keyboardType: TextInputType.number,
                semanticLabel: 'Quantidade final ajustada',
                isRequired: true,
                errorText: _errorText,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.spacing12,
                runSpacing: AppSpacing.spacing12,
                children: <Widget>[
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppButton(label: 'Confirmar ajuste', onPressed: _confirm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(ReplenishmentSuggestionStatus status) {
  return switch (status) {
    ReplenishmentSuggestionStatus.suggested => 'Sugerida',
    ReplenishmentSuggestionStatus.insufficientData => 'Dados insuficientes',
    ReplenishmentSuggestionStatus.accepted => 'Aceita',
    ReplenishmentSuggestionStatus.adjusted => 'Ajustada',
    ReplenishmentSuggestionStatus.discarded => 'Descartada',
  };
}

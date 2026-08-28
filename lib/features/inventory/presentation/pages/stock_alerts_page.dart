import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/stock_alert.dart';
import '../../domain/value_objects/stock_alert_level.dart';
import '../../domain/value_objects/stock_alert_transition_type.dart';
import '../bloc/stock_alert_list_bloc.dart';
import '../bloc/stock_alert_list_event.dart';
import '../bloc/stock_alert_list_state.dart';

class StockAlertsPage extends StatelessWidget {
  const StockAlertsPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final StockAlertListBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<StockAlertListBloc>(
          create: (_) => createBloc()
            ..add(
              StockAlertListStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: const _StockAlertsView(),
        );
      },
    );
  }
}

class _StockAlertsView extends StatelessWidget {
  const _StockAlertsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StockAlertListBloc, StockAlertListState>(
        builder: (context, state) {
          final bloc = context.read<StockAlertListBloc>();
          return AppAdminPageLayout(
            title: 'Alertas de ruptura',
            filtersBuilder: (context) => _StockAlertFilters(state: state),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: AppDataTable<StockAlert>(
                      status: _tableStatus(state),
                      rows: state.alerts,
                      rowIdBuilder: (alert) => alert.id,
                      emptyTitle: 'Nenhum alerta de ruptura encontrado',
                      emptyDescription:
                          'Ajuste os filtros ou aguarde uma nova oscilação de estoque.',
                      errorTitle:
                          'Não foi possível carregar os alertas de ruptura',
                      errorMessage:
                          state.loadFailure?.message ??
                          'Tente novamente em breve.',
                      retryLabel: 'Tentar novamente',
                      onRetry: () =>
                          bloc.add(const StockAlertListRefreshRequested()),
                      mobileCardTitleBuilder: (context, alert) =>
                          Text(_levelLabel(alert.level)),
                      columns: <AppDataColumn<StockAlert>>[
                        AppDataColumn(
                          label: 'Severidade',
                          cellBuilder: (context, alert) => Text(
                            '${_levelLabel(alert.level)}\n${_transitionLabel(alert.transitionType)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppDataColumn(
                          label: 'Produto',
                          cellBuilder: (context, alert) =>
                              Text(alert.productId),
                        ),
                        AppDataColumn(
                          label: 'Variante',
                          cellBuilder: (context, alert) =>
                              Text(alert.variantId),
                        ),
                        AppDataColumn(
                          label: 'Unidade',
                          cellBuilder: (context, alert) =>
                              Text(alert.warehouseId),
                        ),
                        AppDataColumn(
                          label: 'Saldo/limite',
                          cellBuilder: (context, alert) => Text(
                            '${alert.sellableQuantity} / ${alert.thresholdQuantity}',
                          ),
                        ),
                        AppDataColumn(
                          label: 'Data/hora',
                          cellBuilder: (context, alert) =>
                              Text(_dateTimeLabel(alert.triggeredAt)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppDataTableStatus _tableStatus(StockAlertListState state) {
    return switch (state.loadStatus) {
      StockAlertListLoadStatus.loading => AppDataTableStatus.loading,
      StockAlertListLoadStatus.failure => AppDataTableStatus.error,
      StockAlertListLoadStatus.ready =>
        state.alerts.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }
}

class _StockAlertFilters extends StatefulWidget {
  const _StockAlertFilters({required this.state});

  final StockAlertListState state;

  @override
  State<_StockAlertFilters> createState() => _StockAlertFiltersState();
}

class _StockAlertFiltersState extends State<_StockAlertFilters> {
  late final TextEditingController _productController;
  late final TextEditingController _warehouseController;
  StockAlertLevel? _level;

  @override
  void initState() {
    super.initState();
    _productController = TextEditingController(text: widget.state.productId);
    _warehouseController = TextEditingController(
      text: widget.state.warehouseId,
    );
    _level = widget.state.level;
  }

  @override
  void didUpdateWidget(covariant _StockAlertFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.productId != widget.state.productId) {
      _productController.text = widget.state.productId;
    }
    if (oldWidget.state.warehouseId != widget.state.warehouseId) {
      _warehouseController.text = widget.state.warehouseId;
    }
    if (oldWidget.state.level != widget.state.level) {
      _level = widget.state.level;
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<StockAlertListBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Severidade',
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
                selected: _level == null,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _level = null);
                },
              ),
              for (final level in StockAlertLevel.values)
                AppFilterChip(
                  label: _levelLabel(level),
                  selected: _level == level,
                  onSelected: (selected) {
                    setState(() => _level = selected ? level : null);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            key: const ValueKey('stock_alert_product_filter'),
            controller: _productController,
            label: 'Produto',
            hintText: 'ID do produto',
            prefixIcon: const Icon(Icons.checkroom_outlined),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            key: const ValueKey('stock_alert_warehouse_filter'),
            controller: _warehouseController,
            label: 'Unidade',
            hintText: 'ID do estoque/unidade',
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
                _productController.text.isEmpty &&
                _warehouseController.text.isEmpty &&
                _level == null,
            onPressed: () {
              _productController.clear();
              _warehouseController.clear();
              setState(() => _level = null);
              bloc.add(const StockAlertListFiltersCleared());
            },
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext context) {
    context.read<StockAlertListBloc>().add(
      StockAlertListFiltersApplied(
        level: _level,
        productId: _productController.text,
        warehouseId: _warehouseController.text,
      ),
    );
  }
}

String _levelLabel(StockAlertLevel level) {
  return switch (level) {
    StockAlertLevel.low => 'Baixo',
    StockAlertLevel.critical => 'Crítico',
  };
}

String _transitionLabel(StockAlertTransitionType type) {
  return switch (type) {
    StockAlertTransitionType.entered => 'Entrou no limite',
    StockAlertTransitionType.escalated => 'Agravou',
    StockAlertTransitionType.deescalated => 'Melhorou parcialmente',
    StockAlertTransitionType.recovered => 'Recuperado',
  };
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

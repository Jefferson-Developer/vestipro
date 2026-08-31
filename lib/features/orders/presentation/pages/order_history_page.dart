import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_duplication_item_issue.dart';
import '../../domain/entities/order_duplication_result.dart';
import '../bloc/order_duplication_cubit.dart';
import '../bloc/order_duplication_state.dart';
import '../bloc/order_history_bloc.dart';
import '../bloc/order_history_event.dart';
import '../bloc/order_history_state.dart';
import '../widgets/order_status_history_timeline.dart';
import 'order_list_page.dart' show OrderStatusBadge;

/// Pedido history/detail screen (TASK-104): the full, read-only status
/// timeline of one Order plus "Repetir pedido", gated by [Capability.orderView]
/// exactly like [OrderListPage] itself — the same read this page's own row
/// action opens from.
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.orderId,
    required this.permissionService,
    required this.createBloc,
    required this.createDuplicationCubit,
    this.onDuplicated,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String orderId;
  final PermissionService permissionService;
  final OrderHistoryBloc Function() createBloc;
  final OrderDuplicationCubit Function() createDuplicationCubit;

  /// Called once "Repetir pedido" successfully creates a new draft — always
  /// navigates into the existing order draft flow (`OrderDraftRoute`,
  /// TASK-096), never a bespoke confirmation screen of its own.
  final ValueChanged<Order>? onDuplicated;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.orderView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return MultiBlocProvider(
          providers: [
            BlocProvider<OrderHistoryBloc>(
              create: (_) => createBloc()
                ..add(
                  OrderHistoryStarted(
                    organizationId: organizationId,
                    companyId: companyId,
                    userId: userId,
                    orderId: orderId,
                  ),
                ),
            ),
            BlocProvider<OrderDuplicationCubit>(
              create: (_) => createDuplicationCubit(),
            ),
          ],
          child: _OrderHistoryPermissionsGate(
            organizationId: organizationId,
            companyId: companyId,
            sellerId: userId,
            permissionService: permissionService,
            onDuplicated: onDuplicated,
          ),
        );
      },
    );
  }
}

class _OrderHistoryPermissionsGate extends StatefulWidget {
  const _OrderHistoryPermissionsGate({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.permissionService,
    this.onDuplicated,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final ValueChanged<Order>? onDuplicated;

  @override
  State<_OrderHistoryPermissionsGate> createState() =>
      _OrderHistoryPermissionsGateState();
}

class _OrderHistoryPermissionsGateState
    extends State<_OrderHistoryPermissionsGate> {
  late final Future<bool> _canDuplicate;

  @override
  void initState() {
    super.initState();
    // "Repetir pedido" creates a brand new order draft — gated by the same
    // `Capability.orderCreate` [OrderDraftRoute] itself requires, never a
    // bespoke capability of its own.
    _canDuplicate = widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.sellerId,
          capability: Capability.orderCreate,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canDuplicate,
      builder: (context, snapshot) {
        return _OrderHistoryScaffold(
          canDuplicate: snapshot.data ?? false,
          organizationId: widget.organizationId,
          companyId: widget.companyId,
          sellerId: widget.sellerId,
          onDuplicated: widget.onDuplicated,
        );
      },
    );
  }
}

class _OrderHistoryScaffold extends StatelessWidget {
  const _OrderHistoryScaffold({
    required this.canDuplicate,
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    this.onDuplicated,
  });

  final bool canDuplicate;
  final String organizationId;
  final String companyId;
  final String sellerId;
  final ValueChanged<Order>? onDuplicated;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDuplicationCubit, OrderDuplicationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _handleDuplicationChange(context, state),
      builder: (context, duplicationState) {
        return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
          builder: (context, historyState) {
            final order = historyState.order;
            final canSubmitDuplicate =
                canDuplicate &&
                order != null &&
                order.items.isNotEmpty &&
                duplicationState.status != OrderDuplicationStatus.submitting;

            return Scaffold(
              body: AppAdminPageLayout(
                title: order == null || order.orderNumber == null
                    ? 'Histórico do pedido'
                    : 'Histórico do pedido ${order.orderNumber}',
                actions: <Widget>[
                  AppButton(
                    label: 'Repetir pedido',
                    leadingIcon: Icons.content_copy_outlined,
                    isLoading:
                        duplicationState.status ==
                        OrderDuplicationStatus.submitting,
                    isDisabled: !canSubmitDuplicate,
                    onPressed: !canSubmitDuplicate
                        ? null
                        : () => context.read<OrderDuplicationCubit>().duplicate(
                            organizationId: organizationId,
                            companyId: companyId,
                            sellerId: sellerId,
                            sourceOrderId: order.id,
                          ),
                  ),
                ],
                content: _OrderHistoryContent(state: historyState),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDuplicationChange(
    BuildContext context,
    OrderDuplicationState state,
  ) async {
    switch (state.status) {
      case OrderDuplicationStatus.success:
        final result = state.result;
        if (result == null) return;
        if (result.hasWarnings) {
          await _OrderDuplicationSummaryDialog.show(context, result: result);
        }
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          message: result.sourceOrderNumber == null
              ? 'Novo rascunho criado a partir deste pedido.'
              : 'Novo rascunho criado a partir do pedido '
                    '${result.sourceOrderNumber}.',
          variant: AppSnackbarVariant.success,
        );
        onDuplicated?.call(result.draft);
      case OrderDuplicationStatus.failure:
        AppSnackbar.show(
          context,
          message:
              state.failure?.message ?? 'Não foi possível repetir este pedido.',
          variant: AppSnackbarVariant.error,
        );
      case OrderDuplicationStatus.idle:
      case OrderDuplicationStatus.submitting:
        break;
    }
  }
}

class _OrderHistoryContent extends StatelessWidget {
  const _OrderHistoryContent({required this.state});

  final OrderHistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == OrderHistoryLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar o histórico do pedido',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () =>
            context.read<OrderHistoryBloc>().add(const OrderHistoryRetried()),
      );
    }
    if (state.isLoading || state.order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final order = state.order!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _OrderHistorySummaryCard(order: order),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Linha do tempo',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          OrderStatusHistoryTimeline(entries: order.statusHistory),
        ],
      ),
    );
  }
}

class _OrderHistorySummaryCard extends StatelessWidget {
  const _OrderHistorySummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Cliente ${order.customerId}',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Vendedor ${order.sellerId} • ${order.itemCount} '
            'ite${order.itemCount == 1 ? 'm' : 'ns'}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          if (order.duplicatedFromOrderId != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Duplicado do pedido '
              '${order.duplicatedFromOrderNumber ?? order.duplicatedFromOrderId}',
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderDuplicationSummaryDialog extends StatelessWidget {
  const _OrderDuplicationSummaryDialog({required this.result});

  final OrderDuplicationResult result;

  static Future<void> show(
    BuildContext context, {
    required OrderDuplicationResult result,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _OrderDuplicationSummaryDialog(result: result),
    );
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
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline, color: colors.warning),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'Revise o novo rascunho antes de continuar',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              if (result.hasIssues) ...<Widget>[
                Text(
                  'Estes itens não foram copiados:',
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                for (final issue in result.issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
                    child: Text(
                      '• ${issue.productId} (${issue.requestedQuantity} un.) — '
                      '${_issueLabel(issue.type)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.spacing16),
              ],
              if (result.hasPriceChanges) ...<Widget>[
                Text(
                  'O preço destes itens mudou desde o pedido original:',
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                for (final change in result.priceChanges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
                    child: Text(
                      '• ${change.productId}: '
                      '${_formatCurrency(change.previousUnitPrice)} → '
                      '${_formatCurrency(change.newUnitPrice)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                alignment: WrapAlignment.end,
                children: <Widget>[
                  AppButton(
                    label: 'Entendi',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _issueLabel(OrderDuplicationItemIssueType type) {
    return switch (type) {
      OrderDuplicationItemIssueType.discontinued => 'produto descontinuado',
      OrderDuplicationItemIssueType.unavailable => 'sem disponibilidade',
      OrderDuplicationItemIssueType.priceUnavailable => 'sem preço vigente',
    };
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_approval_decision.dart';
import '../bloc/order_approval_queue_bloc.dart';
import '../bloc/order_approval_queue_event.dart';
import '../bloc/order_approval_queue_state.dart';

/// Fila de aprovação (TASK-103): every pedido routed to `underReview`
/// (`submitOrder`'s own approval routing, TASK-101) this caller may decide —
/// gated by [Capability.orderApprove], granted today to exactly OWNER/ADMIN/
/// SALES_MANAGER (`RolePermissionMatrix`). Decisions themselves are never
/// authorized here: [OrderApprovalQueueBloc] only ever calls
/// `DecideOrderApprovalUseCase`, which re-validates the very same capability
/// and calls `decideOrderApproval` — the sole place a decision is actually
/// persisted, server-side.
class OrderApprovalQueuePage extends StatelessWidget {
  const OrderApprovalQueuePage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final OrderApprovalQueueBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.orderApprove,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<OrderApprovalQueueBloc>(
          create: (_) => createBloc()
            ..add(
              OrderApprovalQueueStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            ),
          child: const _OrderApprovalQueueScaffold(),
        );
      },
    );
  }
}

class _OrderApprovalQueueScaffold extends StatelessWidget {
  const _OrderApprovalQueueScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderApprovalQueueBloc, OrderApprovalQueueState>(
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
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Fila de aprovação',
            content: _OrderApprovalQueueContent(state: state),
          ),
        );
      },
    );
  }
}

class _OrderApprovalQueueContent extends StatelessWidget {
  const _OrderApprovalQueueContent({required this.state});

  final OrderApprovalQueueState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderApprovalQueueBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Pedidos com desconto ou condição acima da política do vendedor '
            'aguardando sua decisão.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDataTable<Order>(
            status: _tableStatus(state),
            rows: state.orders,
            rowIdBuilder: (order) => order.id,
            emptyTitle: 'Nenhum pedido aguardando aprovação',
            emptyDescription:
                'Pedidos encaminhados para aprovação aparecerão aqui.',
            errorTitle: 'Não foi possível carregar a fila de aprovação',
            errorMessage: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () => bloc.add(const OrderApprovalQueueRefreshRequested()),
            mobileCardTitleBuilder: (context, order) =>
                Text(order.orderNumber ?? order.id),
            columns: <AppDataColumn<Order>>[
              AppDataColumn(
                label: 'Nº do pedido',
                cellBuilder: (context, order) => Text(order.orderNumber ?? '—'),
              ),
              AppDataColumn(
                label: 'Cliente',
                cellBuilder: (context, order) => Text(order.customerId),
              ),
              AppDataColumn(
                label: 'Vendedor',
                cellBuilder: (context, order) => Text(order.sellerId),
              ),
              AppDataColumn(
                label: 'Motivo do encaminhamento',
                cellBuilder: (context, order) =>
                    Text(order.approvalReason ?? '—'),
              ),
              AppDataColumn(
                label: 'Enviado em',
                cellBuilder: (context, order) =>
                    Text(_dateTimeLabel(order.createdAt)),
              ),
            ],
            rowActions: <AppDataTableAction<Order>>[
              AppDataTableAction<Order>(
                icon: Icons.check_circle_outline,
                semanticLabel: 'Aprovar pedido',
                onPressed: (order) => _approve(context, order, state),
              ),
              AppDataTableAction<Order>(
                icon: Icons.cancel_outlined,
                semanticLabel: 'Rejeitar pedido',
                onPressed: (order) => _reject(context, order, state),
              ),
            ],
          ),
          if (state.loadStatus == OrderApprovalQueueLoadStatus.ready) ...[
            const SizedBox(height: AppSpacing.spacing8),
            AppPagination(
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () =>
                  bloc.add(const OrderApprovalQueueNextPageRequested()),
            ),
          ],
        ],
      ),
    );
  }

  AppDataTableStatus _tableStatus(OrderApprovalQueueState state) {
    return switch (state.loadStatus) {
      OrderApprovalQueueLoadStatus.initial ||
      OrderApprovalQueueLoadStatus.loading => AppDataTableStatus.loading,
      OrderApprovalQueueLoadStatus.failure => AppDataTableStatus.error,
      OrderApprovalQueueLoadStatus.ready ||
      OrderApprovalQueueLoadStatus.loadingMore =>
        state.orders.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  Future<void> _approve(
    BuildContext context,
    Order order,
    OrderApprovalQueueState state,
  ) async {
    if (state.decidingOrderId != null) return;
    final bloc = context.read<OrderApprovalQueueBloc>();
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Aprovar pedido ${order.orderNumber ?? order.id}?',
      message:
          'O pedido segue para processamento normalmente após a aprovação.',
      confirmLabel: 'Aprovar',
    );
    if (!confirmed) return;
    bloc.add(
      OrderApprovalQueueDecided(
        orderId: order.id,
        decision: OrderApprovalDecisionValue.approved,
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    Order order,
    OrderApprovalQueueState state,
  ) async {
    if (state.decidingOrderId != null) return;
    final bloc = context.read<OrderApprovalQueueBloc>();
    final reason = await _RejectReasonDialog.show(context, order: order);
    if (reason == null) return;
    bloc.add(
      OrderApprovalQueueDecided(
        orderId: order.id,
        decision: OrderApprovalDecisionValue.rejected,
        reason: reason,
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.order});

  final Order order;

  static Future<String?> show(BuildContext context, {required Order order}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RejectReasonDialog(order: order),
    );
  }

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Informe o motivo da rejeição.');
      return;
    }
    Navigator.of(context).pop(reason);
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
                  Icon(Icons.cancel_outlined, color: colors.error),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'Rejeitar pedido ${widget.order.orderNumber ?? widget.order.id}?',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppTextField(
                controller: _reasonController,
                label: 'Motivo',
                hintText: 'Ex.: Desconto incompatível com a política',
                semanticLabel: 'Motivo da rejeição',
                isRequired: true,
                errorText: _errorText,
                maxLines: 3,
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
                  AppButton(
                    label: 'Rejeitar',
                    variant: AppButtonVariant.destructive,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

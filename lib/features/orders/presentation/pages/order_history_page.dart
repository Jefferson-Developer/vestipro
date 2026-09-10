import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_duplication_item_issue.dart';
import '../../domain/entities/order_duplication_result.dart';
import '../../domain/entities/order_signature.dart';
import '../../domain/services/order_receipt_pdf_encoder.dart';
import '../../domain/usecases/capture_order_signature_use_case.dart'
    show kSignableOrderStatuses;
import '../../domain/value_objects/order_status.dart';
import '../../../exchanges/exchanges.dart';
import '../../../returns/returns.dart';
import '../bloc/order_duplication_cubit.dart';
import '../bloc/order_duplication_state.dart';
import '../bloc/order_history_bloc.dart';
import '../bloc/order_history_event.dart';
import '../bloc/order_history_state.dart';
import '../bloc/order_signature_cubit.dart';
import '../bloc/order_signature_state.dart';
import '../widgets/order_status_history_timeline.dart';
import 'order_list_page.dart' show OrderStatusBadge;
import 'order_receipt_preview_page.dart';
import 'order_signature_capture_page.dart';

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
    required this.createSignatureCubit,
    required this.createReturnRequestHistoryCubit,
    required this.createReturnRequestFormCubit,
    required this.createExchangeRequestHistoryCubit,
    required this.createExchangeRequestFormCubit,
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

  /// Builds the single `OrderSignatureCubit` behind "Assinar pedido"/"Ver
  /// comprovante" (TASK-180) — shared as-is with the pushed
  /// `OrderSignatureCapturePage` (`BlocProvider.value`), same factory-per-use
  /// convention as [createDuplicationCubit].
  final OrderSignatureCubit Function() createSignatureCubit;

  /// Feeds the "Devoluções" history section (TASK-199, EPIC-30) embedded in
  /// this same screen.
  final ReturnRequestHistoryCubit Function() createReturnRequestHistoryCubit;

  /// Builds a fresh `ReturnRequestFormCubit` every time "Solicitar
  /// devolução" is pushed (TASK-199) — a brand new devolução intent (and
  /// idempotency key) each time, same one-cubit-per-push convention
  /// [createDuplicationCubit] already sets.
  final ReturnRequestFormCubit Function() createReturnRequestFormCubit;

  /// Feeds the "Trocas" history section (TASK-200, EPIC-30) embedded in
  /// this same screen.
  final ExchangeRequestHistoryCubit Function()
  createExchangeRequestHistoryCubit;

  /// Builds a fresh `ExchangeRequestFormCubit` every time "Solicitar troca"
  /// is pushed (TASK-200) — a brand new troca intent (and idempotency key)
  /// each time, same one-cubit-per-push convention [createDuplicationCubit]
  /// already sets.
  final ExchangeRequestFormCubit Function() createExchangeRequestFormCubit;

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
            BlocProvider<OrderSignatureCubit>(
              create: (_) {
                final cubit = createSignatureCubit();
                unawaited(
                  cubit.loadForOrder(
                    organizationId: organizationId,
                    companyId: companyId,
                    orderId: orderId,
                  ),
                );
                return cubit;
              },
            ),
          ],
          child: _OrderHistoryPermissionsGate(
            organizationId: organizationId,
            companyId: companyId,
            sellerId: userId,
            permissionService: permissionService,
            createReturnRequestHistoryCubit: createReturnRequestHistoryCubit,
            createReturnRequestFormCubit: createReturnRequestFormCubit,
            createExchangeRequestHistoryCubit:
                createExchangeRequestHistoryCubit,
            createExchangeRequestFormCubit: createExchangeRequestFormCubit,
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
    required this.createReturnRequestHistoryCubit,
    required this.createReturnRequestFormCubit,
    required this.createExchangeRequestHistoryCubit,
    required this.createExchangeRequestFormCubit,
    this.onDuplicated,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final ReturnRequestHistoryCubit Function() createReturnRequestHistoryCubit;
  final ReturnRequestFormCubit Function() createReturnRequestFormCubit;
  final ExchangeRequestHistoryCubit Function()
  createExchangeRequestHistoryCubit;
  final ExchangeRequestFormCubit Function() createExchangeRequestFormCubit;
  final ValueChanged<Order>? onDuplicated;

  @override
  State<_OrderHistoryPermissionsGate> createState() =>
      _OrderHistoryPermissionsGateState();
}

class _OrderHistoryPermissionsGateState
    extends State<_OrderHistoryPermissionsGate> {
  late final Future<bool> _canDuplicate;
  late final Future<bool> _canRequestReturn;
  late final Future<bool> _canRequestExchange;

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
    // "Solicitar devolução" (TASK-199, EPIC-30) — gated by
    // `Capability.returnRequestCreate`; `createReturnRequest` (Cloud
    // Function) remains the real, independent source of truth for both this
    // capability and the seller/pedido-ownership scope.
    _canRequestReturn = widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.sellerId,
          capability: Capability.returnRequestCreate,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
    // "Solicitar troca" (TASK-200, EPIC-30) — gated by
    // `Capability.exchangeRequestCreate`; `createExchangeRequest` (Cloud
    // Function) remains the real, independent source of truth for both this
    // capability and the seller/pedido-ownership scope.
    _canRequestExchange = widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.sellerId,
          capability: Capability.exchangeRequestCreate,
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
      builder: (context, duplicateSnapshot) {
        return FutureBuilder<bool>(
          future: _canRequestReturn,
          builder: (context, returnSnapshot) {
            return FutureBuilder<bool>(
              future: _canRequestExchange,
              builder: (context, exchangeSnapshot) {
                return _OrderHistoryScaffold(
                  canDuplicate: duplicateSnapshot.data ?? false,
                  canRequestReturn: returnSnapshot.data ?? false,
                  canRequestExchange: exchangeSnapshot.data ?? false,
                  organizationId: widget.organizationId,
                  companyId: widget.companyId,
                  sellerId: widget.sellerId,
                  createReturnRequestHistoryCubit:
                      widget.createReturnRequestHistoryCubit,
                  createReturnRequestFormCubit:
                      widget.createReturnRequestFormCubit,
                  createExchangeRequestHistoryCubit:
                      widget.createExchangeRequestHistoryCubit,
                  createExchangeRequestFormCubit:
                      widget.createExchangeRequestFormCubit,
                  onDuplicated: widget.onDuplicated,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OrderHistoryScaffold extends StatelessWidget {
  const _OrderHistoryScaffold({
    required this.canDuplicate,
    required this.canRequestReturn,
    required this.canRequestExchange,
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.createReturnRequestHistoryCubit,
    required this.createReturnRequestFormCubit,
    required this.createExchangeRequestHistoryCubit,
    required this.createExchangeRequestFormCubit,
    this.onDuplicated,
  });

  final bool canDuplicate;
  final bool canRequestReturn;
  final bool canRequestExchange;
  final String organizationId;
  final String companyId;
  final String sellerId;
  final ReturnRequestHistoryCubit Function() createReturnRequestHistoryCubit;
  final ReturnRequestFormCubit Function() createReturnRequestFormCubit;
  final ExchangeRequestHistoryCubit Function()
  createExchangeRequestHistoryCubit;
  final ExchangeRequestFormCubit Function() createExchangeRequestFormCubit;
  final ValueChanged<Order>? onDuplicated;

  /// Pedido statuses a devolução — ou uma troca (TASK-200, EPIC-30) — may be
  /// requested against: mirrors exactly which `OrderStatus` values
  /// `OrderStatusTransitionValidator` accepts a transition into
  /// `returned`/`partiallyReturned` from. A troca reaproveita a mesma janela
  /// de elegibilidade da devolução (`tasks.md`: "reaproveitando a base de
  /// devoluções") — nunca altera o `status` do pedido em si, apenas o
  /// mesmo pedido já faturado/expedido/entregue precisa existir para que
  /// uma variante já entregue possa ser trocada.
  static const _returnEligibleStatuses = <OrderStatus>{
    OrderStatus.invoiced,
    OrderStatus.partiallyInvoiced,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.partiallyReturned,
  };

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

            return BlocConsumer<OrderSignatureCubit, OrderSignatureState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status,
              listener: (context, signatureState) =>
                  _handleSignatureChange(context, signatureState),
              builder: (context, signatureState) {
                final canSign =
                    canDuplicate &&
                    order != null &&
                    kSignableOrderStatuses.contains(order.status) &&
                    !signatureState.hasValidSignature &&
                    signatureState.status !=
                        OrderSignatureFlowStatus.capturing &&
                    signatureState.status != OrderSignatureFlowStatus.syncing;
                final canViewReceipt = order?.orderNumber != null;
                final canSubmitReturnRequest =
                    canRequestReturn &&
                    order != null &&
                    _returnEligibleStatuses.contains(order.status);
                final canSubmitExchangeRequest =
                    canRequestExchange &&
                    order != null &&
                    _returnEligibleStatuses.contains(order.status);

                return Scaffold(
                  body: AppAdminPageLayout(
                    title: order == null || order.orderNumber == null
                        ? 'Histórico do pedido'
                        : 'Histórico do pedido ${order.orderNumber}',
                    actions: <Widget>[
                      if (canSubmitReturnRequest)
                        AppButton(
                          label: 'Solicitar devolução',
                          leadingIcon: Icons.keyboard_return_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _requestReturn(
                            context,
                            organizationId: organizationId,
                            companyId: companyId,
                            userId: sellerId,
                            order: order,
                          ),
                        ),
                      if (canSubmitExchangeRequest)
                        AppButton(
                          label: 'Solicitar troca',
                          leadingIcon: Icons.swap_horiz_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _requestExchange(
                            context,
                            organizationId: organizationId,
                            companyId: companyId,
                            userId: sellerId,
                            order: order,
                          ),
                        ),
                      if (canViewReceipt)
                        AppButton(
                          label: 'Ver comprovante',
                          leadingIcon: Icons.receipt_long_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _viewReceipt(
                            context,
                            order: order!,
                            signature: signatureState.signature,
                          ),
                        ),
                      AppButton(
                        label: signatureState.hasValidSignature
                            ? 'Pedido assinado'
                            : 'Assinar pedido',
                        leadingIcon: Icons.draw_outlined,
                        isDisabled: !canSign,
                        onPressed: !canSign
                            ? null
                            : () => _signOrder(context, order, sellerId),
                      ),
                      AppButton(
                        label: 'Repetir pedido',
                        leadingIcon: Icons.content_copy_outlined,
                        isLoading:
                            duplicationState.status ==
                            OrderDuplicationStatus.submitting,
                        isDisabled: !canSubmitDuplicate,
                        onPressed: !canSubmitDuplicate
                            ? null
                            : () => context
                                  .read<OrderDuplicationCubit>()
                                  .duplicate(
                                    organizationId: organizationId,
                                    companyId: companyId,
                                    sellerId: sellerId,
                                    sourceOrderId: order.id,
                                  ),
                      ),
                    ],
                    content: _OrderHistoryContent(
                      state: historyState,
                      organizationId: organizationId,
                      createReturnRequestHistoryCubit:
                          createReturnRequestHistoryCubit,
                      createExchangeRequestHistoryCubit:
                          createExchangeRequestHistoryCubit,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _requestReturn(
    BuildContext context, {
    required String organizationId,
    required String companyId,
    required String userId,
    required Order order,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReturnRequestFormPage(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          order: order,
          createCubit: createReturnRequestFormCubit,
        ),
      ),
    );
  }

  Future<void> _requestExchange(
    BuildContext context, {
    required String organizationId,
    required String companyId,
    required String userId,
    required Order order,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExchangeRequestFormPage(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          order: order,
          createCubit: createExchangeRequestFormCubit,
        ),
      ),
    );
  }

  void _handleSignatureChange(BuildContext context, OrderSignatureState state) {
    if (state.status == OrderSignatureFlowStatus.failure) {
      AppSnackbar.show(
        context,
        message:
            state.failure?.message ??
            'Não foi possível processar a assinatura do pedido.',
        variant: AppSnackbarVariant.error,
      );
    }
  }

  Future<void> _signOrder(
    BuildContext context,
    Order order,
    String sellerId,
  ) async {
    final cubit = context.read<OrderSignatureCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<OrderSignatureCubit>.value(
          value: cubit,
          child: OrderSignatureCapturePage(
            order: order,
            signedByUserId: sellerId,
          ),
        ),
      ),
    );
  }

  Future<void> _viewReceipt(
    BuildContext context, {
    required Order order,
    required OrderSignature? signature,
  }) async {
    final cubit = context.read<OrderSignatureCubit>();
    await cubit.logReceiptViewed(
      organizationId: organizationId,
      companyId: companyId,
      orderId: order.id,
    );
    final bytes = await const OrderReceiptPdfEncoder().encodeToBytes(
      order: order,
      signature: signature,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderReceiptPreviewPage(
          bytes: bytes,
          fileName: 'Comprovante ${order.orderNumber}',
        ),
      ),
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
  const _OrderHistoryContent({
    required this.state,
    required this.organizationId,
    required this.createReturnRequestHistoryCubit,
    required this.createExchangeRequestHistoryCubit,
  });

  final OrderHistoryState state;
  final String organizationId;
  final ReturnRequestHistoryCubit Function() createReturnRequestHistoryCubit;
  final ExchangeRequestHistoryCubit Function()
  createExchangeRequestHistoryCubit;

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
          const SizedBox(height: AppSpacing.spacing24),
          ReturnRequestHistorySection(
            organizationId: organizationId,
            orderId: order.id,
            createCubit: createReturnRequestHistoryCubit,
          ),
          const SizedBox(height: AppSpacing.spacing24),
          ExchangeRequestHistorySection(
            organizationId: organizationId,
            orderId: order.id,
            createCubit: createExchangeRequestHistoryCubit,
          ),
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
                      '${_formatCurrency(change.previousUnitPrice, result.draft.currency)} → '
                      '${_formatCurrency(change.newUnitPrice, result.draft.currency)}',
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

  String _formatCurrency(double value, String currency) {
    return CurrencyFormatter.formatWithCode(value, currency);
  }
}

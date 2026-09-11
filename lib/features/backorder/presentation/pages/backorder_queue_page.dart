import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/backorder_request.dart';
import '../../domain/value_objects/backorder_status.dart';
import '../cubit/backorder_queue_cubit.dart';
import '../cubit/backorder_queue_state.dart';

/// Fila de atendimento de backorder (TASK-215, EPIC-32) — lista, priorizada,
/// toda demanda registrada por ruptura de estoque (`BackorderQueueCubit`),
/// além de um inbox separado de solicitações aguardando aprovação para quem
/// possui [Capability.backorderApprove]. Nunca acessa Firestore diretamente
/// (`AGENTS.md`) — toda ação passa pelo Cubit/use cases/Cloud Functions.
class BackorderQueuePage extends StatelessWidget {
  const BackorderQueuePage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final BackorderQueueCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.backorderRequest,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<BackorderQueueCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(cubit.watch(organizationId: organizationId));
            return cubit;
          },
          child: _BackorderQueueView(
            organizationId: organizationId,
            userId: userId,
            permissionService: permissionService,
          ),
        );
      },
    );
  }
}

class _BackorderQueueView extends StatelessWidget {
  const _BackorderQueueView({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backorders / estoque futuro')),
      body: BlocConsumer<BackorderQueueCubit, BackorderQueueState>(
        listenWhen: (previous, current) =>
            previous.actionFailureMessage != current.actionFailureMessage &&
            current.actionFailureMessage != null,
        listener: (context, state) {
          final message = state.actionFailureMessage;
          if (message == null) return;
          AppSnackbar.show(
            context,
            message: message,
            variant: AppSnackbarVariant.error,
          );
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PermissionBuilder(
                  permissionService: permissionService,
                  organizationId: organizationId,
                  userId: userId,
                  capability: Capability.backorderApprove,
                  builder: (context, canApprove) {
                    if (!canApprove || state.awaitingApproval.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Aguardando aprovação',
                          style: AppTypography.labelLarge.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing8),
                        for (final backorder in state.awaitingApproval)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.spacing12,
                            ),
                            child: _BackorderCard(
                              backorder: backorder,
                              isProcessing:
                                  state.processingBackorderId == backorder.id,
                              onApprove: () =>
                                  context.read<BackorderQueueCubit>().decide(
                                    backorderId: backorder.id,
                                    approve: true,
                                  ),
                              onReject: () =>
                                  context.read<BackorderQueueCubit>().decide(
                                    backorderId: backorder.id,
                                    approve: false,
                                  ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.spacing24),
                      ],
                    );
                  },
                ),
                Text(
                  'Fila de atendimento',
                  style: AppTypography.labelLarge.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.spacing24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.queue.isEmpty)
                  Text(
                    'Nenhum backorder na fila de atendimento.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.colors.outline,
                    ),
                  )
                else
                  for (final backorder in state.queue)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.spacing12,
                      ),
                      child: _BackorderCard(
                        backorder: backorder,
                        isProcessing:
                            state.processingBackorderId == backorder.id,
                        onCancel: () => context
                            .read<BackorderQueueCubit>()
                            .cancel(backorderId: backorder.id),
                        onConvert:
                            backorder.status == BackorderStatus.readyToFulfill
                            ? () => _promptConvert(context, backorder)
                            : null,
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _promptConvert(
    BuildContext context,
    BackorderRequest backorder,
  ) async {
    final cubit = context.read<BackorderQueueCubit>();
    final controller = TextEditingController();
    final orderId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Converter em pedido'),
        content: AppTextField(
          controller: controller,
          label: 'ID do pedido já enviado',
          hintText: 'Informe o pedido que cobre esta quantidade',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          AppButton(
            label: 'Converter',
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          ),
        ],
      ),
    );
    if (orderId == null || orderId.trim().isEmpty) return;
    unawaited(
      cubit.convert(backorderId: backorder.id, orderId: orderId.trim()),
    );
  }
}

class _BackorderCard extends StatelessWidget {
  const _BackorderCard({
    required this.backorder,
    required this.isProcessing,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onConvert,
  });

  final BackorderRequest backorder;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
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
                  'Cliente ${backorder.customerId}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppStatusBadge(
                label: backorder.status.label,
                variant: _variantFor(backorder.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Produto ${backorder.productId} · Variante ${backorder.variantId}'
            '${backorder.sku != null ? ' · SKU ${backorder.sku}' : ''}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          Text(
            'Pendente: ${backorder.remainingQuantity} de ${backorder.quantity}'
            ' · Prioridade: ${backorder.priority.label}'
            ' · Origem: ${backorder.origin.label}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          if (backorder.expectedAvailabilityDate != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing4),
              child: Text(
                'Estoque sinalizado disponível — previsão, não é reserva '
                'confirmada. Revalide antes de converter.',
                style: AppTypography.bodySmall.copyWith(color: colors.info),
              ),
            ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              if (onApprove != null)
                AppButton(
                  label: 'Aprovar',
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onApprove,
                ),
              if (onReject != null)
                AppButton(
                  label: 'Recusar',
                  variant: AppButtonVariant.secondary,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onReject,
                ),
              if (onConvert != null)
                AppButton(
                  label: 'Converter em pedido',
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onConvert,
                ),
              if (onCancel != null)
                AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.text,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onCancel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  AppStatusBadgeVariant _variantFor(BackorderStatus status) {
    return switch (status) {
      BackorderStatus.converted => AppStatusBadgeVariant.success,
      BackorderStatus.readyToFulfill => AppStatusBadgeVariant.info,
      BackorderStatus.rejected ||
      BackorderStatus.cancelled => AppStatusBadgeVariant.neutral,
      BackorderStatus.awaitingApproval => AppStatusBadgeVariant.warning,
      BackorderStatus.queued ||
      BackorderStatus.requested => AppStatusBadgeVariant.info,
    };
  }
}

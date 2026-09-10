import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/exchange_request.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../cubit/exchange_request_queue_cubit.dart';
import '../cubit/exchange_request_queue_state.dart';

/// Fila de análise de trocas (TASK-200, EPIC-30) — toda `ExchangeRequest`
/// ainda `requested` visível ao caller (mesmo escopo de
/// `OrderVisibilityService`, TASK-102), com ação de aprovar/recusar. Gated
/// por [Capability.exchangeRequestApprove] — nunca alcançável por quem só
/// pode solicitar ([Capability.exchangeRequestCreate]).
class ExchangeRequestAnalysisPage extends StatelessWidget {
  const ExchangeRequestAnalysisPage({
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
  final ExchangeRequestQueueCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.exchangeRequestApprove,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ExchangeRequestQueueCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.watch(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            );
            return cubit;
          },
          child: const _ExchangeRequestAnalysisView(),
        );
      },
    );
  }
}

class _ExchangeRequestAnalysisView extends StatelessWidget {
  const _ExchangeRequestAnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExchangeRequestQueueCubit, ExchangeRequestQueueState>(
      listenWhen: (previous, current) =>
          previous.decisionStatus != current.decisionStatus,
      listener: (context, state) {
        if (state.decisionStatus == ExchangeRequestDecisionStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Decisão registrada.',
            variant: AppSnackbarVariant.success,
          );
        } else if (state.decisionStatus ==
            ExchangeRequestDecisionStatus.failure) {
          AppSnackbar.show(
            context,
            message:
                state.decisionFailureMessage ??
                'Não foi possível registrar a decisão.',
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Trocas pendentes',
            content: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExchangeRequestQueueState state) {
    switch (state.status) {
      case ExchangeRequestQueueStatus.initial:
      case ExchangeRequestQueueStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ExchangeRequestQueueStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar as trocas pendentes',
          message: state.failureMessage ?? 'Tente novamente em breve.',
        );
      case ExchangeRequestQueueStatus.empty:
        return const AppEmptyState(
          title: 'Nenhuma troca pendente',
          description: 'Novas solicitações de troca aparecem aqui.',
          icon: Icons.swap_horiz_outlined,
        );
      case ExchangeRequestQueueStatus.ready:
        return ListView.separated(
          itemCount: state.exchangeRequests.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.spacing12),
          itemBuilder: (context, index) => _ExchangeRequestCard(
            exchangeRequest: state.exchangeRequests[index],
            isDeciding:
                state.decisionStatus ==
                    ExchangeRequestDecisionStatus.deciding &&
                state.decidingExchangeRequestId ==
                    state.exchangeRequests[index].id,
          ),
        );
    }
  }
}

class _ExchangeRequestCard extends StatelessWidget {
  const _ExchangeRequestCard({
    required this.exchangeRequest,
    required this.isDeciding,
  });

  final ExchangeRequest exchangeRequest;
  final bool isDeciding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<ExchangeRequestQueueCubit>();

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
          Text(
            'Pedido ${exchangeRequest.orderNumber ?? exchangeRequest.orderId}',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Motivo: ${exchangeRequest.reasonCategory.label}',
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
          if (exchangeRequest.reasonDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing4),
              child: Text(
                exchangeRequest.reasonDetails!,
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ),
          const SizedBox(height: AppSpacing.spacing8),
          for (final item in exchangeRequest.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'De ${item.originVariantId} para ${item.destinationVariantId} '
                      '(${item.quantity} un.)',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              AppButton(
                label: 'Recusar',
                variant: AppButtonVariant.secondary,
                isDisabled: isDeciding,
                onPressed: () => _reject(context, cubit),
              ),
              const SizedBox(width: AppSpacing.spacing8),
              AppButton(
                label: 'Aprovar',
                isLoading: isDeciding,
                isDisabled: isDeciding,
                onPressed: () => cubit.decide(
                  exchangeRequest: exchangeRequest,
                  decision: ExchangeRequestDecisionValue.approved,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    ExchangeRequestQueueCubit cubit,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recusar troca'),
        content: AppTextField(
          controller: reasonController,
          label: 'Motivo da recusa',
          isRequired: true,
          maxLines: 3,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await cubit.decide(
      exchangeRequest: exchangeRequest,
      decision: ExchangeRequestDecisionValue.rejected,
      reason: reason,
    );
  }
}

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/return_request.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../cubit/return_request_queue_cubit.dart';
import '../cubit/return_request_queue_state.dart';

/// Fila de análise de devoluções (TASK-199, EPIC-30) — toda `ReturnRequest`
/// ainda `requested` visível ao caller (mesmo escopo de `OrderVisibilityService`,
/// TASK-102), com ação de aprovar/recusar. Gated por
/// [Capability.returnRequestApprove] — nunca alcançável por quem só pode
/// solicitar ([Capability.returnRequestCreate]).
class ReturnRequestAnalysisPage extends StatelessWidget {
  const ReturnRequestAnalysisPage({
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
  final ReturnRequestQueueCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.returnRequestApprove,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ReturnRequestQueueCubit>(
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
          child: const _ReturnRequestAnalysisView(),
        );
      },
    );
  }
}

class _ReturnRequestAnalysisView extends StatelessWidget {
  const _ReturnRequestAnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReturnRequestQueueCubit, ReturnRequestQueueState>(
      listenWhen: (previous, current) =>
          previous.decisionStatus != current.decisionStatus,
      listener: (context, state) {
        if (state.decisionStatus == ReturnRequestDecisionStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Decisão registrada.',
            variant: AppSnackbarVariant.success,
          );
        } else if (state.decisionStatus ==
            ReturnRequestDecisionStatus.failure) {
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
            title: 'Devoluções pendentes',
            content: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ReturnRequestQueueState state) {
    switch (state.status) {
      case ReturnRequestQueueStatus.initial:
      case ReturnRequestQueueStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ReturnRequestQueueStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar as devoluções pendentes',
          message: state.failureMessage ?? 'Tente novamente em breve.',
        );
      case ReturnRequestQueueStatus.empty:
        return const AppEmptyState(
          title: 'Nenhuma devolução pendente',
          description: 'Novas solicitações de devolução aparecem aqui.',
          icon: Icons.keyboard_return_outlined,
        );
      case ReturnRequestQueueStatus.ready:
        return ListView.separated(
          itemCount: state.returnRequests.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.spacing12),
          itemBuilder: (context, index) => _ReturnRequestCard(
            returnRequest: state.returnRequests[index],
            isDeciding:
                state.decisionStatus == ReturnRequestDecisionStatus.deciding &&
                state.decidingReturnRequestId == state.returnRequests[index].id,
          ),
        );
    }
  }
}

class _ReturnRequestCard extends StatelessWidget {
  const _ReturnRequestCard({
    required this.returnRequest,
    required this.isDeciding,
  });

  final ReturnRequest returnRequest;
  final bool isDeciding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<ReturnRequestQueueCubit>();

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
            'Pedido ${returnRequest.orderNumber ?? returnRequest.orderId}',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Motivo: ${returnRequest.reasonCategory.label}',
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
          if (returnRequest.reasonDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing4),
              child: Text(
                returnRequest.reasonDetails!,
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            '${returnRequest.totalRequestedQuantity} '
            'ite${returnRequest.totalRequestedQuantity == 1 ? 'm' : 'ns'} • '
            '${CurrencyFormatter.formatWithCode(returnRequest.refundAmount, returnRequest.currency)}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
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
                  returnRequest: returnRequest,
                  decision: ReturnRequestDecisionValue.approved,
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
    ReturnRequestQueueCubit cubit,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recusar devolução'),
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
      returnRequest: returnRequest,
      decision: ReturnRequestDecisionValue.rejected,
      reason: reason,
    );
  }
}

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/return_request.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../cubit/return_request_history_cubit.dart';
import '../cubit/return_request_history_state.dart';

/// Histórico de devoluções vinculado ao pedido (TASK-199, TASK-102) —
/// embutido no detalhe do pedido (`OrderHistoryPage`), sempre visível
/// (mesmo quando vazio) para deixar claro que nenhuma devolução foi aberta
/// ainda.
class ReturnRequestHistorySection extends StatelessWidget {
  const ReturnRequestHistorySection({
    required this.organizationId,
    required this.orderId,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String orderId;
  final ReturnRequestHistoryCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReturnRequestHistoryCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.watch(organizationId: organizationId, orderId: orderId),
        );
        return cubit;
      },
      child: BlocBuilder<ReturnRequestHistoryCubit, ReturnRequestHistoryState>(
        builder: (context, state) {
          if (state.status == ReturnRequestHistoryStatus.initial ||
              state.status == ReturnRequestHistoryStatus.loading) {
            return const SizedBox.shrink();
          }
          if (state.status == ReturnRequestHistoryStatus.error) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Devoluções',
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              if (state.returnRequests.isEmpty)
                Text(
                  'Nenhuma devolução solicitada para este pedido.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                )
              else
                for (final returnRequest in state.returnRequests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                    child: _ReturnRequestTile(returnRequest: returnRequest),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ReturnRequestTile extends StatelessWidget {
  const _ReturnRequestTile({required this.returnRequest});

  final ReturnRequest returnRequest;

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
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${returnRequest.reasonCategory.label} — '
                  '${returnRequest.totalRequestedQuantity} '
                  'ite${returnRequest.totalRequestedQuantity == 1 ? 'm' : 'ns'}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  CurrencyFormatter.formatWithCode(
                    returnRequest.refundAmount,
                    returnRequest.currency,
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
                if (returnRequest.status == ReturnRequestStatus.rejected &&
                    returnRequest.decisionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                    child: Text(
                      returnRequest.decisionReason!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppStatusBadge(
            label: returnRequest.status.label,
            variant: _variantFor(returnRequest.status),
          ),
        ],
      ),
    );
  }

  AppStatusBadgeVariant _variantFor(ReturnRequestStatus status) {
    return switch (status) {
      ReturnRequestStatus.requested => AppStatusBadgeVariant.info,
      ReturnRequestStatus.approved => AppStatusBadgeVariant.success,
      ReturnRequestStatus.rejected => AppStatusBadgeVariant.error,
    };
  }
}

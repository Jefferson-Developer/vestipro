import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/exchange_request.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../cubit/exchange_request_history_cubit.dart';
import '../cubit/exchange_request_history_state.dart';

/// Histórico de trocas vinculado ao pedido (TASK-200, TASK-102) — embutido
/// no detalhe do pedido (`OrderHistoryPage`), sempre visível (mesmo quando
/// vazio) para deixar claro que nenhuma troca foi aberta ainda.
class ExchangeRequestHistorySection extends StatelessWidget {
  const ExchangeRequestHistorySection({
    required this.organizationId,
    required this.orderId,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String orderId;
  final ExchangeRequestHistoryCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExchangeRequestHistoryCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.watch(organizationId: organizationId, orderId: orderId),
        );
        return cubit;
      },
      child:
          BlocBuilder<ExchangeRequestHistoryCubit, ExchangeRequestHistoryState>(
            builder: (context, state) {
              if (state.status == ExchangeRequestHistoryStatus.initial ||
                  state.status == ExchangeRequestHistoryStatus.loading) {
                return const SizedBox.shrink();
              }
              if (state.status == ExchangeRequestHistoryStatus.error) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Trocas',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing8),
                  if (state.exchangeRequests.isEmpty)
                    Text(
                      'Nenhuma troca solicitada para este pedido.',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colors.outline,
                      ),
                    )
                  else
                    for (final exchangeRequest in state.exchangeRequests)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.spacing8,
                        ),
                        child: _ExchangeRequestTile(
                          exchangeRequest: exchangeRequest,
                        ),
                      ),
                ],
              );
            },
          ),
    );
  }
}

class _ExchangeRequestTile extends StatelessWidget {
  const _ExchangeRequestTile({required this.exchangeRequest});

  final ExchangeRequest exchangeRequest;

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
                  '${exchangeRequest.reasonCategory.label} — '
                  '${exchangeRequest.totalRequestedQuantity} '
                  'ite${exchangeRequest.totalRequestedQuantity == 1 ? 'm' : 'ns'}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (exchangeRequest.priceDifferenceAmount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                    child: Text(
                      _priceDifferenceLabel(
                        exchangeRequest.priceDifferenceAmount!,
                        exchangeRequest.currency,
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ),
                if (exchangeRequest.status == ExchangeRequestStatus.rejected &&
                    exchangeRequest.decisionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                    child: Text(
                      exchangeRequest.decisionReason!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppStatusBadge(
            label: exchangeRequest.status.label,
            variant: _variantFor(exchangeRequest.status),
          ),
        ],
      ),
    );
  }

  String _priceDifferenceLabel(double amount, String currency) {
    if (amount == 0) return 'Sem diferença de preço';
    final formatted = CurrencyFormatter.formatWithCode(amount.abs(), currency);
    return amount > 0
        ? 'Cliente deve $formatted de diferença'
        : 'Cliente recebe $formatted de diferença';
  }

  AppStatusBadgeVariant _variantFor(ExchangeRequestStatus status) {
    return switch (status) {
      ExchangeRequestStatus.requested => AppStatusBadgeVariant.info,
      ExchangeRequestStatus.approved => AppStatusBadgeVariant.success,
      ExchangeRequestStatus.rejected => AppStatusBadgeVariant.error,
    };
  }
}

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/errors.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/order.dart';
import '../domain/entities/order_status_history_entry.dart';
import '../domain/entities/order_submission_result.dart';
import '../domain/usecases/save_order_draft_use_case.dart';
import '../domain/usecases/submit_order_use_case.dart';
import '../domain/value_objects/order_sync_status.dart';

/// UI-facing orchestration for "Enviar pedido" feedback (TASK-101/TASK-113).
Future<AppResult<OrderSubmissionResult>> submitOrderFromDraft({
  required BuildContext context,
  required Order order,
  required SubmitOrderUseCase submitOrderUseCase,
  required SaveOrderDraftUseCase saveOrderDraftUseCase,
  required void Function(String location) navigateTo,
}) async {
  final result = await submitOrderUseCase(order: order);
  if (!context.mounted) return result;

  switch (result) {
    case AppSuccess<OrderSubmissionResult>(value: final submission):
      final updatedOrder = order.copyWith(
        status: submission.status,
        syncStatus: OrderSyncStatus.synced,
        orderNumber: submission.orderNumber,
        discountAmount: submission.discountAmount,
        surchargeAmount: submission.surchargeAmount,
        shippingAmount: submission.shippingAmount,
        statusHistory: <OrderStatusHistoryEntry>[
          ...order.statusHistory,
          OrderStatusHistoryEntry(
            previousStatus: order.status,
            newStatus: submission.status,
            changedAt: submission.submittedAt,
            actorId: order.sellerId,
          ),
        ],
        updatedAt: submission.submittedAt,
        version: order.version + 1,
      );
      await saveOrderDraftUseCase(order: updatedOrder);
      if (!context.mounted) return result;
      AppSnackbar.show(
        context,
        message: 'Pedido ${submission.orderNumber} enviado com sucesso.',
        variant: AppSnackbarVariant.success,
      );
      navigateTo(
        CatalogHomeRoute(
          orgId: order.organizationId,
          companyId: order.companyId,
        ).location,
      );
    case AppFailure<OrderSubmissionResult>(failure: final failure):
      AppSnackbar.show(
        context,
        message: failure is ConnectivityFailure
            ? 'Sem conexão. O pedido continua salvo localmente neste '
                  'dispositivo e pode ser enviado quando a conexão voltar.'
            : failure.message,
        variant: failure is ConnectivityFailure
            ? AppSnackbarVariant.warning
            : AppSnackbarVariant.error,
      );
  }

  return result;
}

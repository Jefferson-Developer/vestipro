import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/notifications/notifications.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../repositories/order_commercial_alert_dispatch_repository.dart';
import '../value_objects/order_commercial_alert_classification.dart';
import '../value_objects/order_status.dart';
import '../value_objects/order_sync_status.dart';

/// Evaluates a single [Order] and, when it is `rejected` or failed to
/// sync, dispatches an internal notification (category `commercial`,
/// TASK-151) to [recipientUserId] — mirrors `ProcessTargetAlertUseCase`
/// (TASK-149)/`ProcessCrmTaskReminderUseCase` (TASK-152).
///
/// [recipientUserId] is always the caller's own authenticated user, never
/// resolved from [Order.sellerId] blindly, for the same two reasons
/// `ProcessCrmTaskReminderUseCase` already documents: `firestore.rules` only
/// lets a client create a notification for itself
/// (`userId == request.auth.uid`), and this [Order] is only ever fed to this
/// use case because the caller was already authorized to see it
/// (`OrderListBloc`'s own `Capability.orderView`/`OrderVisibilityService`
/// scoping) — so "apenas quem pode ver o pedido é notificado sobre ele"
/// holds by construction, never re-decided here.
///
/// The pedido's monetary value (`Order.itemsSubtotal`) is only ever included
/// in the notification body when [recipientUserId] holds
/// `Capability.financeView` — a `SALES_REP` without it still gets notified
/// (they need to know *that* their own pedido was rejected/failed to sync),
/// just never the amount, satisfying "nenhuma notificação vaza dado
/// financeiro sensível fora do RBAC do destinatário".
@injectable
final class ProcessOrderCommercialAlertUseCase {
  ProcessOrderCommercialAlertUseCase(
    this._dispatchRepository,
    this._notificationInboxRepository,
    this._permissionService,
    this._analyticsService,
  ) : _uuid = const Uuid();

  final OrderCommercialAlertDispatchRepository _dispatchRepository;
  final NotificationInboxRepository _notificationInboxRepository;
  final PermissionService _permissionService;
  final AnalyticsService _analyticsService;
  final Uuid _uuid;

  /// Returns `true` when a new notification was actually created for
  /// [order] — `false` when [order] warrants no alert, one was already
  /// dispatched for this exact (order, classification, recipient), or
  /// persisting the notification failed.
  Future<bool> call({
    required Order order,
    required String recipientUserId,
    DateTime? now,
  }) async {
    final classification = _classify(order);
    if (classification == null) return false;

    final instant = (now ?? DateTime.now()).toUtc();
    final lastDispatchedResult = await _dispatchRepository.getLastDispatchedAt(
      organizationId: order.organizationId,
      orderId: order.id,
      recipientUserId: recipientUserId,
      classification: classification,
    );
    final lastDispatchedAt = switch (lastDispatchedResult) {
      AppSuccess(value: final value) => value,
      _ => null,
    };
    // No cooldown re-arm (see repository doc): once dispatched for this
    // exact combination, it is never dispatched again.
    if (lastDispatchedAt != null) return false;

    final canViewFinance = await _canViewFinance(
      organizationId: order.organizationId,
      userId: recipientUserId,
    );
    final content = _contentFor(
      classification,
      order: order,
      includeAmount: canViewFinance,
    );
    final deepLink = OrderHistoryRoute(
      orgId: order.organizationId,
      companyId: order.companyId,
      orderId: order.id,
    ).location;

    final notification = AppNotification(
      id: _uuid.v4(),
      organizationId: order.organizationId,
      userId: recipientUserId,
      category: AppNotificationCategory.commercial,
      title: content.title,
      body: content.body,
      deepLink: deepLink,
      createdAt: instant,
      priority: AppNotificationPriority.critical,
    );

    final created = await _notificationInboxRepository.create(
      notification: notification,
    );
    if (created is! AppSuccess<AppNotification>) return false;

    await _dispatchRepository.markDispatched(
      organizationId: order.organizationId,
      orderId: order.id,
      recipientUserId: recipientUserId,
      classification: classification,
      dispatchedAt: instant,
    );
    await _analyticsService.logEvent(
      AnalyticsEvents.commercialOrderAlertTriggered,
      parameters: <String, Object?>{
        'organization_id': order.organizationId,
        'company_id': order.companyId,
        'order_id': order.id,
        'classification': classification.name,
      },
    );
    return true;
  }

  /// `null` means [order] currently warrants no commercial alert.
  /// `rejected` takes priority over a stale `criticalSyncFailure` a rejected
  /// order might still be carrying from before it last reached the backend.
  OrderCommercialAlertClassification? _classify(Order order) {
    if (order.status == OrderStatus.rejected) {
      return OrderCommercialAlertClassification.rejected;
    }
    if (order.syncStatus == OrderSyncStatus.failed) {
      return OrderCommercialAlertClassification.criticalSyncFailure;
    }
    return null;
  }

  Future<bool> _canViewFinance({
    required String organizationId,
    required String userId,
  }) async {
    final result = await _permissionService.hasPermission(
      organizationId: organizationId,
      userId: userId,
      capability: Capability.financeView,
    );
    return result is AppSuccess<bool> && result.value;
  }

  _OrderCommercialAlertContent _contentFor(
    OrderCommercialAlertClassification classification, {
    required Order order,
    required bool includeAmount,
  }) {
    final label = order.orderNumber ?? order.id;
    final amountSuffix = includeAmount
        ? ' Valor dos itens: R\$ ${order.itemsSubtotal.toStringAsFixed(2)}.'
        : '';
    return switch (classification) {
      OrderCommercialAlertClassification.rejected =>
        _OrderCommercialAlertContent(
          title: 'Pedido rejeitado',
          body:
              'O pedido $label foi rejeitado.'
              '${_reasonSuffix(order.rejectionReason)}$amountSuffix',
        ),
      OrderCommercialAlertClassification.criticalSyncFailure =>
        _OrderCommercialAlertContent(
          title: 'Falha crítica ao sincronizar pedido',
          body:
              'O pedido $label não foi sincronizado. Verifique a conexão e '
              'tente novamente para não perder o pedido.$amountSuffix',
        ),
    };
  }

  String _reasonSuffix(String? rejectionReason) {
    final reason = rejectionReason?.trim();
    if (reason == null || reason.isEmpty) return '';
    return ' Motivo: $reason.';
  }
}

final class _OrderCommercialAlertContent {
  const _OrderCommercialAlertContent({required this.title, required this.body});

  final String title;
  final String body;
}

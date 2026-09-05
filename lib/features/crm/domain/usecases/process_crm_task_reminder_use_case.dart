import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/notifications/notifications.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_reminder_dispatch_repository.dart';
import '../services/crm_task_reminder_evaluator.dart';
import '../value_objects/crm_reminder_settings.dart';
import '../value_objects/crm_task_reminder_classification.dart';

/// Evaluates a single [CrmTask] and, when it is overdue or due soon,
/// dispatches an internal notification (category `crm`, TASK-151) to
/// [recipientUserId] — mirrors `ProcessTargetAlertUseCase` (TASK-149).
///
/// [recipientUserId] is always the caller's own authenticated user (never
/// resolved from [CrmTask.responsibleUserId] blindly): `firestore.rules`
/// only lets a client create a notification for itself
/// (`userId == request.auth.uid`), and the business rule ("apenas o
/// responsável, e o gestor com visibilidade da equipe, recebe a
/// notificação — nunca outro vendedor sem relação com a atividade") is
/// satisfied by construction, since `GenerateCrmTaskRemindersUseCase` is only
/// ever fed the tasks the caller is already authorized to see
/// (`CrmTaskListBloc.visibleResponsibleUserIds` — the caller's own tasks,
/// plus their team's when `canManageOthers` is true).
@injectable
final class ProcessCrmTaskReminderUseCase {
  ProcessCrmTaskReminderUseCase(
    this._dispatchRepository,
    this._notificationInboxRepository,
    this._shouldDispatchNotification,
    this._resolveNotificationDeliveryTime,
    this._analyticsService,
  ) : _evaluator = const CrmTaskReminderEvaluator(),
      _uuid = const Uuid();

  final CrmReminderDispatchRepository _dispatchRepository;
  final NotificationInboxRepository _notificationInboxRepository;
  final ShouldDispatchNotificationUseCase _shouldDispatchNotification;
  final ResolveNotificationDeliveryTimeUseCase _resolveNotificationDeliveryTime;
  final AnalyticsService _analyticsService;
  final CrmTaskReminderEvaluator _evaluator;
  final Uuid _uuid;

  /// Returns `true` when a new notification was actually created for
  /// [task] — `false` when no reminder was warranted, the cooldown had not
  /// elapsed yet, the current time falls outside the allowed sending
  /// window, or persisting the notification failed.
  Future<bool> call({
    required CrmTask task,
    required String recipientUserId,
    required DateTime now,
    CrmReminderSettings settings = const CrmReminderSettings(),
  }) async {
    final classification = _evaluator.classify(
      task: task,
      now: now,
      settings: settings,
    );
    if (classification == CrmTaskReminderClassification.none) return false;

    // TASK-154: never writes the central de notificações entry at all when
    // the recipient turned `crm`/central off — checked before the cooldown
    // read below so a muted category never even touches the dispatch log.
    final allowed = await _shouldDispatchNotification(
      organizationId: task.organizationId,
      userId: recipientUserId,
      category: AppNotificationCategory.crm,
    );
    if (!allowed) return false;

    final lastDispatchedResult = await _dispatchRepository.getLastDispatchedAt(
      organizationId: task.organizationId,
      taskId: task.id,
      recipientUserId: recipientUserId,
      classification: classification,
    );
    final lastDispatchedAt = switch (lastDispatchedResult) {
      AppSuccess(value: final value) => value,
      _ => null,
    };
    if (lastDispatchedAt != null &&
        now.difference(lastDispatchedAt) < settings.notificationCooldown) {
      return false;
    }

    final isOwnTask = task.responsibleUserId == recipientUserId;
    final content = _contentFor(
      classification,
      task: task,
      isOwnTask: isOwnTask,
    );
    final deepLink = _resolveDeepLink(
      task: task,
      organizationId: task.organizationId,
    );

    // TASK-155: a CRM reminder is always `informative` — never `critical` —
    // so it is written now with a future `deliverAt` whenever it falls
    // inside the recipient's own quiet hours, replacing this use case's
    // former ad-hoc, org-wide 8h-18h window (`CrmReminderSettings`'s own
    // doc already anticipated this replacement).
    final deliverAt = await _resolveNotificationDeliveryTime(
      organizationId: task.organizationId,
      userId: recipientUserId,
      priority: AppNotificationPriority.informative,
      now: now,
    );

    final notification = AppNotification(
      id: _uuid.v4(),
      organizationId: task.organizationId,
      userId: recipientUserId,
      category: AppNotificationCategory.crm,
      title: content.title,
      body: content.body,
      deepLink: deepLink,
      createdAt: now,
      deliverAt: deliverAt,
    );

    final created = await _notificationInboxRepository.create(
      notification: notification,
    );
    if (created is! AppSuccess<AppNotification>) return false;

    await _dispatchRepository.markDispatched(
      organizationId: task.organizationId,
      taskId: task.id,
      recipientUserId: recipientUserId,
      classification: classification,
      dispatchedAt: now,
    );
    await _analyticsService.logEvent(
      AnalyticsEvents.crmReminderTriggered,
      parameters: <String, Object?>{
        'organization_id': task.organizationId,
        'task_id': task.id,
        'classification': classification.name,
        'is_own_task': isOwnTask,
      },
    );
    return true;
  }

  /// Prefers the customer 360 page (TASK-052) — the destination that
  /// exists today for essentially every CRM task, since a task is almost
  /// always tied to a `customerId`. Falls back to the Central de
  /// Oportunidades (TASK-132) when only an `opportunityId` is present, and
  /// finally to the Central de Notificações itself (always a valid route)
  /// so a deep link is never broken even for a task with neither.
  String _resolveDeepLink({
    required CrmTask task,
    required String organizationId,
  }) {
    final customerId = task.customerId?.trim();
    if (customerId != null && customerId.isNotEmpty) {
      return CustomerDetailRoute(
        orgId: organizationId,
        customerId: customerId,
      ).location;
    }

    final companyId = task.companyId?.trim();
    final opportunityId = task.opportunityId?.trim();
    if (companyId != null &&
        companyId.isNotEmpty &&
        opportunityId != null &&
        opportunityId.isNotEmpty) {
      return OpportunityCenterRoute(
        orgId: organizationId,
        companyId: companyId,
      ).location;
    }

    return NotificationCenterRoute(orgId: organizationId).location;
  }

  _CrmReminderContent _contentFor(
    CrmTaskReminderClassification classification, {
    required CrmTask task,
    required bool isOwnTask,
  }) {
    final title = task.title.trim().isEmpty
        ? 'Tarefa de CRM'
        : task.title.trim();
    return switch (classification) {
      CrmTaskReminderClassification.overdue => _CrmReminderContent(
        title: isOwnTask
            ? 'Follow-up atrasado'
            : 'Follow-up da equipe atrasado',
        body: isOwnTask
            ? '"$title" venceu e ainda está pendente. Priorize o contato '
                  'com o cliente.'
            : '"$title" da sua equipe venceu e ainda está pendente.',
      ),
      CrmTaskReminderClassification.dueSoon => _CrmReminderContent(
        title: isOwnTask
            ? 'Follow-up próximo do vencimento'
            : 'Follow-up da equipe próximo do vencimento',
        body: isOwnTask
            ? '"$title" vence em breve. Não perca o compromisso com o '
                  'cliente.'
            : '"$title" da sua equipe vence em breve.',
      ),
      CrmTaskReminderClassification.none => const _CrmReminderContent(
        title: '',
        body: '',
      ),
    };
  }
}

final class _CrmReminderContent {
  const _CrmReminderContent({required this.title, required this.body});

  final String title;
  final String body;
}

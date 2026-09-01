import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/notifications/notifications.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target.dart';
import '../../domain/entities/target_alert.dart';
import '../../domain/entities/target_alert_assessment.dart';
import '../../domain/entities/target_progress_view_model.dart';
import '../../domain/repositories/target_alert_dispatch_repository.dart';
import '../../domain/repositories/target_alert_settings_repository.dart';
import '../../domain/services/target_alert_evaluator.dart';
import '../../domain/value_objects/target_alert_settings.dart';

@injectable
final class ProcessTargetAlertUseCase {
  ProcessTargetAlertUseCase(
    this._settingsRepository,
    this._dispatchRepository,
    this._notificationInboxRepository,
    this._analyticsService,
  ) : _evaluator = const TargetAlertEvaluator(),
      _uuid = const Uuid();

  final TargetAlertSettingsRepository _settingsRepository;
  final TargetAlertDispatchRepository _dispatchRepository;
  final NotificationInboxRepository _notificationInboxRepository;
  final AnalyticsService _analyticsService;
  final TargetAlertEvaluator _evaluator;
  final Uuid _uuid;

  Future<TargetAlert?> call({
    required Target target,
    required TargetProgressViewModel progress,
    required String userId,
    DateTime? now,
  }) async {
    final instant = (now ?? DateTime.now()).toUtc();
    final settingsResult = await _settingsRepository.getForOrganization(
      organizationId: target.organizationId,
    );
    final settings = switch (settingsResult) {
      AppSuccess(value: final value) => value,
      _ => const TargetAlertSettings(),
    };

    final assessment = _evaluator.evaluate(
      target: target,
      progress: progress,
      settings: settings,
      now: instant,
    );
    if (assessment.classification == TargetAlertClassification.onTrack) {
      return null;
    }

    final deepLink = TargetDashboardRoute(
      orgId: target.organizationId,
      companyId: target.companyId,
      targetId: target.id,
    ).location;
    final content = _contentForAssessment(assessment);
    final shouldDispatch = await _shouldDispatch(
      organizationId: target.organizationId,
      targetId: target.id,
      classification: assessment.classification,
      now: instant,
      cooldown: settings.notificationCooldown,
    );

    if (!shouldDispatch) {
      return TargetAlert(
        classification: assessment.classification,
        title: content.title,
        message: content.message,
        deepLink: deepLink,
        daysRemaining: assessment.daysRemaining,
        paceRatio: assessment.paceRatio,
        notificationQueued: false,
      );
    }

    final notification = AppNotification(
      id: _uuid.v4(),
      organizationId: target.organizationId,
      userId: userId,
      category: AppNotificationCategory.targetAlert,
      title: content.title,
      body: content.message,
      deepLink: deepLink,
      createdAt: instant,
    );

    final notificationCreated = await _notificationInboxRepository.create(
      notification: notification,
    );
    final queued = notificationCreated is AppSuccess<AppNotification>;
    if (queued) {
      await _dispatchRepository.markDispatched(
        organizationId: target.organizationId,
        targetId: target.id,
        classification: assessment.classification,
        dispatchedAt: instant,
      );
      await _analyticsService.logEvent(
        AnalyticsEvents.targetAlertTriggered,
        parameters: <String, Object?>{
          'organization_id': target.organizationId,
          'company_id': target.companyId,
          'target_id': target.id,
          'metric_type': target.metricType.name,
          'dimension_type': target.dimensionType.name,
          'alert_type': assessment.classification.name,
        },
      );
    }

    return TargetAlert(
      classification: assessment.classification,
      title: content.title,
      message: content.message,
      deepLink: deepLink,
      daysRemaining: assessment.daysRemaining,
      paceRatio: assessment.paceRatio,
      notificationQueued: queued,
    );
  }

  Future<bool> _shouldDispatch({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
    required DateTime now,
    required Duration cooldown,
  }) async {
    final result = await _dispatchRepository.getLastDispatchedAt(
      organizationId: organizationId,
      targetId: targetId,
      classification: classification,
    );
    final lastDispatchedAt = switch (result) {
      AppSuccess(value: final value) => value,
      _ => null,
    };
    if (lastDispatchedAt == null) return true;
    return now.difference(lastDispatchedAt) >= cooldown;
  }

  _TargetAlertContent _contentForAssessment(TargetAlertAssessment assessment) {
    return switch (assessment.classification) {
      TargetAlertClassification.highRisk => _TargetAlertContent(
        title: 'Meta em risco alto',
        message:
            'Seu ritmo atual está bem abaixo do necessário. Restam '
            '${assessment.daysRemaining} dia(s) no período; vale priorizar '
            'clientes com maior potencial agora.',
      ),
      TargetAlertClassification.moderateRisk => _TargetAlertContent(
        title: 'Meta abaixo do ritmo',
        message:
            'Seu ritmo atual ficou abaixo do necessário. Restam '
            '${assessment.daysRemaining} dia(s) no período; revise as '
            'próximas contas a visitar.',
      ),
      TargetAlertClassification.opportunity => _TargetAlertContent(
        title: 'Meta próxima de ser atingida',
        message:
            'Você está perto de bater esta meta. Restam '
            '${assessment.daysRemaining} dia(s); mantenha o foco nos '
            'clientes mais quentes para consolidar o resultado.',
      ),
      TargetAlertClassification.onTrack => const _TargetAlertContent(
        title: '',
        message: '',
      ),
    };
  }
}

final class _TargetAlertContent {
  const _TargetAlertContent({required this.title, required this.message});

  final String title;
  final String message;
}

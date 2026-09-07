/// Centralized catalog of Firebase Analytics event names for VestiPro
/// (TASK-017). No feature is allowed to pass a raw string literal to
/// [AnalyticsService.logEvent] — every event name must be referenced through
/// a constant defined here, so the taxonomy stays consistent and grep-able
/// across the whole app (same reasoning as `AppRoutePaths` for navigation).
///
/// Naming convention (documented in `docs/architecture/analytics.md`):
/// `snake_case`, verb in the past participle, e.g. `_created`, `_completed`,
/// `_viewed`, `_submitted`, `_clicked`, `_downloaded`.
///
/// This is the minimum taxonomy required by section 14 of `tasks.md`. New
/// events must be added here — never inlined at the call site — and, when
/// they belong to a different domain than commercial/product analytics
/// (e.g. RBAC/audit metrics), kept in a separate catalog instead of mixed
/// into this one (see "Regras de negócio e restrições" in TASK-017).
final class AnalyticsEvents {
  const AnalyticsEvents._();

  static const String loginCompleted = 'login_completed';
  static const String signUpCompleted = 'sign_up_completed';
  static const String organizationCreated = 'organization_created';
  static const String customerCreated = 'customer_created';
  static const String leadCreated = 'lead_created';
  static const String leadQualified = 'lead_qualified';
  static const String leadDisqualified = 'lead_disqualified';
  static const String productViewed = 'product_viewed';
  static const String catalogFiltered = 'catalog_filtered';
  static const String orderCreated = 'order_created';
  static const String orderSubmitted = 'order_submitted';
  static const String orderSyncFailed = 'order_sync_failed';
  static const String orderApproved = 'order_approved';
  static const String orderRejected = 'order_rejected';
  static const String orderHistoryViewed = 'order_history_viewed';
  static const String orderDuplicated = 'order_duplicated';
  static const String crmActivityCreated = 'crm_activity_created';
  static const String crmFollowupCompleted = 'crm_followup_completed';
  static const String insightOpened = 'insight_opened';
  static const String insightActionClicked = 'insight_action_clicked';
  static const String reportExported = 'report_exported';
  static const String reportBuilt = 'report_built';
  static const String reportQueryExecuted = 'report_query_executed';
  static const String offlinePackDownloaded = 'offline_pack_downloaded';
  static const String productAddedToOrder = 'product_added_to_order';
  static const String passwordResetRequested = 'password_reset_requested';
  static const String inviteSent = 'invite_sent';
  static const String inviteAccepted = 'invite_accepted';
  static const String userRoleUpdated = 'user_role_updated';
  static const String userDeactivated = 'user_deactivated';
  static const String userReactivated = 'user_reactivated';
  static const String teamCreated = 'team_created';
  static const String teamUpdated = 'team_updated';
  static const String teamDeleted = 'team_deleted';
  static const String portfolioAssignmentSaved = 'portfolio_assignment_saved';
  static const String productCreated = 'product_created';
  static const String productUpdated = 'product_updated';
  static const String productPublished = 'product_published';
  static const String productMediaUpdated = 'product_media_updated';
  static const String futureStockViewed = 'future_stock_viewed';
  static const String catalogHomeViewed = 'catalog_home_viewed';
  static const String catalogSectionOpened = 'catalog_section_opened';
  static const String catalogGridViewed = 'catalog_grid_viewed';
  static const String productFavorited = 'product_favorited';
  static const String productUnfavorited = 'product_unfavorited';
  static const String favoritesViewed = 'favorites_viewed';
  static const String campaignViewed = 'campaign_viewed';
  static const String campaignProductClicked = 'campaign_product_clicked';
  static const String catalogShareCreated = 'catalog_share_created';
  static const String catalogShareOpened = 'catalog_share_opened';

  /// Logged by `CreateTargetUseCase`/`UpdateTargetUseCase` (TASK-115,
  /// EPIC-15) whenever a meta comercial is created or edited.
  static const String targetCreated = 'target_created';
  static const String targetUpdated = 'target_updated';

  /// Logged by `TargetDashboardCubit` (TASK-116, EPIC-15) once per dimension
  /// the caller navigates the achievement dashboard to (never once per
  /// realtime achievement tick — that would flood the taxonomy on every
  /// sync).
  static const String targetDashboardViewed = 'target_dashboard_viewed';

  /// Logged by `PositivacaoDashboardCubit` (TASK-117, EPIC-15) once per
  /// dimension the caller navigates the positivação de carteira dashboard
  /// to — same "once per dimension switch, never once per realtime tick"
  /// rule as [targetDashboardViewed].
  static const String positivacaoDashboardViewed =
      'positivacao_dashboard_viewed';

  /// Logged by the positivação settings admin screen (TASK-117, EPIC-15)
  /// whenever an OWNER/ADMIN updates the organization's positivação rule
  /// (`OrganizationSettings.positivacao*`).
  static const String positivacaoSettingsUpdated =
      'positivacao_settings_updated';

  /// Logged by `RankingDashboardCubit` (TASK-118, EPIC-15) once per
  /// dimension/metric the caller navigates the ranking comercial dashboard
  /// to — same "once per dimension switch, never once per realtime tick"
  /// rule as [targetDashboardViewed]/[positivacaoDashboardViewed].
  static const String rankingDashboardViewed = 'ranking_dashboard_viewed';
  static const String targetAlertTriggered = 'target_alert_triggered';

  /// Logged by every EPIC-17 BI dashboard bloc/cubit (starting with
  /// `ExecutiveDashboardBloc`, TASK-134) once per company/team/period filter
  /// combination the caller navigates to — `dashboard_type` (`executive`,
  /// and every future TASK-135 a TASK-143 value) plus the applied
  /// `company_id`/`team_id`/`month` are always carried as parameters, so a
  /// single event name lets analytics answer "quais dashboards de BI são
  /// mais usados" without a dedicated `*_dashboard_viewed` event per screen
  /// — deliberately not reusing [targetDashboardViewed]/
  /// [positivacaoDashboardViewed]/[rankingDashboardViewed] (EPIC-15's own,
  /// narrower, per-dashboard event names, already shipped before this
  /// cross-cutting convention existed for EPIC-17).
  static const String dashboardViewed = 'dashboard_viewed';

  /// Logged once per `SyncEngine.runPush` call (TASK-109, EPIC-14) — the
  /// Outbox drain pass — with `attempted`/`synced`/`failed`/`conflicts`/
  /// `duration_ms` parameters, feeding the "métricas de sincronização"
  /// required by seção 14 de `tasks.md`.
  static const String syncPushCompleted = 'sync_push_completed';

  /// Logged once per `SyncEngine.runPull` call (TASK-109, EPIC-14) — the
  /// incremental pull pass — with `sources_processed`/`sources_failed`/
  /// `applied`/`skipped`/`rejected_cross_tenant`/`duration_ms` parameters.
  static const String syncPullCompleted = 'sync_pull_completed';

  /// Logged when a user opens the Central de Sincronização (TASK-112,
  /// EPIC-14).
  static const String syncCenterOpened = 'sync_center_opened';

  /// Logged when a user triggers a manual retry from the Central de
  /// Sincronização (TASK-112, EPIC-14) — "Sincronizar agora", "Tentar
  /// novamente" (individual) or "Tentar novamente todos" (em lote).
  static const String syncManualRetryTriggered = 'sync_manual_retry_triggered';

  /// Logged whenever TASK-113's aggregated connectivity indicator changes
  /// between the four UI states, including the time the app spent offline
  /// before coming back online.
  static const String connectivityStatusChanged = 'connectivity_status_changed';

  /// Logged by `SavedReportsBloc` (TASK-145, EPIC-18) whenever a
  /// `ReportDefinition` from the report builder (TASK-144) is saved as a new
  /// `SavedReport`, carrying its `visibility` as a parameter.
  static const String reportViewSaved = 'report_view_saved';

  /// Logged by `SavedReportsBloc` (TASK-145) whenever an existing
  /// `SavedReport`'s `visibility` is changed away from `private`
  /// (`team`/`organization`) — never for a plain rename/favorite toggle.
  static const String reportViewShared = 'report_view_shared';

  /// Logged by `SavedReportsBloc` (TASK-145) whenever a `SavedReport` is
  /// permanently deleted.
  static const String reportViewDeleted = 'report_view_deleted';

  /// Logged by `ReportSchedulesBloc` (TASK-149, EPIC-18) whenever a new
  /// periodic `ReportSchedule` is created for a `SavedReport`.
  static const String reportScheduleCreated = 'report_schedule_created';

  /// Logged by `ReportSchedulesBloc` (TASK-149) whenever an existing
  /// `ReportSchedule` is paused.
  static const String reportSchedulePaused = 'report_schedule_paused';

  /// Logged by `ReportSchedulesBloc` (TASK-149) whenever a `ReportSchedule`
  /// is permanently deleted.
  static const String reportScheduleDeleted = 'report_schedule_deleted';

  /// Logged by `ProcessCrmTaskReminderUseCase` (TASK-152, EPIC-19) whenever
  /// an internal notification is actually dispatched for an overdue/due-soon
  /// CRM task or follow-up — `classification` (`overdue`/`dueSoon`) and
  /// `is_own_task` (the recipient is the task's own responsible rep vs. a
  /// manager with team visibility) are carried as parameters.
  static const String crmReminderTriggered = 'crm_reminder_triggered';

  /// Logged by `ProcessOrderCommercialAlertUseCase` (TASK-153, EPIC-19)
  /// whenever an internal notification is actually dispatched for a pedido
  /// rejeitado or a falha crítica de sincronização — `classification`
  /// (`rejected`/`criticalSyncFailure`) is carried as a parameter. Never
  /// carries the order's monetary value, same "no financial/personal data in
  /// analytics" rule every other event in this catalog already follows.
  static const String commercialOrderAlertTriggered =
      'commercial_order_alert_triggered';

  /// Logged by `ProcessInsightCommercialAlertUseCase` (TASK-153, EPIC-19)
  /// whenever an internal notification is actually dispatched for a "hot"
  /// commercial opportunity the insights engine (EPIC-16) identified —
  /// `insight_type` and `severity` are carried as parameters.
  static const String commercialOpportunityAlertTriggered =
      'commercial_opportunity_alert_triggered';

  /// Logged by `CommunicationPreferencesCubit` (TASK-154, EPIC-19) whenever a
  /// user successfully changes one `(category, channel)` frequency in the
  /// preferências de comunicação screen — `category`, `channel` and
  /// `frequency` are carried as parameters. Never logged for a rejected
  /// change (e.g. the system category fully-disabled guard).
  static const String communicationPreferencesUpdated =
      'communication_preferences_updated';

  /// Logged by `LocaleCubit` (TASK-174, EPIC-23) whenever a user successfully
  /// changes the app's interface language — the new `language_code` (e.g.
  /// `"pt"`, `"en"`) is carried as a parameter. Not logged for the value a
  /// device already boots with (only for an explicit change).
  static const String appLocaleChanged = 'app_locale_changed';

  /// Every event name currently defined in the taxonomy. Used by tests to
  /// assert there are no duplicates and by tooling that needs to enumerate
  /// the full catalog (e.g. a future QA/analytics debug screen).
  static const List<String> values = [
    loginCompleted,
    signUpCompleted,
    organizationCreated,
    customerCreated,
    leadCreated,
    leadQualified,
    leadDisqualified,
    productViewed,
    catalogFiltered,
    orderCreated,
    orderSubmitted,
    orderSyncFailed,
    orderApproved,
    orderRejected,
    orderHistoryViewed,
    orderDuplicated,
    crmActivityCreated,
    crmFollowupCompleted,
    insightOpened,
    insightActionClicked,
    reportExported,
    reportBuilt,
    reportQueryExecuted,
    offlinePackDownloaded,
    productAddedToOrder,
    passwordResetRequested,
    inviteSent,
    inviteAccepted,
    userRoleUpdated,
    userDeactivated,
    userReactivated,
    teamCreated,
    teamUpdated,
    teamDeleted,
    portfolioAssignmentSaved,
    productCreated,
    productUpdated,
    productPublished,
    productMediaUpdated,
    futureStockViewed,
    catalogHomeViewed,
    catalogSectionOpened,
    catalogGridViewed,
    productFavorited,
    productUnfavorited,
    favoritesViewed,
    campaignViewed,
    campaignProductClicked,
    catalogShareCreated,
    catalogShareOpened,
    targetCreated,
    targetUpdated,
    targetDashboardViewed,
    positivacaoDashboardViewed,
    positivacaoSettingsUpdated,
    rankingDashboardViewed,
    targetAlertTriggered,
    dashboardViewed,
    syncPushCompleted,
    syncPullCompleted,
    syncCenterOpened,
    syncManualRetryTriggered,
    connectivityStatusChanged,
    reportViewSaved,
    reportViewShared,
    reportViewDeleted,
    reportScheduleCreated,
    reportSchedulePaused,
    reportScheduleDeleted,
    crmReminderTriggered,
    commercialOrderAlertTriggered,
    commercialOpportunityAlertTriggered,
    communicationPreferencesUpdated,
    appLocaleChanged,
  ];
}

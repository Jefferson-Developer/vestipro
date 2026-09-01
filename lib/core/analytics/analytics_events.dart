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
    syncPushCompleted,
    syncPullCompleted,
    syncCenterOpened,
    syncManualRetryTriggered,
    connectivityStatusChanged,
  ];
}

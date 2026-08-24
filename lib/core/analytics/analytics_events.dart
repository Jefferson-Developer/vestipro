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
  ];
}

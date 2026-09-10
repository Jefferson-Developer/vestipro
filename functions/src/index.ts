import { initializeApp } from 'firebase-admin/app';

// A ordem importa: precisa correr antes de qualquer função que use
// `firebase-admin` (Firestore, Auth) ser registrada abaixo.
initializeApp();

export { healthCheck } from './health/health-check';
export { createOrganization } from './organizations/create-organization';
export { createInvite } from './invites/create-invite';
export { resendInvite } from './invites/resend-invite';
export { revokeInvite } from './invites/revoke-invite';
export { validateInvite } from './invites/validate-invite';
export { acceptInvite } from './invites/accept-invite';
export { updateUserRole } from './admin/update-user-role';
export { deactivateUser, reactivateUser } from './admin/update-user-access';
export {
  recalculateCustomerScores,
  startCustomerImportJob,
  processCustomerImportJob,
  resolveCustomerImportDuplicateRow,
  geocodeCustomerAddresses,
} from './customers';
export { startProductImportJob, processProductImportJob } from './products';
export { createCatalogShareLink } from './catalog/create-catalog-share-link';
export { getCatalogShareLink } from './catalog/get-catalog-share-link';
export { registerCatalogShareOpen } from './catalog/register-catalog-share-open';
export { revokeCatalogShareLink } from './catalog/revoke-catalog-share-link';
export { createCartShareLink, getCartShareLink, reviewCartShare } from './cart_shares';
export {
  createCustomerPortalInvite,
  acceptCustomerPortalInvite,
  loadCustomerPortal,
  repeatCustomerPortalOrder,
} from './customer_portal';
export { calculatePricing, simulateCommercialRule } from './pricing';
export { applyStockBalanceAdjustment } from './inventory/apply-stock-balance-adjustment';
export { createStockReservation } from './inventory/create-stock-reservation';
export { releaseStockReservation } from './inventory/release-stock-reservation';
export { consumeStockReservation } from './inventory/consume-stock-reservation';
export { expireStockReservations } from './inventory/expire-stock-reservations';
export { syncStockAlerts } from './inventory/sync-stock-alerts';
export { recomputeStockTurnoverMetrics } from './inventory/recompute-stock-turnover-metrics';
export {
  submitOrder,
  decideOrderApproval,
  signOrder,
  generateQuote,
  convertQuoteToOrder,
  expireQuotes,
  processRecurringOrders,
} from './orders';
export { generateInsightsScheduled } from './insights';
export {
  calculateReplenishmentSuggestions,
  decideReplenishmentSuggestion,
} from './replenishment';
export {
  calculateDemandForecasts,
  evaluateDemandForecastAccuracy,
} from './demand-forecast';
export { calculateProductRecommendations } from './recommendations';
export {
  recomputeSalesDailyOnOrderWrite,
  recomputeMonthlyAggregates,
  recomputeMonthlyAggregatesScheduled,
} from './aggregations';
export {
  loadReportCatalog,
  executeReportQuery,
  exportReportToCsv,
  exportReportToXlsx,
  exportReportToPdf,
  runReportSchedules,
} from './reports';
export {
  requestPersonalDataExport,
  processPersonalDataExportRequested,
  getPersonalDataExportDownloadUrl,
} from './privacy/personal-data-export';
export { requestAccountDeletion } from './privacy/account-deletion';
export {
  updateDataRetentionPolicy,
  applyDataRetentionPoliciesScheduled,
} from './privacy/data-retention';
export {
  saveErpIntegrationConfig,
  saveErpIntegrationCredentials,
  processErpSyncQueueItem,
  pullErpInventoryAndPrices,
  retryFailedErpSyncItems,
} from './erp_integration';
export {
  saveWebhookConfig,
  regenerateWebhookSecret,
  sendTestWebhookEvent,
  deliverWebhookEvent,
  retryFailedWebhookDeliveries,
  enqueueOrderWebhookEvents,
  enqueueCustomerWebhookEvents,
  enqueueInventoryWebhookEvents,
} from './webhooks';
export {
  generateApiKey,
  revokeApiKey,
  rotateApiKey,
  listApiKeys,
  publicApiV1,
} from './public_api';
export {
  configureSsoConnection,
  resolveSsoForEmail,
  completeSsoLogin,
} from './sso';
export {
  getWhatsAppContext,
  saveWhatsAppTemplate,
  updateWhatsAppOptIn,
  sendWhatsAppMessage,
  handleWhatsAppStatus,
} from './whatsapp';
export { generateWalletSummary } from './wallet_summary';
export { suggestApproach } from './approach_suggestion';
export { generateDailyRepSummary, getDailyRepSummary } from './daily_rep_summary';
export { explainReport } from './report_explanation';
export {
  recognizeProductImage,
  submitProductRecognitionFeedback,
  indexProductImageEmbedding,
  removeProductImageEmbeddingOnDelete,
} from './product_recognition';
export { assistCampaignCreation } from './campaign_assist';
export {
  createPaymentCharge,
  getPaymentStatus,
  handlePaymentWebhook,
  reconcilePaymentTransactionToOrder,
} from './payments';
export {
  calculateOrderCommission,
  calculateOrderCommissionOnWrite,
} from './commissions';
export { createReturnRequest, resolveReturnRequest } from './returns';

// Domínios reservados pelo backlog (EPIC-01 a EPIC-32) — cada um populado pela
// task correspondente. Mantidos vazios de propósito por enquanto; nenhum é
// importado aqui até ter uma função real para exportar.
// - src/auth/     (ex.: TASK-029 — RBAC)
// - src/pricing/  (ex.: TASK-088 — motor de precificação server-side)
// - src/insights/ (ex.: TASK-121 — engine base de insights)
// - src/admin/    (ex.: TASK-033 — auditoria administrativa)

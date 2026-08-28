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
export { recalculateCustomerScores } from './customers';
export { createCatalogShareLink } from './catalog/create-catalog-share-link';
export { getCatalogShareLink } from './catalog/get-catalog-share-link';
export { registerCatalogShareOpen } from './catalog/register-catalog-share-open';
export { revokeCatalogShareLink } from './catalog/revoke-catalog-share-link';
export { calculatePricing } from './pricing';
export { applyStockBalanceAdjustment } from './inventory/apply-stock-balance-adjustment';
export { createStockReservation } from './inventory/create-stock-reservation';
export { releaseStockReservation } from './inventory/release-stock-reservation';
export { consumeStockReservation } from './inventory/consume-stock-reservation';
export { expireStockReservations } from './inventory/expire-stock-reservations';
export { syncStockAlerts } from './inventory/sync-stock-alerts';

// Domínios reservados pelo backlog (EPIC-01 a EPIC-32) — cada um populado pela
// task correspondente. Mantidos vazios de propósito por enquanto; nenhum é
// importado aqui até ter uma função real para exportar.
// - src/auth/     (ex.: TASK-029 — RBAC)
// - src/pricing/  (ex.: TASK-088 — motor de precificação server-side)
// - src/orders/   (ex.: TASK-101 — submissão do pedido)
// - src/insights/ (ex.: TASK-121 — engine base de insights)
// - src/admin/    (ex.: TASK-033 — auditoria administrativa)

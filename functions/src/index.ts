import { initializeApp } from 'firebase-admin/app';

// A ordem importa: precisa correr antes de qualquer função que use
// `firebase-admin` (Firestore, Auth) ser registrada abaixo.
initializeApp();

export { healthCheck } from './health/health-check';

// Domínios reservados pelo backlog (EPIC-01 a EPIC-32) — cada um populado pela
// task correspondente. Mantidos vazios de propósito por enquanto; nenhum é
// importado aqui até ter uma função real para exportar.
// - src/auth/     (ex.: TASK-029 — RBAC)
// - src/pricing/  (ex.: TASK-088 — motor de precificação server-side)
// - src/orders/   (ex.: TASK-101 — submissão do pedido)
// - src/insights/ (ex.: TASK-121 — engine base de insights)
// - src/admin/    (ex.: TASK-033 — auditoria administrativa)

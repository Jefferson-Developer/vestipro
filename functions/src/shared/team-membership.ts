import type { Firestore } from 'firebase-admin/firestore';

/**
 * Whether [uidA] and [uidB] (both members of [organizationId]) share at
 * least one team — the exact "gestor de equipe" scoping rule already
 * established by `../orders/decide-order-approval.ts` (TASK-103) and reused
 * as-is by `../wallet_summary/wallet-summary-shared.ts`'s
 * `assertCanAccessSellerWallet` (TASK-186) and
 * `../approach_suggestion/approach-suggestion-shared.ts`'s
 * `assertCanAccessCustomer` (TASK-187) — extracted here once both features
 * needed the identical Firestore round-trip + set-intersection, instead of
 * each keeping its own copy (AGENTS.md: "Não duplicar... regra").
 *
 * Reads only `organizations/{organizationId}/members/{uid}` for both ids —
 * never trusts a client-supplied team list.
 */
export async function membersShareTeam(params: {
  db: Firestore;
  organizationId: string;
  uidA: string;
  uidB: string;
}): Promise<boolean> {
  const { db, organizationId, uidA, uidB } = params;
  const membersRef = db
    .collection('organizations')
    .doc(organizationId)
    .collection('members');
  const [snapshotA, snapshotB] = await Promise.all([
    membersRef.doc(uidA).get(),
    membersRef.doc(uidB).get(),
  ]);
  const teamIdsA = normalizeTeamIds(snapshotA.data()?.teamIds);
  const teamIdsB = normalizeTeamIds(snapshotB.data()?.teamIds);
  return teamIdsB.some((teamId) => teamIdsA.includes(teamId));
}

function normalizeTeamIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is string => typeof entry === 'string');
}

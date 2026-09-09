import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Transaction,
} from 'firebase-admin/firestore';
import type { PricingEngineOutput } from '../pricing/pricing-engine';
import { optionalString } from '../pricing/calculate-pricing';

export interface ApprovalChainLevel {
  index: number;
  role: string;
  label: string;
}

export interface ApprovalChainInstance {
  policyId: string;
  policyVersion: number;
  reason: string;
  discountPercent: number;
  currentLevelIndex: number;
  status: 'pending' | 'approved' | 'rejected';
  levels: ApprovalChainLevel[];
  decisions: ApprovalChainDecision[];
}

export interface ApprovalChainDecision {
  levelIndex: number;
  role: string;
  decision: 'approved' | 'rejected';
  actorId: string;
  actorName: string;
  reason: string | null;
  decidedAt: Timestamp;
}

interface ApprovalPolicyLevelInput {
  role: string;
  label?: string;
}

interface ApprovalPolicyBand {
  id: string;
  companyId?: string;
  status: string;
  version: number;
  minDiscountPercent: number;
  maxDiscountPercent: number;
  levels: ApprovalPolicyLevelInput[];
}

export function buildApprovalChainInstance(
  policyDocs: Array<{ id: string; data: DocumentData }>,
  companyId: string,
  pricing: PricingEngineOutput,
  fallbackReason: string,
): ApprovalChainInstance | null {
  const discountPercent = highestRequestedDiscountPercent(pricing);
  if (!pricing.approvalRequired || discountPercent <= 0) return null;

  const policy = policyDocs
    .map((doc) => mapApprovalPolicy(doc.id, doc.data))
    .filter((candidate) =>
      candidate.status === 'active' &&
      (!candidate.companyId || candidate.companyId === companyId) &&
      discountPercent >= candidate.minDiscountPercent &&
      discountPercent <= candidate.maxDiscountPercent &&
      candidate.levels.length > 0,
    )
    .sort((left, right) => {
      const byScope = Number(Boolean(right.companyId)) - Number(Boolean(left.companyId));
      if (byScope !== 0) return byScope;
      const byMin = right.minDiscountPercent - left.minDiscountPercent;
      if (byMin !== 0) return byMin;
      return left.id.localeCompare(right.id);
    })[0];

  if (!policy) return null;

  return {
    policyId: policy.id,
    policyVersion: policy.version,
    reason: fallbackReason,
    discountPercent,
    currentLevelIndex: 0,
    status: 'pending',
    levels: policy.levels.map((level, index) => ({
      index,
      role: level.role,
      label: level.label ?? level.role,
    })),
    decisions: [],
  };
}

export function parseApprovalChain(data: unknown): ApprovalChainInstance | null {
  if (typeof data !== 'object' || data === null) return null;
  const raw = data as DocumentData;
  const levels = Array.isArray(raw.levels)
    ? raw.levels.map((entry, index) => {
        if (typeof entry !== 'object' || entry === null) {
          throw new HttpsError('failed-precondition', 'Cadeia de aprovacao invalida.');
        }
        const level = entry as DocumentData;
        const role = requireString(level.role, 'approvalChain.level.role');
        return {
          index: typeof level.index === 'number' ? level.index : index,
          role,
          label: optionalString(level.label) ?? role,
        };
      })
    : [];
  if (levels.length === 0) return null;

  const decisions = Array.isArray(raw.decisions)
    ? raw.decisions.map((entry) => {
        if (typeof entry !== 'object' || entry === null) {
          throw new HttpsError('failed-precondition', 'Historico de aprovacao invalido.');
        }
        const decision = entry as DocumentData;
        return {
          levelIndex: Number(decision.levelIndex ?? 0),
          role: requireString(decision.role, 'approvalChain.decision.role'),
          decision: requireChainDecision(decision.decision),
          actorId: requireString(decision.actorId, 'approvalChain.decision.actorId'),
          actorName: optionalString(decision.actorName) ?? '',
          reason: optionalString(decision.reason) ?? null,
          decidedAt: decision.decidedAt instanceof Timestamp
            ? decision.decidedAt
            : Timestamp.now(),
        };
      })
    : [];

  return {
    policyId: optionalString(raw.policyId) ?? 'legacy',
    policyVersion: Number(raw.policyVersion ?? 1),
    reason: optionalString(raw.reason) ?? 'Aprovacao comercial requerida.',
    discountPercent: Number(raw.discountPercent ?? 0),
    currentLevelIndex: Number(raw.currentLevelIndex ?? 0),
    status: raw.status === 'approved' || raw.status === 'rejected' ? raw.status : 'pending',
    levels,
    decisions,
  };
}

export async function enqueueApprovalNotifications(
  transaction: Transaction,
  organizationRef: DocumentReference,
  params: {
    organizationId: string;
    companyId: string;
    orderId: string;
    orderNumber: string;
    level: ApprovalChainLevel;
    now: Timestamp;
    actorId: string;
  },
): Promise<number> {
  const membersSnapshot = await transaction.get(
    organizationRef.collection('members')
      .where('roleName', '==', params.level.role)
      .where('status', '==', 'active'),
  );
  let count = 0;
  for (const member of membersSnapshot.docs) {
    const userId = optionalString(member.data().userId) ?? member.id;
    transaction.set(organizationRef.collection('notifications').doc(), {
      organizationId: params.organizationId,
      userId,
      type: 'order_approval_required',
      category: 'commercial',
      title: 'Pedido aguardando aprovacao',
      body: `Pedido ${params.orderNumber} aguarda ${params.level.label}.`,
      deepLink: `/org/${params.organizationId}/orders/approve?orderId=${params.orderId}`,
      metadata: {
        companyId: params.companyId,
        orderId: params.orderId,
        orderNumber: params.orderNumber,
        approvalLevelIndex: params.level.index,
        approvalRole: params.level.role,
      },
      readAt: null,
      deliverAt: params.now,
      createdAt: params.now,
      createdBy: params.actorId,
    });
    count += 1;
  }
  return count;
}

function mapApprovalPolicy(id: string, data: DocumentData): ApprovalPolicyBand {
  const rawLevels = Array.isArray(data.levels) ? data.levels : [];
  const levels = rawLevels
    .map((entry): ApprovalPolicyLevelInput | null => {
      if (typeof entry !== 'object' || entry === null) return null;
      const level = entry as DocumentData;
      const role = optionalString(level.role);
      if (!role) return null;
      return { role, label: optionalString(level.label) };
    })
    .filter((entry): entry is ApprovalPolicyLevelInput => entry !== null);

  return {
    id,
    companyId: optionalString(data.companyId),
    status: optionalString(data.status) ?? 'inactive',
    version: Number(data.version ?? 1),
    minDiscountPercent: Number(
      data.minDiscountPercent ?? data.discountFromPercent ?? data.fromPercent ?? 0,
    ),
    maxDiscountPercent: Number(
      data.maxDiscountPercent ?? data.discountToPercent ?? data.toPercent ?? 100,
    ),
    levels,
  };
}

function highestRequestedDiscountPercent(pricing: PricingEngineOutput): number {
  return pricing.items.reduce((highest, item) => {
    const requested = item.approvalRequest?.requestedDiscountPercent ?? 0;
    return requested > highest ? requested : highest;
  }, 0);
}

function requireString(value: unknown, field: string): string {
  const parsed = optionalString(value);
  if (!parsed) {
    throw new HttpsError('failed-precondition', `${field} is required.`);
  }
  return parsed;
}

function requireChainDecision(value: unknown): 'approved' | 'rejected' {
  if (value === 'approved' || value === 'rejected') return value;
  throw new HttpsError('failed-precondition', 'Decisao de aprovacao invalida.');
}

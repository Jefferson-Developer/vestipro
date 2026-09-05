import { getFirestore, Timestamp, type DocumentData, type Query } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { requireNonEmptyString } from '../invites/invite-shared';
import { AGGREGATE_COLLECTION_BY_DIMENSION } from '../aggregations/aggregation-shared';
import { catalogForRole, REPORT_ROLES, type ReportFieldConfig } from './report-catalog';

interface FilterInput { fieldId?: unknown; operator?: unknown; value?: unknown }
interface DefinitionInput { organizationId?: unknown; companyId?: unknown; dimensions?: unknown; metrics?: unknown; filters?: unknown; groupBy?: unknown; sortBy?: unknown; comparisonPeriod?: unknown }

/** The subset of a `members/{uid}` document {@link runReportAggregation} and
 * every caller of it needs — never the full membership record. */
export interface ReportAggregationMember {
  roleName: string;
  teamIds?: string[];
}

export interface ReportAggregationParams {
  db: FirebaseFirestore.Firestore;
  organizationId: string;
  companyId: string;
  member: ReportAggregationMember;
  authUid: string;
  data: DefinitionInput | undefined;
}

/**
 * Server-owned dimension/metric aggregation shared by every reporting
 * callable that must produce exactly the same rows a report's
 * `ReportDefinition` describes: `executeReportQuery` (interactive preview,
 * TASK-133/TASK-144) and `exportReportToCsv` (TASK-146) — the latter never
 * trusts a `ReportQueryResult` handed back by the client, it re-derives the
 * same rows itself under the caller's own role/tenant scope, exactly as this
 * function already re-validates for the interactive preview.
 *
 * Caller-side auth/membership/company validation is *not* repeated here —
 * every current and future caller already did that (see `executeReportQuery`
 * and `exportReportToCsv`) before invoking this function, so [member] is
 * assumed to already be the caller's own active Membership.
 */
export async function runReportAggregation(
  params: ReportAggregationParams,
): Promise<{ columns: string[]; rows: Record<string, unknown>[] }> {
  const { db, organizationId, companyId, member, authUid, data } = params;
  const dimensions = stringArray(data?.dimensions, 'dimensions', 2);
  const metrics = stringArray(data?.metrics, 'metrics', 6);
  if (!dimensions.length || !metrics.length) throw new HttpsError('invalid-argument', 'Escolha dimensão e métrica.');
  const catalog = catalogForRole(member.roleName);
  validateSelection(dimensions, metrics, catalog);
  const period = parsePeriod(data?.filters);
  const source = sourceFor(dimensions);
  const loadPeriod = async (month: string): Promise<DocumentData[]> => {
    let query: Query = db.collection('organizations').doc(organizationId).collection(AGGREGATE_COLLECTION_BY_DIMENSION[source]).where('companyId', '==', companyId);
    query = source === 'salesDaily'
      ? query.where('periodKey', '>=', `${month}-01`).where('periodKey', '<=', `${month}-31`).orderBy('periodKey')
      : query.where('periodKey', '==', month);
    if (member.roleName === 'SALES_REP') query = query.where('scopeId', '==', authUid);
    const snapshots = (await query.limit(500).get()).docs.map((doc) => doc.data());
    return member.roleName === 'SALES_MANAGER'
      ? snapshots.filter((row) => Array.isArray(member.teamIds) && member.teamIds.includes(row.labels?.teamId))
      : snapshots;
  };
  let rows = aggregateRows(await loadPeriod(period), dimensions, metrics);
  const comparison = parseComparison(data?.comparisonPeriod);
  let columns = [...dimensions, ...metrics];
  if (comparison !== 'none') {
    const comparisonRows = aggregateRows(await loadPeriod(comparisonMonth(period, comparison)), dimensions, metrics);
    rows = mergeComparison(rows, comparisonRows, dimensions, metrics);
    columns = [...columns, ...metrics.flatMap((metric) => [`${metric}Comparison`, `${metric}ChangePercent`])];
  }
  const sort = data?.sortBy as { fieldId?: unknown; direction?: unknown } | undefined;
  if (sort && typeof sort.fieldId === 'string') rows = sortRows(rows, sort.fieldId, sort.direction === 'descending');
  return { columns, rows };
}

export const executeReportQuery = onCall<DefinitionInput>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const db = getFirestore();
  const memberSnapshot = await db.collection('organizations').doc(organizationId).collection('members').doc(request.auth.uid).get();
  const member = memberSnapshot.data();
  if (!memberSnapshot.exists || member?.status !== 'active' || !REPORT_ROLES.has(member.roleName as string)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode executar relatórios.');
  }
  const company = await db.collection('organizations').doc(organizationId).collection('companies').doc(companyId).get();
  if (!company.exists) throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');
  const { columns, rows } = await runReportAggregation({
    db,
    organizationId,
    companyId,
    member: member as ReportAggregationMember,
    authUid: request.auth.uid,
    data: request.data,
  });
  return { columns, rows, generatedAt: Timestamp.now().toDate().toISOString() };
});

function validateSelection(dimensions: string[], metrics: string[], catalog: ReportFieldConfig[]): void {
  for (const id of [...dimensions, ...metrics]) {
    const field = catalog.find((candidate) => candidate.id === id && candidate.isAvailable !== false);
    if (!field) throw new HttpsError('permission-denied', `Campo ${id} indisponível para seu perfil.`);
  }
  const families = new Set(dimensions.map((id) => ['product', 'category', 'collection'].includes(id) ? 'product' : id));
  if (families.size > 1) throw new HttpsError('invalid-argument', 'As dimensões selecionadas não compartilham a mesma agregação.');
  for (const id of metrics) {
    const field = catalog.find((candidate) => candidate.id === id)!;
    if (dimensions.some((dimension) => !(field.compatibleDimensions ?? []).includes(dimension))) {
      throw new HttpsError('invalid-argument', `${field.label} é incompatível com a dimensão selecionada.`);
    }
  }
}

function sourceFor(dimensions: string[]) {
  const dimension = dimensions[0];
  if (dimension === 'period') return 'salesDaily' as const;
  if (dimension === 'customer') return 'customerMonthly' as const;
  if (dimension === 'seller') return 'sellerMonthly' as const;
  if (dimension === 'region') return 'regionMonthly' as const;
  return 'productMonthly' as const;
}

function aggregateRows(snapshots: DocumentData[], dimensions: string[], metrics: string[]): Record<string, unknown>[] {
  const groups = new Map<string, { dimensions: Record<string, string>; revenueNet: number; revenueGross: number; discountAmount: number; orderCount: number; itemQuantity: number }>();
  for (const snapshot of snapshots) {
    const values = Object.fromEntries(dimensions.map((id) => [id, dimensionValue(id, snapshot)]));
    const key = JSON.stringify(values);
    const current = groups.get(key) ?? { dimensions: values, revenueNet: 0, revenueGross: 0, discountAmount: 0, orderCount: 0, itemQuantity: 0 };
    current.revenueNet += number(snapshot.revenueNet); current.revenueGross += number(snapshot.revenueGross);
    current.discountAmount += number(snapshot.discountAmount); current.orderCount += number(snapshot.orderCount); current.itemQuantity += number(snapshot.itemQuantity);
    groups.set(key, current);
  }
  return [...groups.values()].map((group) => ({ ...group.dimensions, ...Object.fromEntries(metrics.map((id) => [id, metricValue(id, group)])) }));
}

export function mergeComparison(current: Record<string, unknown>[], previous: Record<string, unknown>[], dimensions: string[], metrics: string[]): Record<string, unknown>[] {
  const keyOf = (row: Record<string, unknown>) => JSON.stringify(Object.fromEntries(dimensions.map((id) => [id, row[id]])));
  const previousByKey = new Map(previous.map((row) => [keyOf(row), row]));
  return current.map((row) => {
    const before = previousByKey.get(keyOf(row));
    const comparisonValues = Object.fromEntries(metrics.flatMap((metric) => {
      const currentValue = number(row[metric]);
      const previousValue = before == null ? null : number(before[metric]);
      const change = previousValue == null || previousValue === 0 ? null : round((currentValue - previousValue) / Math.abs(previousValue) * 100);
      return [[`${metric}Comparison`, previousValue], [`${metric}ChangePercent`, change]];
    }));
    return { ...row, ...comparisonValues };
  });
}

function dimensionValue(id: string, row: DocumentData): string {
  if (id === 'period') return row.periodKey as string;
  const labelKey = ({ customer: 'customerName', product: 'productName', category: 'categoryName', collection: 'collectionName', seller: 'sellerName' } as Record<string, string>)[id];
  if (id === 'region') return (row.labels?.state ?? row.scopeId) as string;
  return (row.labels?.[labelKey] ?? row.labels?.[id + 'Id'] ?? row.scopeId ?? '—') as string;
}

function metricValue(id: string, row: { revenueNet: number; revenueGross: number; discountAmount: number; orderCount: number; itemQuantity: number }): number {
  if (id === 'averageTicket') return row.orderCount ? round(row.revenueNet / row.orderCount) : 0;
  if (id === 'averageDiscount') return row.revenueGross ? round(row.discountAmount / row.revenueGross * 100) : 0;
  if (id === 'piecesPerOrder') return row.orderCount ? round(row.itemQuantity / row.orderCount) : 0;
  return row[id as keyof typeof row] as number;
}

function parsePeriod(raw: unknown): string {
  const filters = Array.isArray(raw) ? raw as FilterInput[] : [];
  const value = filters.find((filter) => filter.fieldId === 'period')?.value;
  if (typeof value !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(value)) throw new HttpsError('invalid-argument', 'Informe o período no formato AAAA-MM.');
  return value;
}

function parseComparison(raw: unknown): 'none' | 'previousPeriod' | 'previousYear' {
  if (raw == null || raw === 'none') return 'none';
  if (raw === 'previousPeriod' || raw === 'previousYear') return raw;
  throw new HttpsError('invalid-argument', 'Comparação de período inválida.');
}

export function comparisonMonth(period: string, comparison: 'previousPeriod' | 'previousYear'): string {
  const [year, month] = period.split('-').map(Number);
  const date = comparison === 'previousYear'
    ? new Date(Date.UTC(year - 1, month - 1, 1))
    : new Date(Date.UTC(year, month - 2, 1));
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

function stringArray(raw: unknown, field: string, max: number): string[] {
  if (!Array.isArray(raw) || raw.some((item) => typeof item !== 'string') || raw.length > max) throw new HttpsError('invalid-argument', `${field} inválido.`);
  return [...new Set(raw as string[])];
}

function sortRows(rows: Record<string, unknown>[], field: string, descending: boolean): Record<string, unknown>[] {
  return [...rows].sort((a, b) => { const left = a[field]; const right = b[field]; const order = typeof left === 'number' && typeof right === 'number' ? left - right : String(left).localeCompare(String(right)); return descending ? -order : order; });
}
function number(value: unknown): number { return typeof value === 'number' && Number.isFinite(value) ? value : 0; }
function round(value: number): number { return Math.round(value * 100) / 100; }

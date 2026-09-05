import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';

export interface ReportFieldConfig {
  id: string;
  label: string;
  type: 'dimension' | 'metric' | 'filter';
  valueType: 'text' | 'number' | 'currency' | 'percentage' | 'date';
  compatibleDimensions?: readonly string[];
  isSensitive?: boolean;
  isAvailable?: boolean;
  unavailableReason?: string;
}

export const REPORT_ROLES = new Set(['OWNER', 'ADMIN', 'SALES_MANAGER', 'SALES_REP', 'FINANCE']);
export const FINANCIAL_ROLES = new Set(['OWNER', 'ADMIN', 'FINANCE']);

const PRODUCT_DIMENSIONS = ['product', 'category', 'collection'] as const;
const ALL_DIMENSIONS = ['period', 'customer', 'product', 'category', 'collection', 'seller', 'region'] as const;

export const REPORT_FIELDS: readonly ReportFieldConfig[] = [
  ...ALL_DIMENSIONS.map((id) => ({ id, label: dimensionLabel(id), type: 'dimension' as const, valueType: id === 'period' ? 'date' as const : 'text' as const })),
  { id: 'revenueNet', label: 'Faturamento líquido', type: 'metric', valueType: 'currency', compatibleDimensions: ALL_DIMENSIONS, isSensitive: true },
  { id: 'revenueGross', label: 'Faturamento bruto', type: 'metric', valueType: 'currency', compatibleDimensions: ALL_DIMENSIONS, isSensitive: true },
  { id: 'orderCount', label: 'Pedidos', type: 'metric', valueType: 'number', compatibleDimensions: ['period', 'customer', 'seller', 'region'] },
  { id: 'itemQuantity', label: 'Quantidade vendida', type: 'metric', valueType: 'number', compatibleDimensions: ALL_DIMENSIONS },
  { id: 'averageTicket', label: 'Ticket médio', type: 'metric', valueType: 'currency', compatibleDimensions: ['period', 'customer', 'seller', 'region'], isSensitive: true },
  { id: 'averageDiscount', label: 'Desconto médio', type: 'metric', valueType: 'percentage', compatibleDimensions: ALL_DIMENSIONS, isSensitive: true },
  { id: 'piecesPerOrder', label: 'Peças por pedido', type: 'metric', valueType: 'number', compatibleDimensions: ['period', 'customer', 'seller', 'region'] },
  // KPIs specified in tasks.md but not derivable from TASK-133's current
  // snapshots remain in the server-owned catalog as unavailable. A later
  // aggregation can enable them without shipping a new Flutter UI.
  ...['activeCustomers', 'newCustomers', 'reactivatedCustomers', 'conversion', 'repurchaseRate', 'averageFrequency', 'averageMix', 'margin', 'sellThrough', 'fillRate', 'backorders', 'creditBlockedOrders', 'receivablesAging', 'otif', 'dataQualityScore', 'growthYoY', 'growthMoM', 'targetAchievement', 'portfolioCoverage', 'positivation', 'churn', 'closingForecast', 'weightedPipeline', 'pipelineAging'].map((id) => ({
    id, label: kpiLabel(id), type: 'metric' as const, valueType: 'number' as const,
    compatibleDimensions: ALL_DIMENSIONS, isAvailable: false,
    unavailableReason: 'A camada de agregação ainda não publica este KPI para consultas ad-hoc.',
  })),
  { id: 'period', label: 'Período', type: 'filter', valueType: 'date' },
];

export function catalogForRole(roleName: string): ReportFieldConfig[] {
  if (!REPORT_ROLES.has(roleName)) throw new HttpsError('permission-denied', 'Seu perfil não pode construir relatórios.');
  return REPORT_FIELDS.map((field) => {
    let available = field.isAvailable !== false;
    let reason = field.unavailableReason;
    if (roleName === 'SALES_REP' && field.type === 'dimension' && field.id !== 'seller') {
      available = false; reason = 'Representantes consultam somente a própria carteira.';
    }
    if (field.isSensitive && !FINANCIAL_ROLES.has(roleName)) {
      available = false; reason = 'Métrica disponível apenas para perfis financeiros autorizados.';
    }
    if (roleName === 'SALES_MANAGER' && field.type === 'dimension' && field.id !== 'seller') {
      available = false; reason = 'Gestores consultam somente vendedores das próprias equipes.';
    }
    return { ...field, isAvailable: available, ...(reason ? { unavailableReason: reason } : {}) };
  });
}

export const loadReportCatalog = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  const company = await db.collection('organizations').doc(organizationId).collection('companies').doc(companyId).get();
  if (!company.exists) throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');
  return { fields: catalogForRole(membership.roleName), maxDimensions: 2, maxMetrics: 6 };
});

function dimensionLabel(id: string): string {
  return ({ period: 'Período', customer: 'Cliente', product: 'Produto', category: 'Categoria', collection: 'Coleção', seller: 'Vendedor', region: 'Região' } as Record<string, string>)[id];
}

function kpiLabel(id: string): string {
  const labels: Record<string, string> = { activeCustomers: 'Clientes ativos', newCustomers: 'Clientes novos', reactivatedCustomers: 'Clientes reativados', conversion: 'Conversão', repurchaseRate: 'Taxa de recompra', averageFrequency: 'Frequência média', averageMix: 'Mix médio', margin: 'Margem', sellThrough: 'Sell-through', fillRate: 'Fill rate', backorders: 'Backorders', creditBlockedOrders: 'Pedidos bloqueados por crédito', receivablesAging: 'Aging de contas a receber', otif: 'OTIF', dataQualityScore: 'Qualidade cadastral', growthYoY: 'Crescimento YoY', growthMoM: 'Crescimento MoM', targetAchievement: 'Atingimento de meta', portfolioCoverage: 'Cobertura de carteira', positivation: 'Positivação', churn: 'Churn', closingForecast: 'Previsão de fechamento', weightedPipeline: 'Pipeline ponderado', pipelineAging: 'Aging do pipeline' };
  return labels[id] ?? id;
}

export { PRODUCT_DIMENSIONS };

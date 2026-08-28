import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import {
  asBalanceSnapshot,
  asStockAlertRuleDocument,
  chooseRuleForLevel,
  levelForQuantity,
  resolveApplicableRules,
  resolveTransitionType,
  sellableQuantity,
  type InventoryBalanceSnapshot,
  type StockAlertLevel,
  type StockAlertRuleDocument,
  type StockAlertTransitionType,
} from './stock-alert-shared';

export interface StockAlertSyncOutcome {
  createdAlertIds: string[];
}

export interface StockAlertRecord {
  alertId: string;
  notificationEventId: string;
  organizationId: string;
  companyId: string;
  productId: string;
  variantId: string;
  warehouseId: string;
  level: StockAlertLevel;
  previousLevel: StockAlertLevel | null;
  currentLevel: StockAlertLevel | null;
  transitionType: StockAlertTransitionType;
  sellableQuantity: number;
  thresholdQuantity: number;
  ruleId: string;
  triggeredAt: InventoryBalanceSnapshot['updatedAt'];
}

export interface StockAlertPersistence {
  listRules(organizationId: string): Promise<ReadonlyArray<StockAlertRuleDocument>>;
  saveAlertAndEvent(record: StockAlertRecord): Promise<void>;
}

export async function syncStockAlertsForBalanceChange(
  before: InventoryBalanceSnapshot | null,
  after: InventoryBalanceSnapshot | null,
  persistence?: StockAlertPersistence,
): Promise<StockAlertSyncOutcome> {
  if (!after) {
    return { createdAlertIds: [] };
  }

  const adapter = persistence ?? createFirestorePersistence();
  const rules = await adapter.listRules(after.organizationId);

  const applicableRules = resolveApplicableRules(rules, after);
  if (applicableRules.length === 0) {
    return { createdAlertIds: [] };
  }

  const previousQuantity = sellableQuantity(before);
  const currentQuantity = sellableQuantity(after);
  const previousLevel = levelForQuantity(previousQuantity, applicableRules);
  const currentLevel = levelForQuantity(currentQuantity, applicableRules);
  const transitionType = resolveTransitionType(previousLevel, currentLevel);

  if (!transitionType) {
    return { createdAlertIds: [] };
  }

  const effectiveLevel = currentLevel ?? previousLevel;
  if (!effectiveLevel) {
    return { createdAlertIds: [] };
  }
  const rule = chooseRuleForLevel(effectiveLevel, applicableRules);
  const timestamp = after.updatedAt;
  const alertId = `${after.variantId}_${after.warehouseId}_v${after.version}`;
  const notificationEventId = `${alertId}_notification`;

  await adapter.saveAlertAndEvent({
    alertId,
    notificationEventId,
    organizationId: after.organizationId,
    companyId: after.companyId,
    productId: after.productId,
    variantId: after.variantId,
    warehouseId: after.warehouseId,
    level: effectiveLevel,
    previousLevel,
    currentLevel,
    transitionType,
    sellableQuantity: currentQuantity ?? 0,
    thresholdQuantity: rule.minQuantity,
    ruleId: rule.id,
    triggeredAt: timestamp,
  });

  logger.info('syncStockAlertsForBalanceChange created stock alert', {
    organizationId: after.organizationId,
    productId: after.productId,
    variantId: after.variantId,
    warehouseId: after.warehouseId,
    previousLevel,
    currentLevel,
    transitionType,
    alertId,
  });

  return { createdAlertIds: [alertId] };
}

function createFirestorePersistence(): StockAlertPersistence {
  const db = getFirestore();

  return {
    async listRules(organizationId: string): Promise<ReadonlyArray<StockAlertRuleDocument>> {
      const organizationRef = db.collection('organizations').doc(organizationId);
      const rulesSnapshot = await organizationRef.collection('stockAlertRules').get();
      return rulesSnapshot.docs
        .map((doc) => asStockAlertRuleDocument(doc.id, doc.data()))
        .filter((rule): rule is StockAlertRuleDocument => rule != null);
    },
    async saveAlertAndEvent(record: StockAlertRecord): Promise<void> {
      const organizationRef = db.collection('organizations').doc(record.organizationId);
      await Promise.all([
        organizationRef.collection('stockAlerts').doc(record.alertId).set({
          organizationId: record.organizationId,
          companyId: record.companyId,
          productId: record.productId,
          variantId: record.variantId,
          warehouseId: record.warehouseId,
          level: record.level,
          previousLevel: record.previousLevel,
          currentLevel: record.currentLevel,
          transitionType: record.transitionType,
          sellableQuantity: record.sellableQuantity,
          thresholdQuantity: record.thresholdQuantity,
          triggeredAt: record.triggeredAt,
          ruleId: record.ruleId,
          notificationEventId: record.notificationEventId,
        }),
        organizationRef
          .collection('stockAlertEvents')
          .doc(record.notificationEventId)
          .set({
            organizationId: record.organizationId,
            stockAlertId: record.alertId,
            sourceCollection: 'stockAlerts',
            eventType: 'inventory.stockAlertTransitioned',
            level: record.level,
            previousLevel: record.previousLevel,
            currentLevel: record.currentLevel,
            transitionType: record.transitionType,
            sellableQuantity: record.sellableQuantity,
            thresholdQuantity: record.thresholdQuantity,
            variantId: record.variantId,
            warehouseId: record.warehouseId,
            productId: record.productId,
            createdAt: record.triggeredAt,
            status: 'pending',
          }),
      ]);
    },
  };
}

export const syncStockAlerts = onDocumentWritten(
  'organizations/{organizationId}/inventory/{inventoryId}',
  async (event) => {
    const before = asBalanceSnapshot(event.data?.before.data());
    const after = asBalanceSnapshot(event.data?.after.data());
    await syncStockAlertsForBalanceChange(before, after);
  },
);

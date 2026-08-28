import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
} from 'firebase-admin/firestore';

export const ROLES_ALLOWED_TO_RESERVE_STOCK: ReadonlySet<string> =
  new Set<string>([
    'OWNER',
    'ADMIN',
    'SALES_MANAGER',
    'SALES_REP',
    'SALES_ASSISTANT',
  ]);

export const DEFAULT_STOCK_RESERVATION_TTL_MINUTES = 15;
export const STOCK_RESERVATION_MIN_TTL_MINUTES = 15;
export const STOCK_RESERVATION_MAX_TTL_MINUTES = 60;

export type StockReservationStatus =
  | 'active'
  | 'expired'
  | 'released'
  | 'consumed';

export interface StockReservationResponse {
  reservationId: string;
  organizationId: string;
  companyId: string;
  productId: string;
  variantId: string;
  warehouseId: string;
  orderDraftId: string;
  quantity: number;
  reservedBy: string;
  reservedAt: string;
  expiresAt: string;
  status: StockReservationStatus;
  releasedAt?: string;
  releasedBy?: string;
  consumedAt?: string;
  consumedBy?: string;
  correlationId: string;
}

export interface InventoryBalanceSnapshot {
  physicalQuantity: number;
  reservedQuantity: number;
  blockedQuantity: number;
}

export function requirePositiveInteger(value: unknown, field: string): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value <= 0) {
    throw new HttpsError('invalid-argument', `${field} must be a positive integer.`);
  }
  return value;
}

export function stockReservationRef(
  organizationRef: DocumentReference,
  reservationId: string,
): DocumentReference {
  return organizationRef.collection('stockReservations').doc(reservationId);
}

export function balanceDocId(variantId: string, warehouseId: string): string {
  return `${variantId}_${warehouseId}`;
}

export function inventoryBalanceRef(
  organizationRef: DocumentReference,
  variantId: string,
  warehouseId: string,
): DocumentReference {
  return organizationRef
    .collection('inventory')
    .doc(balanceDocId(variantId, warehouseId));
}

export function asInt(value: unknown): number {
  return typeof value === 'number' && Number.isInteger(value) ? value : 0;
}

export function asTimestamp(value: unknown): Timestamp | undefined {
  return value instanceof Timestamp ? value : undefined;
}

export function computeSellableQuantity(
  balance: InventoryBalanceSnapshot,
): number {
  return (
    balance.physicalQuantity - balance.reservedQuantity - balance.blockedQuantity
  );
}

export function buildReservationExpiryDate(now: Date, ttlMinutes: number): Date {
  return new Date(now.getTime() + ttlMinutes * 60 * 1000);
}

export function planReservationCreate(
  balance: InventoryBalanceSnapshot,
  quantity: number,
): InventoryBalanceSnapshot {
  if (computeSellableQuantity(balance) < quantity) {
    throw new HttpsError(
      'failed-precondition',
      'Nao ha saldo vendavel suficiente para reservar esta quantidade.',
    );
  }
  return {
    physicalQuantity: balance.physicalQuantity,
    reservedQuantity: balance.reservedQuantity + quantity,
    blockedQuantity: balance.blockedQuantity,
  };
}

export function planReservationRelease(
  balance: InventoryBalanceSnapshot,
  quantity: number,
): InventoryBalanceSnapshot {
  const nextReserved = balance.reservedQuantity - quantity;
  if (nextReserved < 0) {
    throw new HttpsError(
      'failed-precondition',
      'A liberacao deixaria o saldo reservado negativo.',
    );
  }
  return {
    physicalQuantity: balance.physicalQuantity,
    reservedQuantity: nextReserved,
    blockedQuantity: balance.blockedQuantity,
  };
}

export function planReservationConsume(
  balance: InventoryBalanceSnapshot,
  quantity: number,
): InventoryBalanceSnapshot {
  const nextBalance = {
    physicalQuantity: balance.physicalQuantity - quantity,
    reservedQuantity: balance.reservedQuantity - quantity,
    blockedQuantity: balance.blockedQuantity,
  };
  if (nextBalance.physicalQuantity < 0 || nextBalance.reservedQuantity < 0) {
    throw new HttpsError(
      'failed-precondition',
      'O consumo da reserva deixaria o saldo fisico ou reservado negativo.',
    );
  }
  if (computeSellableQuantity(nextBalance) < 0) {
    throw new HttpsError(
      'failed-precondition',
      'O consumo da reserva deixaria o saldo vendavel negativo.',
    );
  }
  return nextBalance;
}

export function resolveStockReservationTtlMinutes(
  organizationData: DocumentData | undefined,
): number {
  const rawValue = organizationData?.settings?.stockReservationExpiresInMinutes;
  if (typeof rawValue !== 'number' || !Number.isInteger(rawValue)) {
    return DEFAULT_STOCK_RESERVATION_TTL_MINUTES;
  }
  if (
    rawValue < STOCK_RESERVATION_MIN_TTL_MINUTES ||
    rawValue > STOCK_RESERVATION_MAX_TTL_MINUTES
  ) {
    throw new HttpsError(
      'failed-precondition',
      'A organizacao possui uma configuracao invalida para expiracao de reserva.',
    );
  }
  return rawValue;
}

export function serializeStockReservation(
  reservationId: string,
  data: DocumentData,
  correlationId: string,
): StockReservationResponse {
  const reservedAt = asTimestamp(data.reservedAt);
  const expiresAt = asTimestamp(data.expiresAt);
  const releasedAt = asTimestamp(data.releasedAt);
  const consumedAt = asTimestamp(data.consumedAt);

  return {
    reservationId,
    organizationId: data.organizationId as string,
    companyId: data.companyId as string,
    productId: data.productId as string,
    variantId: data.variantId as string,
    warehouseId: data.warehouseId as string,
    orderDraftId: data.orderDraftId as string,
    quantity: asInt(data.quantity),
    reservedBy: data.reservedBy as string,
    reservedAt: reservedAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    expiresAt: expiresAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    status: (data.status as StockReservationStatus | undefined) ?? 'active',
    releasedAt: releasedAt?.toDate().toISOString(),
    releasedBy: data.releasedBy as string | undefined,
    consumedAt: consumedAt?.toDate().toISOString(),
    consumedBy: data.consumedBy as string | undefined,
    correlationId,
  };
}

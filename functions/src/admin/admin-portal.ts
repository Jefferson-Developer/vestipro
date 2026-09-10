import {
  HttpsError,
  onCall,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  resolveCorrelationId,
  type RequestWithMeta,
} from '../shared/callable-meta';

const OPERATOR_PERMISSIONS = [
  'adminPortal.view',
  'adminPortal.viewSensitiveData',
  'adminPortal.reprocessOutbox',
] as const;

export type OperatorPermission = (typeof OPERATOR_PERMISSIONS)[number];

interface AdminPortalRequest extends RequestWithMeta {
  organizationId?: string;
  query?: string;
  reason?: string;
  ticketId?: string;
  targetUserId?: string;
  deviceId?: string;
  outboxItemId?: string;
}

export interface AdminPortalOperatorSession {
  uid: string;
  displayName: string;
  permissions: OperatorPermission[];
}

export function requireVestiProOperator(
  request: CallableRequest<RequestWithMeta>,
  permission: OperatorPermission = 'adminPortal.view',
): AdminPortalOperatorSession {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  }
  const claims = request.auth.token as Record<string, unknown>;
  if (claims.vestiproOperator !== true) {
    throw new HttpsError(
      'permission-denied',
      'Apenas operadores VestiPro podem acessar este portal.',
    );
  }
  const permissions = Array.isArray(claims.vestiproOperatorPermissions)
    ? claims.vestiproOperatorPermissions.filter(
        (item): item is OperatorPermission =>
          typeof item === 'string' &&
          (OPERATOR_PERMISSIONS as readonly string[]).includes(item),
      )
    : [...OPERATOR_PERMISSIONS];
  if (!permissions.includes(permission)) {
    throw new HttpsError(
      'permission-denied',
      'Operador VestiPro sem permissao para esta acao.',
    );
  }
  return {
    uid: request.auth.uid,
    displayName:
      typeof claims.name === 'string' && claims.name.trim()
        ? claims.name.trim()
        : 'Operador VestiPro',
    permissions,
  };
}

export function requireAdminPortalReason(reason: unknown): string {
  const normalized = typeof reason === 'string' ? reason.trim() : '';
  if (normalized.length < 8) {
    throw new HttpsError(
      'invalid-argument',
      'Informe uma justificativa de suporte antes de acessar dados da organizacao.',
    );
  }
  return normalized;
}

function requireString(value: unknown, field: string): string {
  const normalized = typeof value === 'string' ? value.trim() : '';
  if (!normalized) {
    throw new HttpsError('invalid-argument', `Campo obrigatorio: ${field}.`);
  }
  return normalized;
}

function optionalString(value: unknown): string | undefined {
  const normalized = typeof value === 'string' ? value.trim() : '';
  return normalized || undefined;
}

export async function recordAdminPortalOperatorAudit({
  db,
  organizationId,
  operator,
  action,
  entityType,
  entityId,
  reason,
  ticketId,
  metadata,
}: {
  db: Firestore;
  organizationId: string;
  operator: AdminPortalOperatorSession;
  action: string;
  entityType: string;
  entityId: string;
  reason: string;
  ticketId?: string;
  metadata?: Record<string, unknown>;
}): Promise<string> {
  const ref = db
    .collection('organizations')
    .doc(organizationId)
    .collection('auditLogs')
    .doc();
  await ref.set({
    organizationId,
    actorUserId: operator.uid,
    actorName: operator.displayName,
    action,
    entityType,
    entityId,
    newValue: {
      reason,
      ticketId: ticketId ?? null,
      ...sanitizeAdminPortalAuditMetadata(metadata ?? {}),
    },
    timestamp: Timestamp.now(),
  });
  return ref.id;
}

export function sanitizeAdminPortalAuditMetadata(
  metadata: Record<string, unknown>,
): Record<string, unknown> {
  const blocked = new Set([
    'password',
    'senha',
    'token',
    'secret',
    'apikey',
    'api_key',
    'cpf',
    'cnpj',
  ]);
  return Object.fromEntries(
    Object.entries(metadata).filter(([key]) => !blocked.has(key.toLowerCase())),
  );
}

function safeNumber(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function safeDate(value: unknown): string | null {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return value;
  return null;
}

function healthStatus(
  syncErrors: number,
  openTickets: number,
): 'healthy' | 'warning' | 'critical' {
  if (syncErrors >= 10 || openTickets >= 5) return 'critical';
  if (syncErrors > 0 || openTickets > 0) return 'warning';
  return 'healthy';
}

export function scrubAdminPortalLogMessage(value: unknown): string {
  const text = typeof value === 'string' ? value : 'Evento tecnico registrado.';
  return text
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
    .replace(/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/g, '[cpf]')
    .replace(/\b\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}\b/g, '[cnpj]');
}

export const resolveVestiProOperatorSession = onCall<RequestWithMeta>(
  (request) => {
    const operator = requireVestiProOperator(request);
    return {
      userId: operator.uid,
      displayName: operator.displayName,
      permissions: operator.permissions,
    };
  },
);

export const searchAdminOrganizations = onCall<AdminPortalRequest>(
  async (request) => {
    const operator = requireVestiProOperator(request);
    const reason = requireAdminPortalReason(request.data.reason);
    const ticketId = optionalString(request.data.ticketId);
    const query = optionalString(request.data.query)?.toLowerCase() ?? '';
    const db = getFirestore();
    const snapshot = await db.collection('organizations').limit(50).get();
    const organizations = snapshot.docs
      .map((document) => {
        const data = document.data();
        const displayName = String(
          data.name ?? data.displayName ?? document.id,
        );
        const activeUsers = safeNumber(
          data.activeUsers ?? data.metrics?.activeUsers,
        );
        const syncErrors = safeNumber(
          data.syncErrors ?? data.health?.syncErrors,
        );
        const orderVolumeLast30Days = safeNumber(
          data.orderVolumeLast30Days ?? data.metrics?.orderVolumeLast30Days,
        );
        const openTickets = safeNumber(
          data.openTickets ?? data.support?.openTickets,
        );
        return {
          organizationId: document.id,
          displayName,
          status: String(data.status ?? 'unknown'),
          healthStatus: healthStatus(syncErrors, openTickets),
          activeUsers,
          syncErrors,
          orderVolumeLast30Days,
          openTickets,
          lastActivityAt: safeDate(data.lastActivityAt ?? data.updatedAt),
        };
      })
      .filter(
        (organization) =>
          !query ||
          organization.organizationId.toLowerCase().includes(query) ||
          organization.displayName.toLowerCase().includes(query),
      )
      .slice(0, 25);

    await Promise.all(
      organizations.map((organization) =>
        recordAdminPortalOperatorAudit({
          db,
          organizationId: organization.organizationId,
          operator,
          action: 'vestiproAdmin.organizationSearched',
          entityType: 'organization',
          entityId: organization.organizationId,
          reason,
          ticketId,
          metadata: { query },
        }),
      ),
    );

    logger.info('searchAdminOrganizations succeeded', {
      uid: operator.uid,
      count: organizations.length,
      correlationId: resolveCorrelationId(request.data._meta),
    });
    return { organizations };
  },
);

export const loadAdminDiagnosticReport = onCall<AdminPortalRequest>(
  async (request) => {
    const operator = requireVestiProOperator(
      request,
      'adminPortal.viewSensitiveData',
    );
    const reason = requireAdminPortalReason(request.data.reason);
    const organizationId = requireString(
      request.data.organizationId,
      'organizationId',
    );
    const targetUserId = requireString(
      request.data.targetUserId,
      'targetUserId',
    );
    const deviceId = requireString(request.data.deviceId, 'deviceId');
    const ticketId = optionalString(request.data.ticketId);
    const db = getFirestore();
    const deviceRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('syncDevices')
      .doc(deviceId);
    const device = await deviceRef.get();
    const data = device.data() ?? {};
    if (!device.exists) {
      throw new HttpsError(
        'not-found',
        'Dispositivo de sincronizacao nao encontrado para esta organizacao.',
      );
    }
    if (data.userId !== targetUserId) {
      throw new HttpsError(
        'permission-denied',
        'Dispositivo nao pertence ao usuario informado.',
      );
    }
    const logs = await deviceRef
      .collection('technicalLogs')
      .orderBy('occurredAt', 'desc')
      .limit(20)
      .get();
    const auditLogId = await recordAdminPortalOperatorAudit({
      db,
      organizationId,
      operator,
      action: 'vestiproAdmin.diagnosticViewed',
      entityType: 'syncDevice',
      entityId: deviceId,
      reason,
      ticketId,
      metadata: { targetUserId, deviceId },
    });

    return {
      organizationId,
      userId: targetUserId,
      deviceId,
      syncStatus: String(data.syncStatus ?? 'unknown'),
      pendingOutboxItems: safeNumber(data.pendingOutboxItems),
      failedOutboxItems: safeNumber(data.failedOutboxItems),
      lastSyncAt: safeDate(data.lastSyncAt),
      auditLogId,
      technicalLogs: logs.docs.map((log) => {
        const logData = log.data();
        const rawLevel = String(logData.level ?? 'info');
        return {
          id: log.id,
          level: ['info', 'warning', 'error'].includes(rawLevel)
            ? rawLevel
            : 'info',
          message: scrubAdminPortalLogMessage(logData.message),
          occurredAt: safeDate(logData.occurredAt) ?? new Date(0).toISOString(),
          correlationId: optionalString(logData.correlationId),
        };
      }),
    };
  },
);

export const reprocessAdminOutboxItem = onCall<AdminPortalRequest>(
  async (request) => {
    const operator = requireVestiProOperator(
      request,
      'adminPortal.reprocessOutbox',
    );
    const reason = requireAdminPortalReason(request.data.reason);
    const organizationId = requireString(
      request.data.organizationId,
      'organizationId',
    );
    const outboxItemId = requireString(
      request.data.outboxItemId,
      'outboxItemId',
    );
    const ticketId = optionalString(request.data.ticketId);
    const db = getFirestore();
    const outboxRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('outbox')
      .doc(outboxItemId);
    await outboxRef.set(
      {
        status: 'pending',
        supportReprocessRequestedAt: FieldValue.serverTimestamp(),
        supportReprocessRequestedBy: operator.uid,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    const auditLogId = await recordAdminPortalOperatorAudit({
      db,
      organizationId,
      operator,
      action: 'vestiproAdmin.outboxReprocessRequested',
      entityType: 'outbox',
      entityId: outboxItemId,
      reason,
      ticketId,
    });
    return {
      organizationId,
      action: 'vestiproAdmin.outboxReprocessRequested',
      message: 'Reprocessamento assistido solicitado e auditado.',
      auditLogId,
    };
  },
);

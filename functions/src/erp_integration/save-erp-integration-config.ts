import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanManageErpIntegration,
  erpIntegrationConfigRef,
  isInboundErpEntityType,
  validateFieldMappingConfig,
} from './erp-integration-shared';
import { buildDefaultErpAdapterRegistry } from './adapters/erp-adapter-registry';
import type { InboundErpEntityType } from './types';

export interface SaveErpIntegrationConfigRequest extends RequestWithMeta {
  organizationId?: string;
  adapterType?: string;
  enabledEntityTypes?: unknown;
  fieldMappings?: unknown;
  connection?: unknown;
  isActive?: boolean;
}

export interface SaveErpIntegrationConfigResponse {
  correlationId: string;
}

/**
 * Saves the non-secret half of an organization's ERP integration
 * (TASK-169): which adapter/entities are enabled, the field mapping and
 * adapter-specific connection details (e.g. `baseUrl`/endpoint paths for the
 * reference `GenericRestErpAdapter`). Never accepts credentials — those go
 * through `saveErpIntegrationCredentials`, kept as a separate document/
 * callable so the secret payload never transits through, or is validated
 * alongside, this one's broader request/response logging.
 *
 * RBAC (`assertCanManageErpIntegration`, OWNER/ADMIN only) and every field's
 * shape are re-validated here from the caller's real Membership/request,
 * independent of anything the client claims — same posture
 * `startProductImportJob` (TASK-168) already documents.
 */
export const saveErpIntegrationConfig = onCall<
  SaveErpIntegrationConfigRequest,
  Promise<SaveErpIntegrationConfigResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const adapterType = requireNonEmptyString(request.data?.adapterType, 'adapterType');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageErpIntegration(membership.roleName);

  const registry = buildDefaultErpAdapterRegistry();
  if (!registry.has(adapterType)) {
    throw new HttpsError(
      'invalid-argument',
      `Nenhum adapter de ERP registrado para "${adapterType}".`,
    );
  }

  const enabledEntityTypes = assertValidEnabledEntityTypes(
    request.data?.enabledEntityTypes,
  );
  const fieldMappings = validateFieldMappingConfig(request.data?.fieldMappings);
  const connection = assertValidConnection(request.data?.connection);
  const isActive = request.data?.isActive !== false;

  await erpIntegrationConfigRef(db, organizationId).set({
    organizationId,
    adapterType,
    enabledEntityTypes,
    fieldMappings,
    connection,
    isActive,
    updatedAt: new Date(),
    updatedBy: uid,
  });

  logger.info('saveErpIntegrationConfig succeeded', {
    correlationId,
    uid,
    organizationId,
    adapterType,
  });

  return { correlationId };
});

function assertValidEnabledEntityTypes(
  raw: unknown,
): Array<InboundErpEntityType | 'order'> {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'enabledEntityTypes deve ser uma lista não vazia.',
    );
  }
  return raw.map((value) => {
    if (
      typeof value !== 'string' ||
      (!isInboundErpEntityType(value) && value !== 'order')
    ) {
      throw new HttpsError(
        'invalid-argument',
        `Tipo de entidade inválido em enabledEntityTypes: ${String(value)}.`,
      );
    }
    return value;
  });
}

function assertValidConnection(raw: unknown): Record<string, unknown> {
  if (raw === null || raw === undefined) return {};
  if (typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError('invalid-argument', 'connection deve ser um objeto.');
  }
  for (const value of Object.values(raw as Record<string, unknown>)) {
    if (typeof value !== 'string' && typeof value !== 'number' && typeof value !== 'boolean') {
      throw new HttpsError(
        'invalid-argument',
        'connection só pode conter valores string/number/boolean (nenhum segredo).',
      );
    }
  }
  return raw as Record<string, unknown>;
}

import type { Firestore } from 'firebase-admin/firestore';

import {
  erpIntegrationConfigRef,
  erpIntegrationCredentialsRef,
} from './erp-integration-shared';
import type { ErpIntegrationConfig, ErpIntegrationCredentials } from './types';

/** Loads an organization's ERP integration config — always scoped to the
 * exact `organizationId` passed in (never a caller-suppliable path), so one
 * organization's adapter/mapping can never be read while resolving another's
 * (TASK-169: "adapter, mapeamento e credenciais de uma organização nunca
 * vazam para outra"). Returns `null` when the organization never configured
 * one or explicitly disabled it (`isActive === false`). */
export async function loadErpIntegrationConfig(
  db: Firestore,
  organizationId: string,
): Promise<ErpIntegrationConfig | null> {
  const snapshot = await erpIntegrationConfigRef(db, organizationId).get();
  if (!snapshot.exists) return null;
  const data = snapshot.data() as ErpIntegrationConfig | undefined;
  if (!data || data.isActive === false) return null;
  return data;
}

/** Loads an organization's ERP credentials — same tenant-scoping guarantee
 * as `loadErpIntegrationConfig`. Never logged by any caller; the secret
 * payload only ever flows into the resolved `ErpAdapter`'s own method
 * calls. */
export async function loadErpIntegrationCredentials(
  db: Firestore,
  organizationId: string,
): Promise<ErpIntegrationCredentials | null> {
  const snapshot = await erpIntegrationCredentialsRef(db, organizationId).get();
  if (!snapshot.exists) return null;
  return snapshot.data() as ErpIntegrationCredentials;
}

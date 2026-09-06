import { HttpsError } from 'firebase-functions/v2/https';

import type { ErpAdapter } from '../types';
import { GenericRestErpAdapter } from './generic-rest-erp-adapter';

/**
 * The only place that maps an `adapterType` string to a concrete
 * `ErpAdapter` implementation (TASK-169's acceptance criterion: "Arquitetura
 * permite adicionar um novo adapter de ERP concreto sem reescrever o núcleo
 * do framework") — adding a concrete ERP (e.g. `'sap_btp'`, `'totvs_rest'`)
 * is always exactly one new `register()` call plus its own adapter class;
 * `processErpSyncQueueItem`/`pullErpInventoryAndPrices` never know which
 * concrete adapter answered, only that it satisfies `ErpAdapter`.
 */
export class ErpAdapterRegistry {
  private readonly adaptersByType = new Map<string, ErpAdapter>();

  register(adapter: ErpAdapter): void {
    this.adaptersByType.set(adapter.adapterType, adapter);
  }

  resolve(adapterType: string): ErpAdapter {
    const adapter = this.adaptersByType.get(adapterType);
    if (!adapter) {
      throw new HttpsError(
        'failed-precondition',
        `Nenhum adapter de ERP registrado para "${adapterType}".`,
      );
    }
    return adapter;
  }

  has(adapterType: string): boolean {
    return this.adaptersByType.has(adapterType);
  }
}

/** Default, process-wide registry every Cloud Function in this feature
 * shares — pre-populated with the reference adapter
 * (`GenericRestErpAdapter`). A concrete ERP adapter is added here, never by
 * editing `process-erp-sync-queue-item.ts`/`pull-erp-inventory-and-prices.ts`. */
export function buildDefaultErpAdapterRegistry(): ErpAdapterRegistry {
  const registry = new ErpAdapterRegistry();
  registry.register(new GenericRestErpAdapter());
  return registry;
}

import { HttpsError } from 'firebase-functions/v2/https';

import type {
  ErpAdapter,
  ErpIntegrationConfig,
  ErpIntegrationCredentials,
  ErpPullRecord,
  ErpPushCustomerInput,
  ErpPushOrderInput,
  ErpPushResult,
} from '../types';

/**
 * Reference `ErpAdapter` implementation (TASK-169: "Implementar um adapter
 * de referência... para servir de exemplo e cobrir ERPs que só expõem
 * exportação de arquivo"). Talks to a generic, configurable REST endpoint —
 * every concrete ERP (SAP, TOTVS, Linx, ...) this framework will eventually
 * support either exposes something REST-shaped directly, or sits behind a
 * middleware/iPaaS that does, so this single reference implementation
 * exercises the entire queue/mapping/conflict pipeline end-to-end without
 * requiring a real ERP contract to exist yet.
 *
 * Every endpoint/method is configured per organization via
 * `ErpIntegrationConfig.connection` (never hard-coded), and the only secret
 * this adapter ever reads is `credentials.secrets.bearerToken` — never
 * logged, never echoed back.
 */
export class GenericRestErpAdapter implements ErpAdapter {
  readonly adapterType = 'generic_rest';

  constructor(
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async pullInventory(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
  ): Promise<ErpPullRecord[]> {
    return this.pullRecords(config, credentials, 'inventoryEndpoint');
  }

  async pullPrices(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
  ): Promise<ErpPullRecord[]> {
    return this.pullRecords(config, credentials, 'priceEndpoint');
  }

  async pushOrder(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
    input: ErpPushOrderInput,
  ): Promise<ErpPushResult> {
    const endpoint = this.requireEndpoint(config, 'orderEndpoint');
    const response = await this.fetchImpl(this.buildUrl(config, endpoint), {
      method: 'POST',
      headers: this.buildHeaders(credentials),
      body: JSON.stringify(input.payload),
    });
    return this.parsePushResponse(response, input.orderId);
  }

  async pushCustomer(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
    input: ErpPushCustomerInput,
  ): Promise<ErpPushResult> {
    const endpoint = this.requireEndpoint(config, 'customerEndpoint');
    const response = await this.fetchImpl(this.buildUrl(config, endpoint), {
      method: 'POST',
      headers: this.buildHeaders(credentials),
      body: JSON.stringify(input.payload),
    });
    return this.parsePushResponse(response, input.customerId);
  }

  private async pullRecords(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
    endpointKey: 'inventoryEndpoint' | 'priceEndpoint',
  ): Promise<ErpPullRecord[]> {
    const endpoint = this.requireEndpoint(config, endpointKey);
    const response = await this.fetchImpl(this.buildUrl(config, endpoint), {
      method: 'GET',
      headers: this.buildHeaders(credentials),
    });
    if (!response.ok) {
      throw new HttpsError(
        'unavailable',
        `ERP respondeu ${response.status} ao consultar ${endpointKey}.`,
      );
    }
    const body = (await response.json()) as unknown;
    if (!Array.isArray(body)) {
      throw new HttpsError(
        'failed-precondition',
        `Resposta do ERP para ${endpointKey} não é uma lista de registros.`,
      );
    }
    return body.map((entry, index) => this.parsePullRecord(entry, index));
  }

  private parsePullRecord(entry: unknown, index: number): ErpPullRecord {
    if (entry === null || typeof entry !== 'object') {
      throw new HttpsError(
        'failed-precondition',
        `Registro ${index} retornado pelo ERP não é um objeto.`,
      );
    }
    const record = entry as Record<string, unknown>;
    const externalId = record.id ?? record.externalId ?? record.codigo;
    const sourceVersion =
      record.updatedAt ?? record.version ?? record.dataAtualizacao;
    if (typeof externalId !== 'string' && typeof externalId !== 'number') {
      throw new HttpsError(
        'failed-precondition',
        `Registro ${index} retornado pelo ERP não possui identificador.`,
      );
    }
    return {
      externalId: String(externalId),
      rawFields: record,
      sourceVersion: sourceVersion === undefined ? '' : String(sourceVersion),
    };
  }

  private async parsePushResponse(
    response: Response,
    fallbackId: string,
  ): Promise<ErpPushResult> {
    if (!response.ok) {
      throw new HttpsError(
        'unavailable',
        `ERP respondeu ${response.status} ao receber o envio.`,
      );
    }
    const body = (await response.json().catch(() => null)) as {
      id?: unknown;
      externalId?: unknown;
    } | null;
    const externalId = body?.externalId ?? body?.id ?? fallbackId;
    return { externalId: String(externalId) };
  }

  private requireEndpoint(
    config: ErpIntegrationConfig,
    key: string,
  ): string {
    const endpoint = config.connection?.[key];
    if (typeof endpoint !== 'string' || endpoint.trim().length === 0) {
      throw new HttpsError(
        'failed-precondition',
        `Configuração de integração não define "${key}".`,
      );
    }
    return endpoint;
  }

  private buildUrl(config: ErpIntegrationConfig, endpoint: string): string {
    const baseUrl = config.connection?.baseUrl;
    if (typeof baseUrl !== 'string' || baseUrl.trim().length === 0) {
      throw new HttpsError(
        'failed-precondition',
        'Configuração de integração não define "baseUrl".',
      );
    }
    return `${baseUrl.replace(/\/+$/, '')}/${endpoint.replace(/^\/+/, '')}`;
  }

  private buildHeaders(
    credentials: ErpIntegrationCredentials,
  ): Record<string, string> {
    const bearerToken = credentials.secrets?.bearerToken;
    if (typeof bearerToken !== 'string' || bearerToken.trim().length === 0) {
      throw new HttpsError(
        'failed-precondition',
        'Credenciais de integração não definem "bearerToken".',
      );
    }
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${bearerToken}`,
    };
  }
}

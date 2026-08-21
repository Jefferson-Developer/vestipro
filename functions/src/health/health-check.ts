import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';

export type HealthCheckRequest = RequestWithMeta;

export interface HealthCheckResponse {
  status: 'ok';
  serverTimestamp: string;
  correlationId: string;
  authenticated: boolean;
}

/**
 * Callable function with no business logic, used only to validate the
 * Cloud Functions pipeline end to end (deploy, auth, correlation id,
 * client wrapper, error handling) — see TASK-015. Every future domain
 * function under `src/pricing`, `src/orders`, `src/insights`, `src/auth`
 * and `src/admin` must validate the caller's real organization membership
 * server-side before doing anything; this function does not, because it
 * has no tenant-scoped operation to authorize.
 */
export const healthCheck = onCall<HealthCheckRequest, HealthCheckResponse>(
  (request) => {
    const correlationId = resolveCorrelationId(request.data?._meta);

    logger.info('healthCheck invoked', {
      correlationId,
      authenticated: request.auth != null,
    });

    return {
      status: 'ok',
      serverTimestamp: new Date().toISOString(),
      correlationId,
      authenticated: request.auth != null,
    };
  },
);

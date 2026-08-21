import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { healthCheck, type HealthCheckRequest } from '../src/health/health-check';

const testEnv = functionsTest();

function buildRequest(
  data: HealthCheckRequest,
  auth?: CallableRequest<HealthCheckRequest>['auth'],
): CallableRequest<HealthCheckRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<HealthCheckRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

describe('healthCheck', () => {
  afterAll(() => {
    testEnv.cleanup();
  });

  it('returns status ok with a server timestamp and echoes the correlation id sent under _meta', async () => {
    const wrapped = testEnv.wrap(healthCheck);

    const result = await wrapped(
      buildRequest({ _meta: { correlationId: 'test-correlation-id' } }),
    );

    expect(result.status).toBe('ok');
    expect(result.correlationId).toBe('test-correlation-id');
    expect(typeof result.serverTimestamp).toBe('string');
    expect(new Date(result.serverTimestamp).toString()).not.toBe('Invalid Date');
  });

  it('generates a correlation id when the caller sends no _meta', async () => {
    const wrapped = testEnv.wrap(healthCheck);

    const result = await wrapped(buildRequest({}));

    expect(result.correlationId).toBeTruthy();
    expect(result.correlationId.length).toBeGreaterThan(0);
  });

  it('reports authenticated as false for an unauthenticated call', async () => {
    const wrapped = testEnv.wrap(healthCheck);

    const result = await wrapped(buildRequest({}));

    expect(result.authenticated).toBe(false);
  });

  it('reports authenticated as true when the call carries an auth context', async () => {
    const wrapped = testEnv.wrap(healthCheck);

    const auth = {
      uid: 'user-1',
      rawToken: 'raw-token',
    } as CallableRequest<HealthCheckRequest>['auth'];
    const result = await wrapped(buildRequest({}, auth));

    expect(result.authenticated).toBe(true);
  });
});

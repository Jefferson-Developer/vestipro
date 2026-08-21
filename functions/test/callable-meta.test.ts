import { resolveCorrelationId } from '../src/shared/callable-meta';

describe('resolveCorrelationId', () => {
  it('returns the correlation id sent by the caller', () => {
    expect(resolveCorrelationId({ correlationId: 'from-client' })).toBe('from-client');
  });

  it('generates a new correlation id when meta is undefined', () => {
    const result = resolveCorrelationId(undefined);

    expect(result).toBeTruthy();
    expect(result.length).toBeGreaterThan(0);
  });

  it('generates a new correlation id when the caller sent an empty string', () => {
    const result = resolveCorrelationId({ correlationId: '   ' });

    expect(result).toBeTruthy();
    expect(result).not.toBe('   ');
  });
});

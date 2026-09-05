import { computeNextRunAt, cycleKeyFor } from '../../src/reports/report-schedules-shared';

describe('computeNextRunAt (TASK-149)', () => {
  test('daily: rolls to the next day when the time already passed today', () => {
    // 2026-09-05 12:00 UTC = 09:00 em São Paulo (UTC-3).
    const from = new Date('2026-09-05T12:00:00.000Z');
    const next = computeNextRunAt(
      { frequency: 'daily', hour: 8, minute: 0 },
      from,
    );
    // 08:00 São Paulo já passou (09:00) => próxima ocorrência é amanhã 08:00
    // São Paulo = 11:00 UTC.
    expect(next.toISOString()).toBe('2026-09-06T11:00:00.000Z');
  });

  test('daily: same day when the time has not passed yet', () => {
    const from = new Date('2026-09-05T10:00:00.000Z'); // 07:00 São Paulo
    const next = computeNextRunAt(
      { frequency: 'daily', hour: 8, minute: 0 },
      from,
    );
    expect(next.toISOString()).toBe('2026-09-05T11:00:00.000Z');
  });

  test('weekly: finds the next occurrence of the target weekday, never today if already past', () => {
    // 2026-09-05 é um sábado (weekday ISO 6).
    const from = new Date('2026-09-05T12:00:00.000Z'); // sábado 09:00 SP
    const next = computeNextRunAt(
      { frequency: 'weekly', weekday: 1, hour: 8, minute: 0 }, // segunda-feira
      from,
    );
    // Próxima segunda-feira é 2026-09-07, 08:00 SP = 11:00 UTC.
    expect(next.toISOString()).toBe('2026-09-07T11:00:00.000Z');
  });

  test('weekly: same weekday but time already passed rolls a full week forward', () => {
    const from = new Date('2026-09-07T12:00:00.000Z'); // segunda-feira, 09:00 SP
    const next = computeNextRunAt(
      { frequency: 'weekly', weekday: 1, hour: 8, minute: 0 },
      from,
    );
    expect(next.toISOString()).toBe('2026-09-14T11:00:00.000Z');
  });

  test('monthly: rolls to the next month when the day already passed', () => {
    const from = new Date('2026-09-05T12:00:00.000Z'); // dia 5, 09:00 SP
    const next = computeNextRunAt(
      { frequency: 'monthly', dayOfMonth: 1, hour: 8, minute: 0 },
      from,
    );
    expect(next.toISOString()).toBe('2026-10-01T11:00:00.000Z');
  });

  test('monthly: clamps an out-of-range dayOfMonth to 28 so every month always has it', () => {
    const from = new Date('2026-01-01T00:00:00.000Z');
    const next = computeNextRunAt(
      { frequency: 'monthly', dayOfMonth: 31, hour: 8, minute: 0 },
      from,
    );
    expect(next.getUTCDate()).toBe(28);
  });

  test('always returns an instant strictly after `from`', () => {
    const from = new Date('2026-09-05T11:00:00.000Z');
    for (const timing of [
      { frequency: 'daily' as const, hour: 8, minute: 0 },
      { frequency: 'weekly' as const, weekday: 6, hour: 9, minute: 0 },
      { frequency: 'monthly' as const, dayOfMonth: 5, hour: 8, minute: 0 },
    ]) {
      const next = computeNextRunAt(timing, from);
      expect(next.getTime()).toBeGreaterThan(from.getTime());
    }
  });
});

describe('cycleKeyFor (TASK-149)', () => {
  test('is a deterministic ISO string of the due instant', () => {
    const nextRunAt = new Date('2026-09-06T11:00:00.000Z');
    expect(cycleKeyFor(nextRunAt)).toBe('2026-09-06T11:00:00.000Z');
    expect(cycleKeyFor(nextRunAt)).toBe(cycleKeyFor(new Date(nextRunAt)));
  });
});

import { Timestamp } from 'firebase-admin/firestore';

import {
  computeNpsScore,
  npsAggregateDocId,
  npsCategoryOf,
  npsSurveyExpiresAt,
  npsSurveyRequestDocId,
  optionalComment,
  requireScore,
  resolveNpsSurveyOutcome,
} from '../../src/nps/nps-shared';

describe('npsCategoryOf', () => {
  it('classifies 9 and 10 as promoter', () => {
    expect(npsCategoryOf(9)).toBe('promoter');
    expect(npsCategoryOf(10)).toBe('promoter');
  });

  it('classifies 7 and 8 as passive', () => {
    expect(npsCategoryOf(7)).toBe('passive');
    expect(npsCategoryOf(8)).toBe('passive');
  });

  it('classifies 0 through 6 as detractor', () => {
    expect(npsCategoryOf(0)).toBe('detractor');
    expect(npsCategoryOf(6)).toBe('detractor');
  });
});

describe('computeNpsScore', () => {
  it('computes (promoters - detractors) / total * 100', () => {
    expect(computeNpsScore(6, 2, 10)).toBe(40);
  });

  it('returns null (never 0/NaN) for zero respondents', () => {
    expect(computeNpsScore(0, 0, 0)).toBeNull();
  });

  it('can return a negative score when detractors outnumber promoters', () => {
    expect(computeNpsScore(1, 5, 10)).toBe(-40);
  });

  it('rounds to one decimal place', () => {
    expect(computeNpsScore(1, 1, 3)).toBe(0);
    expect(computeNpsScore(2, 1, 6)).toBe(16.7);
  });
});

describe('requireScore', () => {
  it('accepts every integer from 0 to 10', () => {
    for (let score = 0; score <= 10; score += 1) {
      expect(requireScore(score)).toBe(score);
    }
  });

  it('rejects a non-integer, out-of-range or non-numeric value', () => {
    expect(() => requireScore(10.5)).toThrow();
    expect(() => requireScore(11)).toThrow();
    expect(() => requireScore(-1)).toThrow();
    expect(() => requireScore('9')).toThrow();
    expect(() => requireScore(undefined)).toThrow();
  });
});

describe('optionalComment', () => {
  it('trims and returns a non-empty comment', () => {
    expect(optionalComment('  Ótimo atendimento!  ')).toBe('Ótimo atendimento!');
  });

  it('returns null for an absent/blank/non-string comment', () => {
    expect(optionalComment(undefined)).toBeNull();
    expect(optionalComment('   ')).toBeNull();
    expect(optionalComment(42)).toBeNull();
  });

  it('truncates a comment beyond the maximum length instead of rejecting it', () => {
    const long = 'a'.repeat(1500);
    expect(optionalComment(long)?.length).toBe(1000);
  });
});

describe('npsSurveyRequestDocId / npsAggregateDocId', () => {
  it('derives the survey id from order + milestone (never client-supplied)', () => {
    expect(npsSurveyRequestDocId('order-1', 'delivered')).toBe('order-1_delivered');
  });

  it('derives the aggregate id from company + scope + scopeId + period', () => {
    expect(npsAggregateDocId('company-1', 'seller', 'seller-1', '2026-08')).toBe(
      'company-1_seller_seller-1_2026-08',
    );
  });
});

describe('npsSurveyExpiresAt', () => {
  it('expires 30 days after now', () => {
    const now = Timestamp.fromDate(new Date('2026-08-01T00:00:00.000Z'));
    const expiresAt = npsSurveyExpiresAt(now);
    expect(expiresAt.toDate().toISOString()).toBe('2026-08-31T00:00:00.000Z');
  });
});

describe('resolveNpsSurveyOutcome', () => {
  const now = Timestamp.fromDate(new Date('2026-08-15T00:00:00.000Z'));

  it('trusts a stored "answered" status regardless of expiration', () => {
    expect(
      resolveNpsSurveyOutcome(
        { status: 'answered', expiresAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00.000Z')) },
        now,
      ),
    ).toBe('answered');
  });

  it('computes "expired" lazily from expiresAt, never from a stored value', () => {
    expect(
      resolveNpsSurveyOutcome(
        { status: 'pending', expiresAt: Timestamp.fromDate(new Date('2026-08-01T00:00:00.000Z')) },
        now,
      ),
    ).toBe('expired');
  });

  it('resolves "pending" for a not-yet-expired, not-yet-answered survey', () => {
    expect(
      resolveNpsSurveyOutcome(
        { status: 'pending', expiresAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00.000Z')) },
        now,
      ),
    ).toBe('pending');
  });
});

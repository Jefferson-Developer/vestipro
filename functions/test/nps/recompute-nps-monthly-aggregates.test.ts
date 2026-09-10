import {
  buildNpsAggregateBuckets,
  resolveAffectedNpsPeriod,
  type NpsResponseFact,
} from '../../src/nps/recompute-nps-monthly-aggregates';

describe('resolveAffectedNpsPeriod', () => {
  const validData = { organizationId: 'org-1', companyId: 'company-1', periodKey: '2026-08' };

  it('resolves organization/company/period from the "after" snapshot on create', () => {
    expect(resolveAffectedNpsPeriod(undefined, validData)).toEqual(validData);
  });

  it('falls back to "before" on delete (after is undefined)', () => {
    expect(resolveAffectedNpsPeriod(validData, undefined)).toEqual(validData);
  });

  it('returns null for a malformed document', () => {
    expect(resolveAffectedNpsPeriod(undefined, { organizationId: 'org-1' })).toBeNull();
  });
});

describe('buildNpsAggregateBuckets', () => {
  function fact(overrides: Partial<NpsResponseFact> = {}): NpsResponseFact {
    return { sellerId: overrides.sellerId ?? 'seller-1', category: overrides.category ?? 'promoter' };
  }

  it('aggregates promoters/passives/detractors for the organization scope', () => {
    const facts: NpsResponseFact[] = [
      fact({ category: 'promoter' }),
      fact({ category: 'promoter' }),
      fact({ category: 'passive' }),
      fact({ category: 'detractor' }),
    ];
    const buckets = buildNpsAggregateBuckets('company-1', facts, new Map());
    const organizationBucket = buckets.find((bucket) => bucket.scope === 'organization');
    expect(organizationBucket).toEqual({
      scope: 'organization',
      scopeId: 'company-1',
      promoters: 2,
      passives: 1,
      detractors: 1,
    });
  });

  it('aggregates one bucket per distinct seller', () => {
    const facts: NpsResponseFact[] = [
      fact({ sellerId: 'seller-1', category: 'promoter' }),
      fact({ sellerId: 'seller-2', category: 'detractor' }),
    ];
    const buckets = buildNpsAggregateBuckets('company-1', facts, new Map());
    const seller1 = buckets.find((bucket) => bucket.scope === 'seller' && bucket.scopeId === 'seller-1');
    const seller2 = buckets.find((bucket) => bucket.scope === 'seller' && bucket.scopeId === 'seller-2');
    expect(seller1).toEqual({ scope: 'seller', scopeId: 'seller-1', promoters: 1, passives: 0, detractors: 0 });
    expect(seller2).toEqual({ scope: 'seller', scopeId: 'seller-2', promoters: 0, passives: 0, detractors: 1 });
  });

  it('aggregates a team bucket only for sellers with a known team', () => {
    const facts: NpsResponseFact[] = [
      fact({ sellerId: 'seller-1', category: 'promoter' }),
      fact({ sellerId: 'seller-2', category: 'promoter' }),
    ];
    const teamIdBySeller = new Map<string, string | null>([
      ['seller-1', 'team-a'],
      ['seller-2', null],
    ]);
    const buckets = buildNpsAggregateBuckets('company-1', facts, teamIdBySeller);
    const teamBuckets = buckets.filter((bucket) => bucket.scope === 'team');
    expect(teamBuckets).toEqual([{ scope: 'team', scopeId: 'team-a', promoters: 1, passives: 0, detractors: 0 }]);
  });

  it('two sellers sharing the same team accumulate into a single team bucket', () => {
    const facts: NpsResponseFact[] = [
      fact({ sellerId: 'seller-1', category: 'promoter' }),
      fact({ sellerId: 'seller-2', category: 'detractor' }),
    ];
    const teamIdBySeller = new Map<string, string | null>([
      ['seller-1', 'team-a'],
      ['seller-2', 'team-a'],
    ]);
    const buckets = buildNpsAggregateBuckets('company-1', facts, teamIdBySeller);
    const teamBucket = buckets.find((bucket) => bucket.scope === 'team');
    expect(teamBucket).toEqual({ scope: 'team', scopeId: 'team-a', promoters: 1, passives: 0, detractors: 1 });
  });

  it('returns just the (empty) organization bucket for a period with no responses', () => {
    const buckets = buildNpsAggregateBuckets('company-1', [], new Map());
    expect(buckets).toEqual([
      { scope: 'organization', scopeId: 'company-1', promoters: 0, passives: 0, detractors: 0 },
    ]);
  });
});

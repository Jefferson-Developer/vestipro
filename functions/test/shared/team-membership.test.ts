import { membersShareTeam } from '../../src/shared/team-membership';

function buildFakeDb(teamIdsByUid: Record<string, string[] | undefined>): any {
  return {
    collection: (top: string) => ({
      doc: (orgId: string) => ({
        collection: (sub: string) => ({
          doc: (uid: string) => ({
            get: async () => {
              if (top !== 'organizations' || sub !== 'members') {
                return { data: () => undefined };
              }
              void orgId;
              return { data: () => (teamIdsByUid[uid] ? { teamIds: teamIdsByUid[uid] } : undefined) };
            },
          }),
        }),
      }),
    }),
  };
}

describe('membersShareTeam', () => {
  const organizationId = 'org-1';

  it('returns true when both members share at least one team', async () => {
    const db = buildFakeDb({
      'manager-1': ['team-a'],
      'seller-1': ['team-a', 'team-b'],
    });
    const result = await membersShareTeam({ db, organizationId, uidA: 'manager-1', uidB: 'seller-1' });
    expect(result).toBe(true);
  });

  it('returns false when neither member has any overlapping team', async () => {
    const db = buildFakeDb({
      'manager-1': ['team-x'],
      'seller-1': ['team-a'],
    });
    const result = await membersShareTeam({ db, organizationId, uidA: 'manager-1', uidB: 'seller-1' });
    expect(result).toBe(false);
  });

  it('returns false when a member document has no teamIds at all', async () => {
    const db = buildFakeDb({});
    const result = await membersShareTeam({ db, organizationId, uidA: 'manager-1', uidB: 'seller-1' });
    expect(result).toBe(false);
  });
});

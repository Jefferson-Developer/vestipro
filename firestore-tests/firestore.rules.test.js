/**
 * Testes positivos e negativos de `firestore.rules` (TASK-030).
 *
 * Roda contra o Firebase Emulator Suite (Firestore), nunca contra produção.
 * Uso (a partir da raiz do repositório):
 *
 *   firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
 *
 * `initializeTestEnvironment` detecta o host/porta do emulador via as
 * variáveis de ambiente que `firebase emulators:exec` já exporta
 * (`FIRESTORE_EMULATOR_HOST`); por isso não hardcodamos host/porta aqui.
 */

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

const ORG_A = 'org-a';
const ORG_B = 'org-b';

const now = () => new Date();

function organizationDoc(overrides = {}) {
  return {
    name: 'Malwee Confecções',
    slug: 'malwee',
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
    ...overrides,
  };
}

function membershipDoc({ organizationId, userId, roleId, roleName, status = 'active' }) {
  return {
    organizationId,
    userId,
    roleId,
    roleName,
    teamIds: [],
    status,
    version: 1,
    createdAt: now(),
    createdBy: userId,
    updatedAt: now(),
    updatedBy: userId,
  };
}

function roleDoc({ organizationId, name, isSystemRole }) {
  return {
    organizationId,
    name,
    isSystemRole,
    version: 1,
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
  };
}

function companyDoc({ organizationId }) {
  return {
    organizationId,
    name: 'Malwee Matriz',
    status: 'active',
    version: 1,
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
  };
}

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'vestipro-rules-test',
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // Seed sem passar pelas Rules (dados de fixture: Org A com OWNER e
  // SALES_REP ativos + 1 Company; Org B com seu próprio OWNER).
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await db.doc(`organizations/${ORG_A}`).set(organizationDoc({ createdBy: 'owner-a', updatedBy: 'owner-a' }));
    await db.doc(`organizations/${ORG_A}/roles/OWNER`).set(roleDoc({ organizationId: ORG_A, name: 'OWNER', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/roles/SALES_REP`).set(roleDoc({ organizationId: ORG_A, name: 'SALES_REP', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/members/owner-a`).set(
      membershipDoc({ organizationId: ORG_A, userId: 'owner-a', roleId: 'OWNER', roleName: 'OWNER' }),
    );
    await db.doc(`organizations/${ORG_A}/members/rep-a`).set(
      membershipDoc({ organizationId: ORG_A, userId: 'rep-a', roleId: 'SALES_REP', roleName: 'SALES_REP' }),
    );
    await db.doc(`organizations/${ORG_A}/companies/company-a`).set(companyDoc({ organizationId: ORG_A }));

    await db.doc(`organizations/${ORG_B}`).set(organizationDoc({ createdBy: 'owner-b', updatedBy: 'owner-b' }));
    await db.doc(`organizations/${ORG_B}/roles/OWNER`).set(roleDoc({ organizationId: ORG_B, name: 'OWNER', isSystemRole: true }));
    await db.doc(`organizations/${ORG_B}/members/owner-b`).set(
      membershipDoc({ organizationId: ORG_B, userId: 'owner-b', roleId: 'OWNER', roleName: 'OWNER' }),
    );
    await db.doc(`organizations/${ORG_B}/companies/company-b`).set(companyDoc({ organizationId: ORG_B }));
  });
});

describe('organizations/{organizationId}', () => {
  test('membro ativo consegue ler o doc da própria organization', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}`).get());
  });

  test('usuário não autenticado não le nenhuma organization', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc(`organizations/${ORG_A}`).get());
  });

  test('membro da Org A não consegue ler a Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}`).get());
  });

  test('OWNER consegue atualizar settings (organization.settingsManage)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}`).update({
        settings: { currency: 'USD', country: 'BR', defaultLanguage: 'pt-BR' },
        updatedAt: now(),
        updatedBy: 'owner-a',
      }),
    );
  });

  test('SALES_REP não consegue atualizar settings (sem capability)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}`).update({
        settings: { currency: 'USD', country: 'BR', defaultLanguage: 'pt-BR' },
        updatedAt: now(),
        updatedBy: 'rep-a',
      }),
    );
  });

  test('não é possível alterar o slug (campo imutável) mesmo com capability', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}`).update({
        slug: 'novo-slug',
        updatedAt: now(),
        updatedBy: 'owner-a',
      }),
    );
  });

  test('bootstrap: um novo usuário autenticado pode criar sua própria Organization', async () => {
    const db = testEnv.authenticatedContext('new-founder').firestore();
    await assertSucceeds(
      db.doc('organizations/org-new').set(
        organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }),
      ),
    );
  });

  test('bootstrap: não é possível criar uma Organization em nome de outro usuário', async () => {
    const db = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      db.doc('organizations/org-new').set(
        organizationDoc({ createdBy: 'victim', updatedBy: 'attacker' }),
      ),
    );
  });
});

describe('organizations/{organizationId}/companies/{companyId}', () => {
  test('membro ativo da Org A le a Company da Org A', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/companies/company-a`).get());
  });

  test('membro da Org A não le a Company da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/companies/company-b`).get());
  });

  test('OWNER consegue criar Company na própria organization', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/companies/company-new`).set(companyDoc({ organizationId: ORG_A })),
    );
  });

  test('SALES_REP não consegue criar Company (sem company.manage)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/companies/company-new`).set(companyDoc({ organizationId: ORG_A })),
    );
  });

  test('SALES_REP não consegue excluir Company (sem company.manage)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/companies/company-a`).delete());
  });

  test('OWNER consegue excluir Company da própria organization', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/companies/company-a`).delete());
  });

  test(
    'usuário sem Membership na Org B não cria Company lá mesmo forjando organizationId no payload',
    async () => {
      const db = testEnv.authenticatedContext('owner-a').firestore();
      await assertFails(
        db.doc(`organizations/${ORG_B}/companies/forged`).set(companyDoc({ organizationId: ORG_B })),
      );
    },
  );

  test('não é possível mudar organizationId em um update de Company', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/companies/company-a`).update({ organizationId: ORG_B }),
    );
  });
});

describe('organizations/{organizationId}/roles/{roleId}', () => {
  test('membro ativo le os roles da própria organization', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/roles/OWNER`).get());
  });

  test('não é possível renomear um system role (OWNER)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/roles/OWNER`).update({ name: 'SUPER_OWNER' }),
    );
  });

  test('não é possível excluir um system role (OWNER)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/roles/OWNER`).delete());
  });

  test('OWNER consegue criar um role custom (não system)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/roles/custom-role-1`).set(
        roleDoc({ organizationId: ORG_A, name: 'Custom Role', isSystemRole: false }),
      ),
    );
  });

  test('SALES_REP não consegue criar um role custom (sem role.manage)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/roles/custom-role-1`).set(
        roleDoc({ organizationId: ORG_A, name: 'Custom Role', isSystemRole: false }),
      ),
    );
  });

  test('bootstrap: criador da organization semeia os 7 system roles antes de ter Membership', async () => {
    const db = testEnv.authenticatedContext('new-founder').firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc('organizations/org-new')
        .set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
    });

    await assertSucceeds(
      db.doc('organizations/org-new/roles/OWNER').set(
        roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }),
      ),
    );
  });

  test('bootstrap de system role é negado para quem não é o criador da organization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc('organizations/org-new')
        .set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
    });

    const db = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      db.doc('organizations/org-new/roles/OWNER').set(
        roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }),
      ),
    );
  });
});

describe('organizations/{organizationId}/members/{userId}  (Membership)', () => {
  test('membro ativo le os members da própria organization', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/members/owner-a`).get());
  });

  test('membro da Org A não le members da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/members/owner-b`).get());
  });

  test('OWNER consegue convidar (criar Membership) um novo usuário', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/members/new-hire`).set(
        membershipDoc({ organizationId: ORG_A, userId: 'new-hire', roleId: 'SALES_REP', roleName: 'SALES_REP' }),
      ),
    );
  });

  test('SALES_REP não consegue convidar (sem user.invite)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/members/new-hire`).set(
        membershipDoc({ organizationId: ORG_A, userId: 'new-hire', roleId: 'SALES_REP', roleName: 'SALES_REP' }),
      ),
    );
  });

  test('OWNER consegue trocar a role de um membro (user.changeRole)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/members/rep-a`).update({
        roleId: 'SALES_MANAGER',
        roleName: 'SALES_MANAGER',
        updatedAt: now(),
        updatedBy: 'owner-a',
      }),
    );
  });

  test('SALES_REP não consegue trocar a própria role (sem user.changeRole)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/members/rep-a`).update({
        roleId: 'OWNER',
        roleName: 'OWNER',
        updatedAt: now(),
        updatedBy: 'rep-a',
      }),
    );
  });

  test('bootstrap: criador da organization concede a si mesmo o Membership OWNER', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('organizations/org-new').set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
      await db.doc('organizations/org-new/roles/OWNER').set(roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }));
    });

    const db = testEnv.authenticatedContext('new-founder').firestore();
    await assertSucceeds(
      db.doc('organizations/org-new/members/new-founder').set(
        membershipDoc({ organizationId: 'org-new', userId: 'new-founder', roleId: 'OWNER', roleName: 'OWNER' }),
      ),
    );
  });

  test('bootstrap de Membership OWNER é negado para quem não é o criador da organization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('organizations/org-new').set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
      await db.doc('organizations/org-new/roles/OWNER').set(roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }));
    });

    const db = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      db.doc('organizations/org-new/members/attacker').set(
        membershipDoc({ organizationId: 'org-new', userId: 'attacker', roleId: 'OWNER', roleName: 'OWNER' }),
      ),
    );
  });

  test('Membership inativo perde acesso de leitura à organization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/members/rep-a`)
        .set(membershipDoc({ organizationId: ORG_A, userId: 'rep-a', roleId: 'SALES_REP', roleName: 'SALES_REP', status: 'inactive' }));
    });

    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/companies/company-a`).get());
  });
});

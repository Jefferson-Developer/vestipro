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

function membershipDoc({ organizationId, userId, roleId, roleName, teamIds = [], status = 'active' }) {
  return {
    organizationId,
    userId,
    roleId,
    roleName,
    teamIds,
    status,
    version: 1,
    createdAt: now(),
    createdBy: userId,
    updatedAt: now(),
    updatedBy: userId,
  };
}

function teamDoc({ organizationId, name = 'Equipe Sul', managerUserId = 'manager-a', memberIds = ['rep-a'] }) {
  return {
    organizationId,
    name,
    companyId: 'company-a',
    branchId: null,
    managerUserId,
    memberIds,
    version: 1,
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
    deletedAt: null,
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

function customerDoc({ organizationId, companyId = 'company-a', primarySalesRepId, teamId, deletedAt = null }) {
  return {
    organizationId,
    companyId,
    name: 'Cliente Teste',
    primarySalesRepId,
    teamId,
    deletedAt,
    version: 1,
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
  };
}

function portfolioAssignmentDoc({
  organizationId,
  companyId = 'company-a',
  userId = 'rep-a',
  teamId = 'team-a',
  scopeType = 'customer',
  customerId = 'customer-a',
  region = null,
  segment = null,
  status = 'active',
}) {
  return {
    organizationId,
    companyId,
    userId,
    teamId,
    scopeType,
    customerId,
    region,
    segment,
    status,
    version: 1,
    createdAt: now(),
    createdBy: 'manager-a',
    updatedAt: now(),
    updatedBy: 'manager-a',
    endedAt: null,
    endedBy: null,
    deletedAt: null,
  };
}

function userProfileDoc({ uid, overrides = {} }) {
  return {
    uid,
    name: 'Usuário de Teste',
    email: 'usuario@vestipro.com.br',
    createdAt: now(),
    termsVersion: '2026-08-23',
    termsAcceptedAt: now(),
    ...overrides,
  };
}

function inviteDoc({ organizationId, email = 'novo@vestipro.com.br', roleName = 'SALES_REP', status = 'pending' }) {
  return {
    organizationId,
    email,
    roleName,
    status,
    tokenHash: 'fake-hash-for-tests',
    invitedByUserId: 'owner-a',
    invitedByName: 'Owner A',
    message: null,
    expiresAt: now(),
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
  };
}

function productDoc({ organizationId, deletedAt = null }) {
  return {
    organizationId,
    companyId: 'company-a',
    sku: 'CAMISA-001',
    reference: 'REF-001',
    name: 'Camisa Basica',
    tags: ['lancamento'],
    status: 'active',
    deletedAt,
    searchText: 'camisa basica camisa 001 ref 001 lancamento',
    searchPrefixes: ['c', 'ca', 'cam', 'camisa', 'ref', 'lancamento'],
    version: 1,
    createdAt: now(),
    createdBy: 'owner-a',
    updatedAt: now(),
    updatedBy: 'owner-a',
    syncStatus: 'synced',
  };
}

function favoriteDoc({ organizationId, userId = 'rep-a', productId = 'product-a', companyId = 'company-a' }) {
  return {
    organizationId,
    userId,
    productId,
    companyId,
    createdAt: now(),
  };
}

function catalogShareDoc({
  organizationId,
  createdBy = 'rep-a',
  status = 'active',
  expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
}) {
  return {
    organizationId,
    scope: 'product',
    items: [{ productId: 'product-a', name: 'Camisa Linho', imageUrl: null }],
    collectionId: null,
    collectionName: null,
    tokenHash: 'fake-hash-for-tests',
    status,
    openCount: 0,
    firstOpenedAt: null,
    lastOpenedAt: null,
    expiresAt,
    createdBy,
    createdByName: 'Rep A',
    createdAt: now(),
    updatedAt: now(),
  };
}

function priceListDoc({
  organizationId,
  companyId = 'company-a',
  name = 'Tabela Padrão',
  currency = 'BRL',
  validFrom = now(),
  validTo = null,
  status = 'active',
  scope = 'company',
  scopeValue = null,
  priority = 0,
  createdBy = 'owner-a',
}) {
  return {
    organizationId,
    companyId,
    name,
    currency,
    validFrom,
    validTo,
    status,
    scope,
    scopeValue,
    priority,
    createdAt: now(),
    createdBy,
    updatedAt: now(),
    updatedBy: createdBy,
    deletedAt: null,
    version: 1,
    syncStatus: 'synced',
  };
}

function warehouseDoc({
  organizationId,
  companyId = 'company-a',
  branchId = null,
  code = 'CD-01',
  name = 'Centro de Distribuicao',
  type = 'distributionCenter',
  isActive = true,
  priority = 0,
  createdBy = 'owner-a',
}) {
  return {
    organizationId,
    companyId,
    branchId,
    code,
    name,
    type,
    isActive,
    priority,
    createdAt: now(),
    createdBy,
    updatedAt: now(),
    updatedBy: createdBy,
    deletedAt: null,
    version: 1,
    syncStatus: 'synced',
  };
}

function orderDoc({
  organizationId,
  companyId = 'company-a',
  sellerId,
  status = 'submitted',
  deletedAt = null,
}) {
  return {
    organizationId,
    companyId,
    branchId: 'branch-a',
    customerId: 'customer-a',
    sellerId,
    orderNumber: '000001',
    deliveryAddress: { street: 'Rua A', city: 'Jaraguá do Sul', state: 'SC', zipCode: '89250-000', country: 'BR' },
    billingAddress: { street: 'Rua A', city: 'Jaraguá do Sul', state: 'SC', zipCode: '89250-000', country: 'BR' },
    priceListId: 'price-list-a',
    paymentTermId: 'payment-term-a',
    items: [],
    discountAmount: 0,
    surchargeAmount: 0,
    shippingAmount: 0,
    taxAmount: null,
    status,
    statusHistory: [],
    approvedBy: null,
    approvedAt: null,
    rejectionReason: null,
    deletedAt,
    version: 1,
    createdAt: now(),
    createdBy: sellerId,
    updatedAt: now(),
    updatedBy: sellerId,
    syncStatus: 'synced',
  };
}

function auditLogDoc({ organizationId, actorUserId, action = 'role.changed' }) {
  return {
    organizationId,
    actorUserId,
    actorName: 'Ator de Teste',
    action,
    entityType: 'membership',
    entityId: 'rep-a',
    previousValue: { roleId: 'SALES_REP', roleName: 'SALES_REP' },
    newValue: { roleId: 'SALES_MANAGER', roleName: 'SALES_MANAGER' },
    timestamp: now(),
  };
}

function salesDailyAggregateDoc({ organizationId, companyId = 'company-a' }) {
  return {
    organizationId,
    companyId,
    dimension: 'salesDaily',
    scopeId: companyId,
    periodKey: '2026-08-15',
    revenueGross: 1500,
    revenueNet: 1450,
    discountAmount: 50,
    orderCount: 2,
    itemQuantity: 20,
    labels: {},
    generatedAt: now(),
    version: 1,
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

describe('organizations/{organizationId}/warehouses/{warehouseId}  (TASK-089)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/warehouses/warehouse-a`)
        .set(warehouseDoc({ organizationId: ORG_A }));
      await db
        .doc(`organizations/${ORG_B}/warehouses/warehouse-b`)
        .set(
          warehouseDoc({
            organizationId: ORG_B,
            companyId: 'company-b',
            createdBy: 'owner-b',
          }),
        );
    });
  });

  test('membro ativo da Org A le warehouse da propria organization', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/warehouses/warehouse-a`).get(),
    );
  });

  test('membro da Org A nao le warehouse da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_B}/warehouses/warehouse-b`).get(),
    );
  });

  test('OWNER consegue criar warehouse na propria organization', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/warehouses/warehouse-new`).set(
        warehouseDoc({ organizationId: ORG_A, createdBy: 'owner-a' }),
      ),
    );
  });

  test('SALES_REP nao consegue criar warehouse (sem inventory.adjust)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/warehouses/warehouse-rep`).set(
        warehouseDoc({ organizationId: ORG_A, createdBy: 'rep-a' }),
      ),
    );
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
    await db.doc(`organizations/${ORG_A}/roles/ADMIN`).set(roleDoc({ organizationId: ORG_A, name: 'ADMIN', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/roles/SALES_MANAGER`).set(roleDoc({ organizationId: ORG_A, name: 'SALES_MANAGER', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/roles/SALES_REP`).set(roleDoc({ organizationId: ORG_A, name: 'SALES_REP', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/roles/FINANCE`).set(roleDoc({ organizationId: ORG_A, name: 'FINANCE', isSystemRole: true }));
    await db.doc(`organizations/${ORG_A}/members/owner-a`).set(
      membershipDoc({ organizationId: ORG_A, userId: 'owner-a', roleId: 'OWNER', roleName: 'OWNER' }),
    );
    await db.doc(`organizations/${ORG_A}/members/admin-a`).set(
      membershipDoc({ organizationId: ORG_A, userId: 'admin-a', roleId: 'ADMIN', roleName: 'ADMIN' }),
    );
    await db.doc(`organizations/${ORG_A}/members/finance-a`).set(
      membershipDoc({ organizationId: ORG_A, userId: 'finance-a', roleId: 'FINANCE', roleName: 'FINANCE' }),
    );
    await db.doc(`organizations/${ORG_A}/members/manager-a`).set(
      membershipDoc({
        organizationId: ORG_A,
        userId: 'manager-a',
        roleId: 'SALES_MANAGER',
        roleName: 'SALES_MANAGER',
        teamIds: ['team-a'],
      }),
    );
    await db.doc(`organizations/${ORG_A}/members/rep-a`).set(
      membershipDoc({
        organizationId: ORG_A,
        userId: 'rep-a',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        teamIds: ['team-a'],
      }),
    );
    await db.doc(`organizations/${ORG_A}/members/rep-b`).set(
      membershipDoc({
        organizationId: ORG_A,
        userId: 'rep-b',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        teamIds: ['team-b'],
      }),
    );
    await db.doc(`organizations/${ORG_A}/companies/company-a`).set(companyDoc({ organizationId: ORG_A }));
    await db.doc(`organizations/${ORG_A}/teams/team-a`).set(
      teamDoc({ organizationId: ORG_A, managerUserId: 'manager-a', memberIds: ['rep-a'] }),
    );
    await db.doc(`organizations/${ORG_A}/teams/team-b`).set(
      teamDoc({ organizationId: ORG_A, name: 'Equipe Norte', managerUserId: 'other-manager', memberIds: ['rep-b'] }),
    );

    await db.doc(`organizations/${ORG_B}`).set(organizationDoc({ createdBy: 'owner-b', updatedBy: 'owner-b' }));
    await db.doc(`organizations/${ORG_B}/roles/OWNER`).set(roleDoc({ organizationId: ORG_B, name: 'OWNER', isSystemRole: true }));
    await db.doc(`organizations/${ORG_B}/members/owner-b`).set(
      membershipDoc({ organizationId: ORG_B, userId: 'owner-b', roleId: 'OWNER', roleName: 'OWNER' }),
    );
    await db.doc(`organizations/${ORG_B}/companies/company-b`).set(companyDoc({ organizationId: ORG_B }));
  });
});

describe('users/{userId}  (basic profile — TASK-035)', () => {
  test('um usuário autenticado consegue criar o próprio perfil', async () => {
    const db = testEnv.authenticatedContext('new-user').firestore();
    await assertSucceeds(
      db.doc('users/new-user').set(userProfileDoc({ uid: 'new-user' })),
    );
  });

  test('não é possível criar o perfil de outro usuário (uid forjado)', async () => {
    const db = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      db.doc('users/victim').set(userProfileDoc({ uid: 'victim' })),
    );
  });

  test('não é possível criar o próprio perfil com o campo uid forjado', async () => {
    const db = testEnv.authenticatedContext('new-user').firestore();
    await assertFails(
      db.doc('users/new-user').set(userProfileDoc({ uid: 'someone-else' })),
    );
  });

  test('usuário não autenticado não consegue criar nenhum perfil', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.doc('users/new-user').set(userProfileDoc({ uid: 'new-user' })),
    );
  });

  test('não é possível criar um perfil sem termsVersion (consentimento ausente)', async () => {
    const db = testEnv.authenticatedContext('new-user').firestore();
    const payload = userProfileDoc({ uid: 'new-user' });
    delete payload.termsVersion;
    await assertFails(db.doc('users/new-user').set(payload));
  });

  test('o próprio usuário consegue ler o próprio perfil', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/owner-a').set(userProfileDoc({ uid: 'owner-a' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.doc('users/owner-a').get());
  });

  test('um usuário não consegue ler o perfil de outro usuário', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/owner-b').set(userProfileDoc({ uid: 'owner-b' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc('users/owner-b').get());
  });

  test('nem o próprio usuário consegue atualizar o perfil por este caminho', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/owner-a').set(userProfileDoc({ uid: 'owner-a' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc('users/owner-a').update({ name: 'Novo Nome' }));
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

  test(
    'organizations não pode mais ser criada diretamente pelo cliente, nem pelo próprio usuário ' +
      'autenticado como createdBy — a criação é exclusiva da Cloud Function createOrganization (TASK-037)',
    async () => {
      const db = testEnv.authenticatedContext('new-founder').firestore();
      await assertFails(
        db.doc('organizations/org-new').set(
          organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }),
        ),
      );
    },
  );

  test('organizations continua negando criação em nome de outro usuário (createdBy forjado)', async () => {
    const db = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      db.doc('organizations/org-new').set(
        organizationDoc({ createdBy: 'victim', updatedBy: 'attacker' }),
      ),
    );
  });
});

describe('organizationOwners/{userId}  (TASK-037)', () => {
  test('cliente nunca lê o próprio marcador de idempotência', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('organizationOwners/owner-a').set({ organizationId: ORG_A });
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc('organizationOwners/owner-a').get());
  });

  test('cliente nunca escreve o próprio marcador de idempotência', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc('organizationOwners/owner-a').set({ organizationId: ORG_A }),
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

  test(
    'system role (OWNER) não pode mais ser semeado diretamente pelo cliente, mesmo pelo criador ' +
      'da organization ainda sem Membership — isso é exclusivo da Cloud Function createOrganization (TASK-037)',
    async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context
          .firestore()
          .doc('organizations/org-new')
          .set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
      });

      const db = testEnv.authenticatedContext('new-founder').firestore();
      await assertFails(
        db.doc('organizations/org-new/roles/OWNER').set(
          roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }),
        ),
      );
    },
  );

  test(
    'mesmo OWNER com role.manage não consegue criar um role marcado isSystemRole: true pelo caminho normal',
    async () => {
      const db = testEnv.authenticatedContext('owner-a').firestore();
      await assertFails(
        db.doc(`organizations/${ORG_A}/roles/FAKE_SYSTEM`).set(
          roleDoc({ organizationId: ORG_A, name: 'FAKE_SYSTEM', isSystemRole: true }),
        ),
      );
    },
  );
});

describe('organizations/{organizationId}/portfolioAssignments/{assignmentId}  (TASK-045)', () => {
  test('SALES_MANAGER consegue criar vínculo de carteira na própria organization', async () => {
    const db = testEnv.authenticatedContext('manager-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/portfolioAssignments/assignment-1`).set(
        portfolioAssignmentDoc({ organizationId: ORG_A }),
      ),
    );
  });

  test('SALES_REP não consegue criar vínculo de carteira', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/portfolioAssignments/assignment-1`).set(
        portfolioAssignmentDoc({ organizationId: ORG_A }),
      ),
    );
  });

  test('reatribuição fecha vínculo sem permitir troca de tenant ou escopo', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/portfolioAssignments/assignment-1`)
        .set(portfolioAssignmentDoc({ organizationId: ORG_A }));
    });

    const db = testEnv.authenticatedContext('manager-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/portfolioAssignments/assignment-1`).update({
        status: 'reassigned',
        endedAt: now(),
        endedBy: 'manager-a',
        updatedAt: now(),
        updatedBy: 'manager-a',
      }),
    );
    await assertFails(
      db.doc(`organizations/${ORG_A}/portfolioAssignments/assignment-1`).update({
        customerId: 'customer-b',
        updatedAt: now(),
        updatedBy: 'manager-a',
      }),
    );
  });

  test('SALES_REP lista apenas os próprios vínculos quando a query filtra userId', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/portfolioAssignments/assignment-rep-a`)
        .set(portfolioAssignmentDoc({ organizationId: ORG_A, userId: 'rep-a' }));
      await db
        .doc(`organizations/${ORG_A}/portfolioAssignments/assignment-rep-b`)
        .set(portfolioAssignmentDoc({ organizationId: ORG_A, userId: 'rep-b', customerId: 'customer-b', teamId: 'team-b' }));
    });

    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db
        .collection(`organizations/${ORG_A}/portfolioAssignments`)
        .where('userId', '==', 'rep-a')
        .get(),
    );
    await assertFails(
      db
        .collection(`organizations/${ORG_A}/portfolioAssignments`)
        .where('userId', '==', 'rep-b')
        .get(),
    );
  });
});

describe('organizations/{organizationId}/customers/{customerId}  (TASK-045 visibility contract)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/customers/customer-a`)
        .set(customerDoc({ organizationId: ORG_A, primarySalesRepId: 'rep-a', teamId: 'team-a' }));
      await db
        .doc(`organizations/${ORG_A}/customers/customer-b`)
        .set(customerDoc({ organizationId: ORG_A, primarySalesRepId: 'rep-b', teamId: 'team-b' }));
      await db
        .doc(`organizations/${ORG_B}/customers/customer-other-tenant`)
        .set(customerDoc({ organizationId: ORG_B, companyId: 'company-b', primarySalesRepId: 'owner-b', teamId: 'team-x' }));
    });
  });

  test('SALES_REP lê cliente da própria carteira', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/customers/customer-a`).get());
  });

  test('SALES_REP não lê cliente fora da carteira mesmo manipulando query', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/customers/customer-b`).get());
    await assertFails(
      db
        .collection(`organizations/${ORG_A}/customers`)
        .where('primarySalesRepId', '==', 'rep-b')
        .where('deletedAt', '==', null)
        .get(),
    );
  });

  test('SALES_REP consegue executar a query contratada por primarySalesRepId', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db
        .collection(`organizations/${ORG_A}/customers`)
        .where('primarySalesRepId', '==', 'rep-a')
        .where('deletedAt', '==', null)
        .get(),
    );
  });

  test('SALES_MANAGER lê clientes das suas equipes por teamId', async () => {
    const db = testEnv.authenticatedContext('manager-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/customers/customer-a`).get());
    await assertFails(db.doc(`organizations/${ORG_A}/customers/customer-b`).get());
    await assertSucceeds(
      db
        .collection(`organizations/${ORG_A}/customers`)
        .where('teamId', '==', 'team-a')
        .where('deletedAt', '==', null)
        .get(),
    );
  });

  test('ADMIN e OWNER leem toda a carteira da própria organization', async () => {
    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();
    const adminDb = testEnv.authenticatedContext('admin-a').firestore();

    await assertSucceeds(ownerDb.collection(`organizations/${ORG_A}/customers`).get());
    await assertSucceeds(adminDb.collection(`organizations/${ORG_A}/customers`).get());
  });

  test('membro da Org A não lê clientes da Org B', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/customers/customer-other-tenant`).get());
  });
});

describe('organizations/{organizationId}/orders/{orderId}  (TASK-102 visibility contract)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/orders/order-rep-a`)
        .set(orderDoc({ organizationId: ORG_A, sellerId: 'rep-a' }));
      await db
        .doc(`organizations/${ORG_A}/orders/order-rep-b`)
        .set(orderDoc({ organizationId: ORG_A, sellerId: 'rep-b' }));
      await db
        .doc(`organizations/${ORG_B}/orders/order-other-tenant`)
        .set(orderDoc({ organizationId: ORG_B, companyId: 'company-b', sellerId: 'owner-b' }));
    });
  });

  test('SALES_REP lê o próprio pedido', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/orders/order-rep-a`).get());
  });

  test('SALES_REP não lê pedido de outro vendedor mesmo manipulando a query', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/orders/order-rep-b`).get());
    await assertFails(
      db
        .collection(`organizations/${ORG_A}/orders`)
        .where('sellerId', '==', 'rep-b')
        .where('deletedAt', '==', null)
        .get(),
    );
  });

  test('SALES_REP consegue executar a query contratada por sellerId', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db
        .collection(`organizations/${ORG_A}/orders`)
        .where('sellerId', '==', 'rep-a')
        .where('deletedAt', '==', null)
        .get(),
    );
  });

  test('SALES_MANAGER lê pedido do vendedor da própria equipe, mas não de outra equipe', async () => {
    const db = testEnv.authenticatedContext('manager-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/orders/order-rep-a`).get());
    await assertFails(db.doc(`organizations/${ORG_A}/orders/order-rep-b`).get());
  });

  test('ADMIN e OWNER leem todos os pedidos da própria organization', async () => {
    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();
    const adminDb = testEnv.authenticatedContext('admin-a').firestore();

    await assertSucceeds(ownerDb.collection(`organizations/${ORG_A}/orders`).get());
    await assertSucceeds(adminDb.collection(`organizations/${ORG_A}/orders`).get());
  });

  test('FINANCE não lê pedidos (sem order.view)', async () => {
    const db = testEnv.authenticatedContext('finance-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/orders/order-rep-a`).get());
  });

  test('membro da Org A não lê pedidos da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/orders/order-other-tenant`).get());
  });

  test('ninguém escreve pedido pelo cliente, nem OWNER — submitOrder (Admin SDK) é o único caminho', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/orders/order-new`).set(orderDoc({ organizationId: ORG_A, sellerId: 'owner-a' })),
    );
    await assertFails(
      db.doc(`organizations/${ORG_A}/orders/order-rep-a`).update({ status: 'approved' }),
    );
    await assertFails(db.doc(`organizations/${ORG_A}/orders/order-rep-a`).delete());
  });
});

describe('organizations/{organizationId}/products/{productId}  (TASK-069 global search)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/products/product-a`)
        .set(productDoc({ organizationId: ORG_A }));
      await db
        .doc(`organizations/${ORG_A}/products/product-deleted`)
        .set(productDoc({ organizationId: ORG_A, deletedAt: now() }));
      await db
        .doc(`organizations/${ORG_B}/products/product-b`)
        .set(productDoc({ organizationId: ORG_B }));
    });
  });

  test('membro ativo le produto da propria organization', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/products/product-a`).get());
  });

  test('membro lista produtos pela query de busca contratada', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db
        .collection(`organizations/${ORG_A}/products`)
        .where('organizationId', '==', ORG_A)
        .where('deletedAt', '==', null)
        .where('searchPrefixes', 'array-contains', 'cam')
        .get(),
    );
  });

  test('membro da Org A nao le produto da Org B', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/products/product-b`).get());
  });

  test('produto soft-deleted nao fica legivel pelo cliente', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/products/product-deleted`).get());
  });

  test('cliente nao cria, altera nem exclui produto por Rules', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/products/new-product`).set(productDoc({ organizationId: ORG_A })),
    );
    await assertFails(
      db.doc(`organizations/${ORG_A}/products/product-a`).update({ name: 'Nome alterado' }),
    );
    await assertFails(db.doc(`organizations/${ORG_A}/products/product-a`).delete());
  });
});

describe('organizations/{organizationId}/favorites/{favoriteId}  (TASK-079 personal favorites)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/favorites/rep-a_product-a`)
        .set(favoriteDoc({ organizationId: ORG_A, userId: 'rep-a', productId: 'product-a' }));
      await db
        .doc(`organizations/${ORG_A}/favorites/rep-b_product-a`)
        .set(favoriteDoc({ organizationId: ORG_A, userId: 'rep-b', productId: 'product-a' }));
    });
  });

  test('usuário cria o próprio favorito com o id {userId}_{productId}', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db
        .doc(`organizations/${ORG_A}/favorites/rep-a_product-new`)
        .set(favoriteDoc({ organizationId: ORG_A, userId: 'rep-a', productId: 'product-new' })),
    );
  });

  test('usuário não cria favorito em nome de outro usuário', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/favorites/rep-b_product-new`)
        .set(favoriteDoc({ organizationId: ORG_A, userId: 'rep-b', productId: 'product-new' })),
    );
  });

  test('usuário lê e apaga o próprio favorito', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/favorites/rep-a_product-a`).get());
    await assertSucceeds(db.doc(`organizations/${ORG_A}/favorites/rep-a_product-a`).delete());
  });

  test('usuário não lê nem apaga favorito de outro usuário, mesmo sabendo o id', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/favorites/rep-b_product-a`).get());
    await assertFails(db.doc(`organizations/${ORG_A}/favorites/rep-b_product-a`).delete());
  });

  test('usuário lista apenas os próprios favoritos quando a query filtra userId', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db.collection(`organizations/${ORG_A}/favorites`).where('userId', '==', 'rep-a').get(),
    );
    await assertFails(
      db.collection(`organizations/${ORG_A}/favorites`).where('userId', '==', 'rep-b').get(),
    );
  });

  test('membro da Org A não lê favorito da Org B', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_B}/favorites/owner-b_product-b`)
        .set(favoriteDoc({ organizationId: ORG_B, userId: 'owner-b', productId: 'product-b' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/favorites/owner-b_product-b`).get());
  });
});

describe('organizations/{organizationId}/catalogShares/{shareId}  (TASK-081 catalog sharing)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/catalogShares/share-rep-a`)
        .set(catalogShareDoc({ organizationId: ORG_A, createdBy: 'rep-a' }));
      await db
        .doc(`organizations/${ORG_A}/catalogShares/share-rep-b`)
        .set(catalogShareDoc({ organizationId: ORG_A, createdBy: 'rep-b' }));
      await db
        .doc(`organizations/${ORG_B}/catalogShares/share-owner-b`)
        .set(catalogShareDoc({ organizationId: ORG_B, createdBy: 'owner-b' }));
    });
  });

  test('criador lê o próprio compartilhamento', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/catalogShares/share-rep-a`).get());
  });

  test('membro comum não lê compartilhamento criado por outro membro', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/catalogShares/share-rep-b`).get());
  });

  test('OWNER/ADMIN (catalog.manage) lê qualquer compartilhamento da própria organization', async () => {
    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(ownerDb.doc(`organizations/${ORG_A}/catalogShares/share-rep-b`).get());

    const adminDb = testEnv.authenticatedContext('admin-a').firestore();
    await assertSucceeds(adminDb.doc(`organizations/${ORG_A}/catalogShares/share-rep-b`).get());
  });

  test('membro da Org A não lê compartilhamento da Org B, mesmo sabendo o id', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/catalogShares/share-owner-b`).get());
  });

  test('visitante não autenticado não lê nenhum compartilhamento diretamente', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/catalogShares/share-rep-a`).get());
  });

  test('cliente não cria, altera nem exclui compartilhamento por Rules (somente as Cloud Functions, via Admin SDK)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/catalogShares/new-share`)
        .set(catalogShareDoc({ organizationId: ORG_A, createdBy: 'rep-a' })),
    );
    await assertFails(
      db.doc(`organizations/${ORG_A}/catalogShares/share-rep-a`).update({ status: 'revoked' }),
    );
    await assertFails(db.doc(`organizations/${ORG_A}/catalogShares/share-rep-a`).delete());
  });
});

describe('organizations/{organizationId}/priceLists/{priceListId}  (TASK-083)', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/priceLists/price-list-a`)
        .set(priceListDoc({ organizationId: ORG_A }));
      await db
        .doc(`organizations/${ORG_B}/priceLists/price-list-b`)
        .set(priceListDoc({ organizationId: ORG_B, companyId: 'company-b', createdBy: 'owner-b' }));
    });
  });

  test('membro ativo da Org A le a Price List da própria organization', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/priceLists/price-list-a`).get());
  });

  test('membro da Org A não le a Price List da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/priceLists/price-list-b`).get());
  });

  test('usuário não autenticado não le nenhuma Price List', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/priceLists/price-list-a`).get());
  });

  test('OWNER/ADMIN/FINANCE (priceList.manage) criam Price List na própria organization', async () => {
    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      ownerDb
        .doc(`organizations/${ORG_A}/priceLists/price-list-owner`)
        .set(priceListDoc({ organizationId: ORG_A, createdBy: 'owner-a' })),
    );

    const adminDb = testEnv.authenticatedContext('admin-a').firestore();
    await assertSucceeds(
      adminDb
        .doc(`organizations/${ORG_A}/priceLists/price-list-admin`)
        .set(priceListDoc({ organizationId: ORG_A, createdBy: 'admin-a' })),
    );

    const financeDb = testEnv.authenticatedContext('finance-a').firestore();
    await assertSucceeds(
      financeDb
        .doc(`organizations/${ORG_A}/priceLists/price-list-finance`)
        .set(priceListDoc({ organizationId: ORG_A, createdBy: 'finance-a' })),
    );
  });

  test('SALES_REP e SALES_MANAGER não criam Price List (sem priceList.manage)', async () => {
    const repDb = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      repDb
        .doc(`organizations/${ORG_A}/priceLists/price-list-rep`)
        .set(priceListDoc({ organizationId: ORG_A, createdBy: 'rep-a' })),
    );

    const managerDb = testEnv.authenticatedContext('manager-a').firestore();
    await assertFails(
      managerDb
        .doc(`organizations/${ORG_A}/priceLists/price-list-manager`)
        .set(priceListDoc({ organizationId: ORG_A, createdBy: 'manager-a' })),
    );
  });

  test('não é possível criar Price List com validTo anterior a validFrom', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    const start = new Date();
    const before = new Date(start.getTime() - 86400000);
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/priceLists/price-list-invalid-dates`)
        .set(priceListDoc({ organizationId: ORG_A, validFrom: start, validTo: before })),
    );
  });

  test('não é possível criar Price List de escopo channel/segment sem scopeValue', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/priceLists/price-list-missing-scope-value`)
        .set(priceListDoc({ organizationId: ORG_A, scope: 'channel', scopeValue: null })),
    );
  });

  test('FINANCE atualiza uma Price List existente sem alterar a moeda', async () => {
    const db = testEnv.authenticatedContext('finance-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/priceLists/price-list-a`).update({
        name: 'Tabela Atualizada',
        priority: 5,
        updatedAt: now(),
        updatedBy: 'finance-a',
      }),
    );
  });

  test('não é possível alterar a moeda de uma Price List existente (imutável)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/priceLists/price-list-a`).update({
        currency: 'USD',
        updatedAt: now(),
        updatedBy: 'owner-a',
      }),
    );
  });

  test('cliente não exclui Price List (soft delete apenas, sem delete físico)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/priceLists/price-list-a`).delete());
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

  test('OWNER lista (query) os members da própria organization (UserListPage, TASK-042)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.collection(`organizations/${ORG_A}/members`).get());
  });

  test('SALES_REP não consegue listar (query) os members — sem user.changeRole', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.collection(`organizations/${ORG_A}/members`).get());
  });

  test(
    'OWNER da Org A não consegue listar (query manipulada) os members da Org B (cross-tenant)',
    async () => {
      const db = testEnv.authenticatedContext('owner-a').firestore();
      await assertFails(db.collection(`organizations/${ORG_B}/members`).get());
    },
  );

  test(
    'qualquer usuário consegue resolver a(s) própria(s) organization(s) via ' +
      'collectionGroup("members") filtrado pelo próprio userId ' +
      '(MembershipRepository.listActiveByUser)',
    async () => {
      const db = testEnv.authenticatedContext('rep-a').firestore();
      const snapshot = await assertSucceeds(
        db.collectionGroup('members').where('userId', '==', 'rep-a').get(),
      );
      expect(snapshot.docs.map((doc) => doc.data().organizationId)).toEqual([ORG_A]);
    },
  );

  test(
    'collectionGroup("members") filtrado pelo userId de outra pessoa é negado ' +
      '(nunca enumera Membership alheia)',
    async () => {
      const db = testEnv.authenticatedContext('owner-a').firestore();
      await assertFails(
        db.collectionGroup('members').where('userId', '==', 'rep-a').get(),
      );
    },
  );

  test(
    'collectionGroup("members") sem filtro por userId é negado (não é uma ' +
      'enumeração aberta, mesmo autenticado)',
    async () => {
      const db = testEnv.authenticatedContext('owner-a').firestore();
      await assertFails(db.collectionGroup('members').get());
    },
  );

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

  test(
    'Membership OWNER não pode mais ser autoconcedida diretamente pelo cliente, mesmo pelo ' +
      'criador da organization ainda sem Membership — isso é exclusivo da Cloud Function ' +
      'createOrganization (TASK-037)',
    async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc('organizations/org-new').set(organizationDoc({ createdBy: 'new-founder', updatedBy: 'new-founder' }));
        await db.doc('organizations/org-new/roles/OWNER').set(roleDoc({ organizationId: 'org-new', name: 'OWNER', isSystemRole: true }));
      });

      const db = testEnv.authenticatedContext('new-founder').firestore();
      await assertFails(
        db.doc('organizations/org-new/members/new-founder').set(
          membershipDoc({ organizationId: 'org-new', userId: 'new-founder', roleId: 'OWNER', roleName: 'OWNER' }),
        ),
      );
    },
  );

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

describe('organizations/{organizationId}/invites/{inviteId}  (TASK-039)', () => {
  test('OWNER (user.invite) consegue ler um convite pendente da própria organization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/invites/invite-1`)
        .set(inviteDoc({ organizationId: ORG_A }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/invites/invite-1`).get());
  });

  test('SALES_REP (sem user.invite) não consegue ler os convites', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/invites/invite-1`)
        .set(inviteDoc({ organizationId: ORG_A }));
    });

    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/invites/invite-1`).get());
  });

  test('OWNER da Org A não consegue ler um convite da Org B (cross-tenant)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_B}/invites/invite-1`)
        .set(inviteDoc({ organizationId: ORG_B }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/invites/invite-1`).get());
  });

  test('nem mesmo OWNER consegue criar um convite diretamente pelo cliente — exclusivo da Cloud Function createInvite', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/invites/invite-new`).set(inviteDoc({ organizationId: ORG_A })),
    );
  });

  test('nem mesmo OWNER consegue atualizar (ex.: reenviar) um convite diretamente pelo cliente', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/invites/invite-1`)
        .set(inviteDoc({ organizationId: ORG_A }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/invites/invite-1`).update({ status: 'revoked' }),
    );
  });

  test('nem mesmo OWNER consegue excluir um convite diretamente pelo cliente', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/invites/invite-1`)
        .set(inviteDoc({ organizationId: ORG_A }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/invites/invite-1`).delete());
  });
});

describe('organizations/{organizationId}/auditLogs/{logId}  (TASK-033)', () => {
  test('qualquer membro ativo pode registrar uma entrada de auditoria sobre '
    + 'uma ação que ele mesmo executou', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/auditLogs/log-1`).set(
        auditLogDoc({ organizationId: ORG_A, actorUserId: 'rep-a' }),
      ),
    );
  });

  test('não é possível registrar uma entrada de auditoria em nome de outro '
    + 'usuário (actorUserId forjado)', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/auditLogs/log-1`).set(
        auditLogDoc({ organizationId: ORG_A, actorUserId: 'owner-a' }),
      ),
    );
  });

  test('usuário sem Membership na Org A não registra uma entrada de '
    + 'auditoria lá', async () => {
    const db = testEnv.authenticatedContext('stranger').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/auditLogs/log-1`).set(
        auditLogDoc({ organizationId: ORG_A, actorUserId: 'stranger' }),
      ),
    );
  });

  test('usuário não autenticado não registra nenhuma entrada de auditoria', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/auditLogs/log-1`).set(
        auditLogDoc({ organizationId: ORG_A, actorUserId: 'rep-a' }),
      ),
    );
  });

  test('membro da Org A não registra uma entrada de auditoria forjando o '
    + 'organizationId da Org B', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_B}/auditLogs/log-1`).set(
        auditLogDoc({ organizationId: ORG_B, actorUserId: 'owner-a' }),
      ),
    );
  });

  test('OWNER (audit.log.view) consegue ler o audit log da própria organization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/auditLogs/log-1`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'owner-a' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(db.doc(`organizations/${ORG_A}/auditLogs/log-1`).get());
  });

  test('OWNER e ADMIN conseguem listar audit logs somente da própria organization (TASK-047)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .doc(`organizations/${ORG_A}/auditLogs/log-owner`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'owner-a' }));
      await db
        .doc(`organizations/${ORG_A}/auditLogs/log-admin`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'admin-a', action: 'user.roleUpdated' }));
      await db
        .doc(`organizations/${ORG_B}/auditLogs/log-other-tenant`)
        .set(auditLogDoc({ organizationId: ORG_B, actorUserId: 'owner-b' }));
    });

    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();
    const adminDb = testEnv.authenticatedContext('admin-a').firestore();

    await assertSucceeds(
      ownerDb
        .collection(`organizations/${ORG_A}/auditLogs`)
        .where('action', '==', 'user.roleUpdated')
        .get(),
    );
    await assertSucceeds(
      adminDb
        .collection(`organizations/${ORG_A}/auditLogs`)
        .where('actorUserId', '==', 'admin-a')
        .get(),
    );
    await assertFails(ownerDb.collection(`organizations/${ORG_B}/auditLogs`).get());
  });

  test('SALES_REP (sem audit.log.view) não consegue ler o audit log', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/auditLogs/log-1`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'rep-a' }));
    });

    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/auditLogs/log-1`).get());
    await assertFails(db.collection(`organizations/${ORG_A}/auditLogs`).get());
  });

  test('OWNER da Org A não consegue ler o audit log da Org B (cross-tenant)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_B}/auditLogs/log-1`)
        .set(auditLogDoc({ organizationId: ORG_B, actorUserId: 'owner-b' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_B}/auditLogs/log-1`).get());
  });

  test('nenhum papel, nem OWNER, consegue atualizar uma entrada de auditoria já criada', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/auditLogs/log-1`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'owner-a' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/auditLogs/log-1`).update({ actorName: 'Nome Alterado' }),
    );
  });

  test('nenhum papel, nem OWNER, consegue excluir uma entrada de auditoria já criada', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/auditLogs/log-1`)
        .set(auditLogDoc({ organizationId: ORG_A, actorUserId: 'owner-a' }));
    });

    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(db.doc(`organizations/${ORG_A}/auditLogs/log-1`).delete());
  });
});

describe('organizations/{organizationId}/salesDailyAggregates/{aggregateId}  (TASK-133)', () => {
  // Representative of all five `*Aggregates` collections this task adds
  // (`salesDailyAggregates`/`customerMonthlyAggregates`/
  // `productMonthlyAggregates`/`sellerMonthlyAggregates`/
  // `regionMonthlyAggregates`) — they share the exact same rule (gated by
  // `report.viewSensitive`, client never writes), so one is exercised here
  // in depth instead of duplicating the same five assertions per
  // collection.
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-15`)
        .set(salesDailyAggregateDoc({ organizationId: ORG_A }));
      await context
        .firestore()
        .doc(`organizations/${ORG_B}/salesDailyAggregates/company-b_company-b_2026-08-15`)
        .set(salesDailyAggregateDoc({ organizationId: ORG_B, companyId: 'company-b' }));
    });
  });

  test('OWNER (report.viewSensitive) consegue ler o snapshot da própria organization', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertSucceeds(
      db.doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-15`).get(),
    );
  });

  test('SALES_MANAGER (report.viewSensitive) consegue listar snapshots da própria organization', async () => {
    const db = testEnv.authenticatedContext('manager-a').firestore();
    await assertSucceeds(
      db.collection(`organizations/${ORG_A}/salesDailyAggregates`).get(),
    );
  });

  test('SALES_REP (sem report.viewSensitive) não consegue ler nem listar snapshots', async () => {
    const db = testEnv.authenticatedContext('rep-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-15`).get(),
    );
    await assertFails(db.collection(`organizations/${ORG_A}/salesDailyAggregates`).get());
  });

  test('OWNER da Org A não consegue ler o snapshot da Org B (cross-tenant)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db.doc(`organizations/${ORG_B}/salesDailyAggregates/company-b_company-b_2026-08-15`).get(),
    );
  });

  test('nenhum papel, nem OWNER, consegue criar um snapshot pelo client (só a Admin SDK escreve)', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-16`)
        .set(salesDailyAggregateDoc({ organizationId: ORG_A })),
    );
  });

  test('nenhum papel, nem OWNER, consegue atualizar ou excluir um snapshot já existente', async () => {
    const db = testEnv.authenticatedContext('owner-a').firestore();
    await assertFails(
      db
        .doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-15`)
        .update({ revenueGross: 999999 }),
    );
    await assertFails(
      db.doc(`organizations/${ORG_A}/salesDailyAggregates/company-a_company-a_2026-08-15`).delete(),
    );
  });
});

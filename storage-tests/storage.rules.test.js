/**
 * Testes positivos e negativos de `storage.rules` (TASK-031).
 *
 * Roda contra o Firebase Emulator Suite (Firestore + Storage), nunca contra
 * produção. `storage.rules` faz Cross-Service Security Rules
 * (`firestore.get`/`firestore.exists`) para reler o Membership real do
 * usuário autenticado — por isso o Firestore Emulator precisa estar rodando
 * junto do Storage Emulator nesta suíte, mesmo que nenhum teste aqui chame
 * `context.firestore()` diretamente fora do seed.
 *
 * Uso (a partir da raiz do repositório):
 *
 *   firebase emulators:exec --only "firestore,storage" \
 *     "npm --prefix storage-tests test"
 *
 * `initializeTestEnvironment` detecta host/porta dos emuladores via as
 * variáveis de ambiente que `firebase emulators:exec` já exporta
 * (`FIRESTORE_EMULATOR_HOST`, `FIREBASE_STORAGE_EMULATOR_HOST`); por isso não
 * hardcodamos host/porta aqui.
 */

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

const STORAGE_RULES_PATH = path.resolve(__dirname, '..', 'storage.rules');
const FIRESTORE_RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

const ORG_A = 'org-a';
const ORG_B = 'org-b';

const PRODUCT_IMAGE_MAX_BYTES = 10 * 1024 * 1024;
const ORDER_ATTACHMENT_MAX_BYTES = 20 * 1024 * 1024;

const now = () => new Date();

function membershipDoc({ organizationId, userId, roleName, status = 'active' }) {
  return {
    organizationId,
    userId,
    roleId: roleName,
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

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    // Precisa ser exatamente o project ID configurado em `.firebaserc`
    // (`vestipro`), e não um project ID sintético como em
    // `firestore-tests` (`vestipro-rules-test`): `storage.rules` faz
    // Cross-Service Security Rules (`firestore.get`/`firestore.exists`), e
    // com `"singleProjectMode": true` (`firebase.json`) essas chamadas
    // cross-service sempre resolvem contra o projeto único configurado do
    // emulador, não contra o `projectId` passado aqui — se os dois
    // divergirem, o Storage Emulator consulta um Firestore "vazio" (projeto
    // errado) e toda regra que depende de Membership fica falso-negativa.
    projectId: 'vestipro',
    firestore: {
      rules: fs.readFileSync(FIRESTORE_RULES_PATH, 'utf8'),
    },
    storage: {
      rules: fs.readFileSync(STORAGE_RULES_PATH, 'utf8'),
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();

  // Seed sem passar pelas Rules: Org A com OWNER, SALES_REP, SALES_ASSISTANT
  // e um Membership INATIVO; Org B com seu próprio OWNER.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await db
      .doc(`organizations/${ORG_A}/members/owner-a`)
      .set(membershipDoc({ organizationId: ORG_A, userId: 'owner-a', roleName: 'OWNER' }));
    await db
      .doc(`organizations/${ORG_A}/members/rep-a`)
      .set(membershipDoc({ organizationId: ORG_A, userId: 'rep-a', roleName: 'SALES_REP' }));
    await db
      .doc(`organizations/${ORG_A}/members/assistant-a`)
      .set(membershipDoc({ organizationId: ORG_A, userId: 'assistant-a', roleName: 'SALES_ASSISTANT' }));
    await db
      .doc(`organizations/${ORG_A}/members/inactive-a`)
      .set(membershipDoc({ organizationId: ORG_A, userId: 'inactive-a', roleName: 'SALES_REP', status: 'inactive' }));

    await db
      .doc(`organizations/${ORG_B}/members/owner-b`)
      .set(membershipDoc({ organizationId: ORG_B, userId: 'owner-b', roleName: 'OWNER' }));
  });
});

async function seedFile(storagePath, bytes, contentType) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), storagePath), bytes, { contentType });
  });
}

async function upload(userId, storagePath, bytes, contentType) {
  const storage = testEnv.authenticatedContext(userId).storage();
  return uploadBytes(ref(storage, storagePath), bytes, { contentType });
}

describe('organizations/{organizationId}/products/{productId}/{fileName}', () => {
  const PATH_A = `organizations/${ORG_A}/products/product-1/photo.jpg`;
  const PATH_B = `organizations/${ORG_B}/products/product-1/photo.jpg`;
  const validImage = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

  test('OWNER (catalog.manage) consegue enviar foto de produto dentro da própria organização', async () => {
    await assertSucceeds(upload('owner-a', PATH_A, validImage, 'image/jpeg'));
  });

  test('SALES_REP (sem catalog.manage) não consegue enviar foto de produto', async () => {
    await assertFails(upload('rep-a', PATH_A, validImage, 'image/jpeg'));
  });

  test('Membership inativo não consegue enviar foto de produto', async () => {
    await assertFails(upload('inactive-a', PATH_A, validImage, 'image/jpeg'));
  });

  test('usuário não autenticado não consegue enviar foto de produto', async () => {
    const storage = testEnv.unauthenticatedContext().storage();
    await assertFails(uploadBytes(ref(storage, PATH_A), validImage, { contentType: 'image/jpeg' }));
  });

  test('membro ativo da própria organização consegue ler foto de produto já existente', async () => {
    await seedFile(PATH_A, validImage, 'image/jpeg');
    const storage = testEnv.authenticatedContext('rep-a').storage();
    await assertSucceeds(getBytes(ref(storage, PATH_A)));
  });

  test('usuário não autenticado não consegue ler foto de produto', async () => {
    await seedFile(PATH_A, validImage, 'image/jpeg');
    const storage = testEnv.unauthenticatedContext().storage();
    await assertFails(getBytes(ref(storage, PATH_A)));
  });

  test('membro da Org A não consegue ler foto de produto sob o path da Org B (cross-tenant)', async () => {
    await seedFile(PATH_B, validImage, 'image/jpeg');
    const storage = testEnv.authenticatedContext('owner-a').storage();
    await assertFails(getBytes(ref(storage, PATH_B)));
  });

  test('membro da Org A não consegue enviar foto de produto sob o path da Org B (cross-tenant)', async () => {
    await assertFails(upload('owner-a', PATH_B, validImage, 'image/jpeg'));
  });

  test('upload de arquivo com tipo não permitido é rejeitado (executável disfarçado de imagem)', async () => {
    await assertFails(upload('owner-a', PATH_A, validImage, 'application/x-msdownload'));
  });

  test('upload de foto de produto acima do tamanho máximo permitido é rejeitado', async () => {
    const oversized = new Uint8Array(PRODUCT_IMAGE_MAX_BYTES + 1);
    await assertFails(upload('owner-a', PATH_A, oversized, 'image/jpeg'));
  });

  test('OWNER consegue excluir foto de produto enviada por outro usuário (ação administrativa)', async () => {
    await seedFile(PATH_A, validImage, 'image/jpeg');
    const storage = testEnv.authenticatedContext('owner-a').storage();
    await assertSucceeds(deleteObject(ref(storage, PATH_A)));
  });

  test('SALES_REP não consegue excluir foto de produto (sem catalog.manage)', async () => {
    await seedFile(PATH_A, validImage, 'image/jpeg');
    const storage = testEnv.authenticatedContext('rep-a').storage();
    await assertFails(deleteObject(ref(storage, PATH_A)));
  });
});

describe('organizations/{organizationId}/orders/{orderId}/attachments/{fileName}', () => {
  const PATH_A = `organizations/${ORG_A}/orders/order-1/attachments/nota.pdf`;
  const PATH_B = `organizations/${ORG_B}/orders/order-1/attachments/nota.pdf`;
  const validPdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]);

  test('SALES_REP (order.create) consegue enviar anexo de pedido dentro da própria organização', async () => {
    await assertSucceeds(upload('rep-a', PATH_A, validPdf, 'application/pdf'));
  });

  test('SALES_ASSISTANT (sem order.create) não consegue enviar anexo de pedido', async () => {
    await assertFails(upload('assistant-a', PATH_A, validPdf, 'application/pdf'));
  });

  test('membro da Org A não consegue enviar anexo sob o path da Org B (cross-tenant)', async () => {
    await assertFails(upload('rep-a', PATH_B, validPdf, 'application/pdf'));
  });

  test('usuário não autenticado não consegue ler anexo de pedido', async () => {
    await seedFile(PATH_A, validPdf, 'application/pdf');
    const storage = testEnv.unauthenticatedContext().storage();
    await assertFails(getBytes(ref(storage, PATH_A)));
  });

  test('membro ativo da própria organização consegue ler anexo de pedido já existente', async () => {
    await seedFile(PATH_A, validPdf, 'application/pdf');
    const storage = testEnv.authenticatedContext('assistant-a').storage();
    await assertSucceeds(getBytes(ref(storage, PATH_A)));
  });

  test('upload de anexo com tipo de arquivo não permitido é rejeitado', async () => {
    await assertFails(upload('rep-a', PATH_A, validPdf, 'application/x-sh'));
  });

  test('upload de anexo de pedido acima do tamanho máximo permitido é rejeitado', async () => {
    const oversized = new Uint8Array(ORDER_ATTACHMENT_MAX_BYTES + 1);
    await assertFails(upload('rep-a', PATH_A, oversized, 'application/pdf'));
  });

  test('SALES_MANAGER (order.create) consegue excluir anexo de pedido enviado por outro usuário', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`organizations/${ORG_A}/members/manager-a`)
        .set(membershipDoc({ organizationId: ORG_A, userId: 'manager-a', roleName: 'SALES_MANAGER' }));
    });
    await seedFile(PATH_A, validPdf, 'application/pdf');
    const storage = testEnv.authenticatedContext('manager-a').storage();
    await assertSucceeds(deleteObject(ref(storage, PATH_A)));
  });
});

describe('organizations/{organizationId}/users/{userId}/avatar', () => {
  const PATH_OWNER_A = `organizations/${ORG_A}/users/owner-a/avatar`;
  const validImage = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

  test('usuário consegue enviar o próprio avatar', async () => {
    await assertSucceeds(upload('owner-a', PATH_OWNER_A, validImage, 'image/png'));
  });

  test('usuário não consegue enviar avatar de outro usuário', async () => {
    await assertFails(upload('rep-a', PATH_OWNER_A, validImage, 'image/png'));
  });

  test('upload de avatar com tipo de arquivo não permitido é rejeitado', async () => {
    await assertFails(upload('owner-a', PATH_OWNER_A, validImage, 'application/pdf'));
  });

  test('membro ativo consegue ler avatar de outro membro da mesma organização', async () => {
    await seedFile(PATH_OWNER_A, validImage, 'image/png');
    const storage = testEnv.authenticatedContext('rep-a').storage();
    await assertSucceeds(getBytes(ref(storage, PATH_OWNER_A)));
  });

  test('membro de outra organização não consegue ler avatar (cross-tenant)', async () => {
    await seedFile(PATH_OWNER_A, validImage, 'image/png');
    const storage = testEnv.authenticatedContext('owner-b').storage();
    await assertFails(getBytes(ref(storage, PATH_OWNER_A)));
  });

  test('usuário consegue excluir o próprio avatar', async () => {
    await seedFile(PATH_OWNER_A, validImage, 'image/png');
    const storage = testEnv.authenticatedContext('owner-a').storage();
    await assertSucceeds(deleteObject(ref(storage, PATH_OWNER_A)));
  });

  test('usuário não consegue excluir avatar de outro usuário', async () => {
    await seedFile(PATH_OWNER_A, validImage, 'image/png');
    const storage = testEnv.authenticatedContext('rep-a').storage();
    await assertFails(deleteObject(ref(storage, PATH_OWNER_A)));
  });
});

describe('deny by default', () => {
  test('path de mídia ainda não modelado nas rules é sempre negado', async () => {
    await assertFails(
      upload('owner-a', `organizations/${ORG_A}/random/file.txt`, new Uint8Array([1, 2, 3]), 'text/plain'),
    );
  });
});

# TASK-171 — Implementar API pública (REST) — CONCLUÍDA

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Agente executor:** `flutter-senior-architect`

## O que foi implementado

Uma API REST pública, versionada (`/v1/...`), autenticada por API key, restrita à organização do
token, com rate limiting, paginação por cursor, log de uso e endpoints de gestão da própria chave —
tudo em `functions/src/public_api/`, reaproveitando os padrões de RBAC/lookup por hash já
estabelecidos por TASK-169 (ERP) e TASK-170 (webhooks).

### Modelo de dados (Firestore)

- `organizations/{organizationId}/apiKeys/{keyId}` — `name`, `keyHash` (SHA-256 do token completo,
  nunca o texto puro), `keySuffix` (últimos 4 caracteres, para o gestor reconhecer a chave numa
  lista), `scopes` (`customers:read` | `products:read` | `orders:read` | `orders:write`),
  `rateLimitPerMinute`, `status` (`active` | `revoked`), `createdAt/By`, `updatedAt/By`,
  `revokedAt/By`, `lastUsedAt`, `lastRotatedAt`. Nunca legível pelo cliente (`firestore.rules`:
  `allow read, write: if false`), mesma postura de `webhookSecrets` (TASK-170) — só acessado via
  Admin SDK pelos 4 callables abaixo ou pelo middleware da API REST.
- `organizations/{organizationId}/apiKeyRateLimitBuckets/{keyId}_{janelaDeUmMinuto}` — contador
  atômico (transação Firestore) da janela de 1 minuto corrente. Nunca legível pelo cliente. TTL
  (`expiresAt`) documentado mas não configurado nesta task (ver "Pendências").
- `organizations/{organizationId}/apiUsageLogs/{logId}` — `keyId`, `method`, `path`, `statusCode`,
  `latencyMs`, `timestamp`, para suporte/faturamento. Legível pelo gestor com `apiKey.manage`
  (nunca carrega a chave em si, só o `keyId`).

### Cloud Functions

- `generateApiKey` (callable, RBAC OWNER/ADMIN) — cria uma nova chave, retorna o token em texto
  puro **uma única vez** (só o hash é persistido).
- `revokeApiKey` (callable) — invalida a chave imediatamente; sem cache/TTL de autorização — o
  middleware relê `apiKeys` diretamente do Firestore em toda requisição.
- `rotateApiKey` (callable) — substitui o segredo mantendo `keyId`/`name`/`scopes`/rate limit; nunca
  reativa uma chave já revogada (usar `generateApiKey` para isso).
- `listApiKeys` (callable) — lista metadados (nunca `keyHash`) para o futuro painel de gestão.
- `publicApiV1` (HTTPS `onRequest`, Express) — roteador com:
  - `GET /v1/customers`, `GET /v1/customers/:id` (escopo `customers:read`)
  - `GET /v1/products`, `GET /v1/products/:id` (escopo `products:read`)
  - `GET /v1/orders`, `GET /v1/orders/:id` (escopo `orders:read`)
  - `POST /v1/orders` (escopo `orders:write`)

### Autenticação, autorização e rate limiting (middleware `public_api/rest/middleware.ts`)

- `authenticateApiKey`: lê o header `X-Api-Key`, calcula o hash (SHA-256) e resolve a chave via
  `collectionGroup('apiKeys').where('keyHash','==', hash)` — o mesmo padrão de
  `findInviteByTokenHash` (`invites/invite-shared.ts`, TASK-039): o chamador só tem o token em mãos,
  nunca o `organizationId`; o `organizationId` que autoriza a requisição é sempre o do documento
  resolvido pelo hash, nunca o que vier no corpo/query. Uma chave inexistente/revogada é sempre 401.
- Rate limit por chave/organização (nunca compartilhado entre organizações), verificado e
  incrementado atomicamente numa transação Firestore por janela de 1 minuto; toda resposta carrega
  `X-RateLimit-Limit` / `X-RateLimit-Remaining` / `X-RateLimit-Reset`; excedido → HTTP 429
  padronizado (`{ error: { code: 'rate_limited', message } }`).
- `requireScope(scope)`: 403 se o escopo da chave não cobrir a rota.
- Log de uso (`res.on('finish')`) sempre grava `statusCode`/`latencyMs` reais, inclusive quando um
  handler de rota falha.

### Paginação por cursor

Todo endpoint de listagem ordena por `(createdAt asc, __name__ asc)` e nunca usa offset — o cursor é
um token opaco (`base64url` de `{ createdAtMs, id }`) apontando para o último item da página
anterior; um cursor ausente/malformado é tratado como "começar do início" (nunca um 500).

### Criação de pedido via API — decisão de arquitetura

`POST /v1/orders` **não reimplementa** nenhuma regra de precificação/estoque/numeração/aprovação:
constrói um `CallableRequest<SubmitOrderRequest>` sintético e invoca
`submitOrder.run(callableRequest)` — a mesma função `orders/submit-order.ts` (TASK-101) que o app usa,
chamada diretamente em processo via `CallableFunction.run`, API pública e documentada do
`firebase-functions` v2 para invocar um callable a partir de outro contexto. **Nenhuma linha de
`orders/submit-order.ts` foi alterada.** Isso elimina qualquer risco de duplicar/divergir a regra de
negócio ("a API não é um atalho que ignora regra de domínio") e qualquer risco de regressão no
arquivo mais crítico do domínio financeiro.

Regras aplicadas ao redor dessa chamada:

- `organizationId` é **sempre** o resolvido da API key (`req.apiKey!.organizationId`) — o que vier no
  corpo é descartado antes de montar o `CallableRequest`.
- `sellerId` é obrigatório no corpo e precisa resolver a um `Membership` ativo real na organização
  (`loadActiveMembership`) antes de sequer tentar `submitOrder.run` — senão 400.
- O `uid` do contexto sintético é fixado como o próprio `sellerId`, de modo que a checagem
  anti-impersonação já existente em `submitOrder` (`sellerId !== uid`) seja satisfeita.
- Erros do `submitOrder` (`HttpsError`) são mapeados para HTTP (400/401/403/404/409/429/500) de forma
  padronizada.

**Limitação conhecida, documentada deliberadamente:** diferente do app (onde `uid` vem de um ID token
Firebase Auth verificado, provando "este usuário específico"), uma chamada via API key não tem
credencial por usuário — `orders:write` + um `sellerId` válido é toda a prova de identidade que esta
task autentica. Um fluxo OAuth 2.0 client-credentials por usuário (marcado "opcionalmente" no próprio
backlog da task) fecharia essa lacuna; ficou fora do escopo desta rodada.

### RBAC/Firestore Rules

- Nova `Capability.apiKeyManage` (`lib/core/permissions/capability.dart`), concedida a OWNER/ADMIN
  automaticamente (mesmo mecanismo de conjunto completo/quase completo de `RolePermissionMatrix`,
  nenhuma lista explícita de outro papel precisou mudar).
- Teste adicionado em `test/core/permissions/role_permission_matrix_test.dart` confirmando que só
  OWNER/ADMIN têm `apiKeyManage`.
- `firestore.rules`: blocos `apiKeys` (deny total), `apiKeyRateLimitBuckets` (deny total),
  `apiUsageLogs` (leitura só com `apiKey.manage`).
- `firestore.indexes.json`: `fieldOverrides` para `apiKeys.keyHash` (COLLECTION_GROUP, mesmo padrão de
  `invites.tokenHash`/`catalogShares.tokenHash`) + 3 índices compostos novos (`customers`, `products`,
  `orders`, todos `deletedAt ASC + createdAt ASC`) exigidos pela combinação
  equality-filter+orderBy-em-campo-diferente das listagens paginadas.

### Dependência nova

`express` (já era dependência transitiva de `firebase-functions`, promovida a dependência direta —
`^4.21.0`, mesma versão já resolvida em `node_modules`) + `@types/express` (dev). `package-lock.json`
regenerado com `npm install --package-lock-only --offline` (sem acesso à rede; diff mínimo, só as 2
entradas novas).

## Escopo deliberadamente fora desta task

- **OAuth 2.0 client credentials** — marcado "opcionalmente" no próprio backlog da task; API key
  cobre integralmente os critérios de aceite listados.
- **Painel/tela do gestor** para gerar/revogar/rotacionar chaves — mesmo precedente de TASK-170
  (webhooks): nenhuma UI foi criada nesta task; usar `flutter-ui-design-specialist` numa rodada
  dedicada, consumindo os 4 callables já prontos (`generateApiKey`/`revokeApiKey`/`rotateApiKey`/
  `listApiKeys`).
- **Rewrite de Hosting** para uma URL amigável (`https://dominio/api/v1/...`) — não há site de
  Hosting provisionado neste projeto ainda; o endpoint funciona hoje na URL bruta da Cloud Function
  (`.../publicApiV1/v1/...`).
- **TTL policy** em `apiKeyRateLimitBuckets.expiresAt` — precisa ser configurada via `gcloud`/console
  (não é expressável em `firestore.rules`/`firestore.indexes.json`); documentado como pendência.
- **Testes de Emulador** (Rules positivas/negativas de `apiKeys`/`apiUsageLogs`, isolamento
  multi-tenant ponta a ponta do middleware, rate limit sob concorrência real, criação de pedido via
  API ponta a ponta) — o ambiente de execução desta rodada não tem Java instalado, logo não roda o
  Firebase Emulator; mesma limitação já documentada em TASK-170-CONCLUIDA. O que é garantido por
  construção nesta rodada: toda query do middleware/rotas usa exclusivamente
  `organizations/{organizationId}/...` com o `organizationId` resolvido do hash da chave (nunca uma
  query cross-tenant, nunca o valor do corpo/query da requisição).

## Comandos executados

- `cd functions && npm install --package-lock-only --offline` — resolveu `express`/`@types/express`
  a partir do `node_modules` já presente; `package-lock.json` atualizado (diff de 2 linhas).
- `cd functions && npx tsc --noEmit` — sem erros.
- `cd functions && npm run build` — sem erros.
- `cd functions && npx eslint src/public_api` — sem erros/warnings.
- `cd functions && npm run lint` (eslint em `src test` completo) — sem erros/warnings.
- `cd functions && npx jest test/public_api/api-key-shared.test.ts` — 34/34 passando.
- `cd functions && npx jest --testPathIgnorePatterns=emulator` — 258 passaram, 124 falharam em
  19/45 suites, todas por falta de Firestore Emulator (`Could not load the default credentials`) —
  mesma condição pré-existente documentada em TASK-170-CONCLUIDA (mesmo número de suítes/testes
  falhando por essa causa; nenhuma nova falha introduzida — `submit-order.test.ts`, o arquivo mais
  sensível a esta task por ser reaproveitado via `.run()`, falha exatamente pelo mesmo motivo de
  sempre, não por um erro estrutural novo).
- `flutter analyze lib/core/permissions/capability.dart test/core/permissions/role_permission_matrix_test.dart`
  — sem issues.
- `flutter test test/core/permissions/role_permission_matrix_test.dart` — 23/23 passando (inclui o
  novo teste de `apiKeyManage`).
- `dart format --set-exit-if-changed` nos dois arquivos Dart alterados — sem mudanças pendentes.
- `npx firebase deploy --only firestore:rules --dry-run --project vestipro` — `firestore.rules`
  compilou com sucesso (nenhum deploy real executado).
- `node -e "JSON.parse(...)"` em `firestore.indexes.json` — JSON válido.

## Arquivos criados

- `functions/src/public_api/types.ts`
- `functions/src/public_api/api-key-shared.ts`
- `functions/src/public_api/generate-api-key.ts`
- `functions/src/public_api/revoke-api-key.ts`
- `functions/src/public_api/rotate-api-key.ts`
- `functions/src/public_api/list-api-keys.ts`
- `functions/src/public_api/rest/middleware.ts`
- `functions/src/public_api/rest/customers.ts`
- `functions/src/public_api/rest/products.ts`
- `functions/src/public_api/rest/orders.ts`
- `functions/src/public_api/rest/app.ts`
- `functions/src/public_api/index.ts`
- `functions/test/public_api/api-key-shared.test.ts`
- `docs/tasks/TASK-171-implementar-api-publica-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `functions/src/index.ts` — exporta as novas Cloud Functions do módulo `public_api`.
- `functions/package.json` — `express`/`@types/express` promovidos a dependência direta.
- `functions/package-lock.json` — regenerado (offline) para os dois pacotes acima.
- `lib/core/permissions/capability.dart` — nova `Capability.apiKeyManage` + `code`.
- `test/core/permissions/role_permission_matrix_test.dart` — teste de RBAC para `apiKeyManage`.
- `firestore.rules` — regras para `apiKeys`/`apiKeyRateLimitBuckets`/`apiUsageLogs`.
- `firestore.indexes.json` — `fieldOverride` para `apiKeys.keyHash` + 3 índices compostos
  (`customers`/`products`/`orders`, `deletedAt ASC + createdAt ASC`).
- `docs/tasks/TASKS.md` — checkbox da TASK-171 marcado; `Progresso` atualizado para 170/220.

## Riscos residuais / pendências

- Testes de Emulador (Rules positivas/negativas, rate limit sob concorrência real, fluxo ponta a
  ponta de `POST /v1/orders`) não cobertos por automação nesta rodada — ver seção acima.
- TTL policy de `apiKeyRateLimitBuckets`/`apiUsageLogs` não configurada (infra fora do escopo de
  `firestore.rules`/`firestore.indexes.json`).
- Painel de gestão de chaves (Flutter) não criado — necessário para o gestor realmente usar
  `generateApiKey`/`revokeApiKey`/`rotateApiKey`/`listApiKeys` sem recorrer a uma chamada manual.
- OAuth 2.0 client credentials não implementado (explicitamente opcional no backlog).
- Rewrite de Hosting para URL amigável não configurado (nenhum site de Hosting provisionado ainda).

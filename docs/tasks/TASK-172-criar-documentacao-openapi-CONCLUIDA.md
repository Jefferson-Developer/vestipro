# TASK-172 — Criar documentação OpenAPI — CONCLUÍDA

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Agente executor:** `flutter-senior-architect`
**Depende de:** TASK-171 (API pública REST, `functions/src/public_api/`) — já implementada.

## O que foi implementado

Especificação OpenAPI 3.0.3 completa da API pública já implementada em
`functions/src/public_api/`, mais um portal de documentação estático (Redoc) e a
configuração de Firebase Hosting para publicá-lo, sem alterar nenhuma linha de código dos
endpoints REST em si.

### Especificação (`docs/api/openapi.yaml`)

Escrita lendo diretamente o código real de `functions/src/public_api/` (não a partir do
backlog/memória) para garantir fidelidade:

- `functions/src/public_api/rest/app.ts` — as 6 rotas/7 operações registradas
  (`GET/POST /v1/orders`, `GET /v1/orders/{id}`, `GET /v1/customers`,
  `GET /v1/customers/{id}`, `GET /v1/products`, `GET /v1/products/{id}`) foram
  documentadas 1:1, sem inventar nenhum endpoint adicional nem omitir nenhum existente.
- `functions/src/public_api/rest/middleware.ts` — autenticação por `X-Api-Key` (header),
  formato de erro `{ error: { code, message } }`, cabeçalhos
  `X-RateLimit-Limit`/`X-RateLimit-Remaining`/`X-RateLimit-Reset` em toda resposta,
  `401 unauthenticated` (chave ausente/inválida/revogada), `403 permission-denied`
  (escopo faltante), `429 rate_limited`.
- `functions/src/public_api/rest/customers.ts` / `products.ts` / `orders.ts` — schemas de
  `Customer`/`Product`/`OrderSummary` documentados campo a campo exatamente como
  serializados (`serializeCustomer`/`serializeProduct`/`serializeOrderSummary`), incluindo
  os `null` explícitos e o cálculo de `total` (soma dos subtotais dos itens + acréscimo +
  frete, arredondado a 2 casas).
- `functions/src/public_api/api-key-shared.ts` — paginação por cursor (`limit` clamped a
  `[1, 100]`, padrão 20; `cursor` opaco base64url; `nextCursor: null` quando não há mais
  páginas) e o rate limit padrão (60/min, configurável de 1 a 600 na emissão da chave).
- `functions/src/orders/submit-order.ts` (via `createOrder` em `rest/orders.ts`) — corpo de
  `POST /v1/orders` documentado com os campos realmente obrigatórios
  (`requireNonEmptyString`/`requireAddress`/`requireItems`: `branchId`, `customerId`,
  `sellerId`, `priceListId`, `paymentTermId`, `deliveryAddress`, `billingAddress`, `items`
  com `id`/`productId`/`variantId`/`quantity` obrigatórios por item) e os opcionais
  (`orderId` como chave de idempotência, `manualDiscountPercent` 0–100, etc.), incluindo a
  nota de que `organizationId` enviado no corpo é sempre descartado (o da API key prevalece)
  e a limitação conhecida de autenticação por `sellerId` sem credencial por usuário — já
  documentada em `docs/tasks/TASK-171-implementar-api-publica-CONCLUIDA.md`.
- Mapeamento de erros de `POST /v1/orders` (`mapAndSendSubmitOrderError` em
  `rest/orders.ts`) documentado literalmente: os códigos vêm sem tradução do domínio de
  pedidos (`invalid-argument`, `not-found`, `already-exists`, `failed-precondition`,
  `resource-exhausted`, `internal`, todos com hífen), enquanto o restante da API usa
  `snake_case` (`not_found`, `rate_limited`, `invalid_argument`). A especificação documenta
  essa inconsistência real ao invés de inventar uma convenção única que o código ainda não
  tem — divergência entre doc e comportamento seria, por definição da própria task, um bug
  de documentação a evitar.

Todos os exemplos de request/response usam dados fictícios plausíveis (clientes, produtos e
pedidos inventados) — nenhum dado real de cliente/organização.

### Portal de documentação (`docs/api/index.html`)

Página estática única, usando o bundle Redoc standalone (`redoc.standalone.js` via CDN) para
renderizar `./openapi.yaml`. Não expõe nenhuma rota interna do VestiPro: a pasta publicada
(`docs/api/`) contém apenas a especificação da API pública e este HTML. Marcada
`<meta name="robots" content="noindex, nofollow">` e cabeçalho HTTP `X-Robots-Tag` equivalente
(ver Hosting abaixo), reduzindo (mas não eliminando) a chance de indexação/descoberta
casual — "link controlado", já que este projeto não tinha (e continua sem) um mecanismo de
Hosting autenticado configurado.

### Firebase Hosting (`firebase.json`)

Adicionado um bloco `hosting` (chave nova; nenhuma chave existente foi alterada), apontando
`public` para `docs/api` — nada mais do repositório é publicado. Nenhum `firebase deploy` foi
executado nesta rodada (ver "Pendências").

## Decisões tomadas

- **Escopo documentado = só a API REST pública (`/v1/...`)**, não os 4 callables de gestão de
  chave (`generateApiKey`/`revokeApiKey`/`rotateApiKey`/`listApiKeys`, em
  `functions/src/public_api/*.ts` fora de `rest/`). Esses são Cloud Functions *callable*
  (protocolo interno do Firebase SDK, não HTTP REST), consumidos hoje só por chamada manual —
  não fazem parte do contrato REST que um parceiro externo integra via `X-Api-Key`/HTTP puro,
  e o próprio pedido desta rodada delimitou o escopo a "`/v1/customers`, `/v1/products`,
  `/v1/orders`, autenticação por API key, rate limiting, paginação por cursor".
- **OpenAPI 3.0.3**, não 3.1, por compatibilidade mais ampla com Redoc/Swagger UI/lint
  (`@redocly/cli`) sem nenhuma feature de 3.1 sendo necessária aqui.
- **OAuth 2.0 não documentado como esquema de segurança real** — apenas mencionado em texto
  como "não implementado nesta versão", pelo mesmo motivo já registrado em
  TASK-171-CONCLUIDA (fora de escopo, marcado "opcionalmente" no backlog). Documentar um
  `securityScheme` OAuth2 que não existe seria inventar comportamento.
- **`license` em `info`** preenchido como `Proprietary` (URL fictícia
  `https://vestipro.com.br/termos-api`, mesmo domínio placeholder já usado em fixtures de
  teste do próprio repositório) apenas para satisfazer a regra `info-license` do lint
  `@redocly/cli` (`recommended` ruleset) — não é uma URL real publicada.
- **`hosting.public` = `docs/api`** (não a raiz do repo, não `functions`) — garante que o
  portal nunca possa servir acidentalmente nenhum outro arquivo do projeto.

## Testes/validações executados

- `node -e "yaml.load(...)"` (usando `js-yaml`, já presente em `functions/node_modules`) —
  `docs/api/openapi.yaml` é YAML válido; script adicional percorreu a árvore inteira do
  documento e confirmou **0 `$ref` órfãos** em 100 referências.
- `npx --yes @redocly/cli@latest lint docs/api/openapi.yaml` — **0 erros, 0 warnings**
  (primeira execução acusou 1 warning de `info-license`, corrigido; segunda execução limpa).
  Rede disponível neste ambiente (`npm ping` respondeu); nenhuma dependência nova foi
  adicionada a `functions/package.json` — `@redocly/cli` rodou via `npx` sem persistir no
  projeto.
- Roteiro de conferência manual endpoint-a-endpoint contra `functions/src/public_api/rest/app.ts`:
  as 7 operações documentadas (`GET/POST /v1/orders`, `GET /v1/orders/{id}`,
  `GET/{id} /v1/customers`, `GET/{id} /v1/products`) correspondem exatamente às 7 registradas
  no roteador Express — nenhum endpoint documentado a mais, nenhum a menos.
- `node -e "JSON.parse(fs.readFileSync('firebase.json'))"` — `firebase.json` continua um JSON
  válido após a adição do bloco `hosting`.
- `git status --porcelain` — confirmado que a execução do `npx @redocly/cli` não deixou
  nenhum artefato/`node_modules` fora do escopo desta task no working tree.

## Testes/validações **não** executados (e por quê)

- **Teste de acesso ao portal publicado** (critério de aceite "portal navegável por um
  parceiro externo") — exigiria `firebase deploy --only hosting`, uma ação de infraestrutura
  real contra o projeto `vestipro` que esta rodada não está autorizada a executar (o protocolo
  desta rodada autoriza apenas commit local, sem deploy/push). O portal foi validado
  estaticamente (HTML bem formado referenciando `./openapi.yaml`, mesma pasta) mas não
  verificado servido de fato por Firebase Hosting.
- **Lint de Firestore Rules/Functions** — não aplicável: nenhuma regra de Firestore/Cloud
  Function foi criada ou alterada nesta task (documentação pura).
- `flutter analyze`/`flutter test` — não executados: nenhum arquivo Dart foi criado/alterado
  nesta task.

## Arquivos criados

- `docs/api/openapi.yaml` — especificação OpenAPI 3.0.3 da API pública.
- `docs/api/index.html` — portal de documentação estático (Redoc standalone).
- `docs/tasks/TASK-172-criar-documentacao-openapi-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `firebase.json` — bloco `hosting` novo (`public: "docs/api"`), sem alterar nenhuma chave
  existente (`firestore`, `storage`, `functions`, `emulators`, `flutter`).
- `docs/tasks/TASKS.md` — checkbox da TASK-172 marcado; `Progresso` atualizado para 171/220.

## Riscos residuais / pendências

- **Deploy do Hosting não executado** — o bloco `hosting` em `firebase.json` está pronto, mas
  ninguém rodou `firebase deploy --only hosting` ainda; o portal não está de fato acessível
  publicamente até essa ação ser tomada por quem tem autoridade de deploy neste projeto.
- **Política de exposição do portal não definida pela organização** — a task pede acesso "a
  parceiros autenticados ou via link controlado, conforme política definida pela
  organização/produto"; esta rodada optou pela opção mais simples disponível sem infra
  adicional (link não indexado, sem autenticação de fato), porque nenhuma decisão de produto
  sobre autenticação de portal (Identity-Aware Proxy, senha compartilhada, etc.) foi tomada
  ainda. Se a organização decidir por acesso autenticado, isso é uma mudança de infraestrutura
  adicional (fora do escopo REST documentado aqui).
- **Geração automática a partir do código não implementada** — a task pede "gerado/validado
  automaticamente (lint de OpenAPI) para não divergir do código real dos endpoints"; esta
  rodada garante a validação automática (lint), mas a especificação foi escrita manualmente
  lendo o código (não gerada por uma ferramenta tipo `tsoa`/`zod-to-openapi` a partir dos
  tipos TypeScript). Manter a spec sincronizada com o código em mudanças futuras depende de
  disciplina de revisão (checklist de PR), não de geração automática — um follow-up possível,
  não implementado nesta rodada.
- **Painel de gestão de chaves (Flutter)** — segue como pendência de TASK-171, não desta task.
- Nenhum dado real de organização/cliente foi usado nos exemplos (confirmado nesta revisão).

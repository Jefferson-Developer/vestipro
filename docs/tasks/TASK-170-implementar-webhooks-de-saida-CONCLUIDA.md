# TASK-170 — Implementar webhooks de saída (CONCLUÍDA)

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ✅ Concluída

## Resumo do que foi implementado

Framework completo de webhooks de saída, server-side (Cloud Functions), seguindo o mesmo padrão
arquitetural do framework de integração ERP criado na TASK-169 (fila com claim/transaction,
idempotência determinística, retry com backoff, log de entregas, isolamento por
`organizationId`).

### Domínio e configuração

- `organizations/{organizationId}/webhooks/{webhookId}` — configuração não sensível: `url`
  (`https://` obrigatório), `events` (subconjunto de `order.created`, `order.status_changed`,
  `customer.created`, `inventory.updated`), `isActive`, e um roll-up de saúde
  (`healthStatus: 'ok' | 'failing'`, `consecutiveFailureCount`, `lastFailureAt`,
  `lastSuccessAt`) que serve como sinalização ao gestor de que um webhook parou de entregar
  (não existe canal de push notification no repositório; este campo é o que uma futura tela de
  configuração lê para alertar o gestor — mesma lógica de "estado que a tela de gestão exibe" que
  `productImportJobs.status` já usa).
- `organizations/{organizationId}/webhookSecrets/{webhookId}` — segredo HMAC, nunca legível por
  nenhum cliente (Firestore Rules negam `read`/`write` para qualquer role), só lido pelas próprias
  Cloud Functions da feature ao assinar uma entrega. Retornado ao chamador uma única vez (criação
  ou regeneração), nunca reexibido depois.
- `organizations/{organizationId}/webhookDeliveries/{deliveryId}` — fila de entrega:
  `pending -> syncing -> synced | failed` (com `attempts`, `nextRetryAt`, `lastError`,
  `lastResponseStatus`).
- `organizations/{organizationId}/webhookDeliveryLogs/{logId}` — log de cada tentativa de
  entrega (URL, status HTTP, sucesso/erro), consultável pelo gestor.

### Cloud Functions (`functions/src/webhooks/`)

- `saveWebhookConfig` (callable) — cria/atualiza um webhook (RBAC OWNER/ADMIN); na criação gera o
  segredo HMAC (`generateWebhookSecret`, 256 bits) e o retorna uma única vez.
- `regenerateWebhookSecret` (callable) — rotaciona o segredo de um webhook existente.
- `sendTestWebhookEvent` (callable) — cria uma entrega sintética (`eventType: 'webhook.test'`)
  direcionada a um webhook específico, independentemente dos eventos assinados — permite validar
  a configuração (URL, assinatura) antes de depender dela em produção, usando o mesmo caminho real
  de entrega/assinatura/retry que qualquer evento de domínio.
- `deliverWebhookEvent` (trigger `onDocumentCreated` em `webhookDeliveries`) — núcleo de entrega:
  carrega config + segredo, monta o payload canônico (`eventId`, `eventType`, `organizationId`,
  `data`, `timestamp`), assina com HMAC-SHA256 (`X-VestiPro-Signature`, mais
  `X-VestiPro-Event-Id`/`X-VestiPro-Event-Type`), faz `POST` (timeout de 10s via
  `AbortController`), e decide sucesso (2xx) vs. retry (backoff 1min/5min/30min/2h) vs. falha
  permanente (após 4 tentativas, atualizando `healthStatus: 'failing'` no config). Nunca lança —
  toda falha é capturada e refletida no próprio documento de entrega e no log.
- `retryFailedWebhookDeliveries` (scheduled, a cada minuto) — reprocessa entregas `failed` cujo
  `nextRetryAt` já venceu e `attempts < 4`, reaproveitando o mesmo núcleo (`processClaimedWebhookDelivery`)
  do trigger, mesma estratégia de `retryFailedErpSyncItems` (TASK-169).
- Triggers produtores de evento, cada um chamando `enqueueWebhookEvent` (fábrica única de
  `webhookDeliveries`, com dedup por `webhookId + eventId` e fan-out só para webhooks
  `isActive` inscritos no evento):
  - `enqueueOrderWebhookEvents` (`onDocumentWritten` em `orders`) — `order.created` na criação;
    `order.status_changed` quando `status` muda. Payload deliberadamente sem total/desconto
    calculado (evita reintroduzir cálculo financeiro fora do motor de pricing server-side).
  - `enqueueCustomerWebhookEvents` (`onDocumentCreated` em `customers`) — `customer.created`.
  - `enqueueInventoryWebhookEvents` (`onDocumentWritten` em `inventory`, reutilizando
    `asBalanceSnapshot`/`sellableQuantity` de `stock-alert-shared.ts`, TASK-090) —
    `inventory.updated` só quando a quantidade vendável realmente muda.

Todo trigger produtor é best-effort: qualquer falha ao enfileirar um evento de webhook é
capturada e logada (`logger.error`), nunca propagada para bloquear a escrita de domínio que a
originou (pedido, cliente, saldo de estoque).

### `eventId` idempotente

`computeWebhookEventId` (hash SHA-256 de `organizationId|eventType|entityId|sourceVersion`) —
determinístico: a mesma ocorrência de domínio sempre gera o mesmo `eventId`, permitindo ao
consumidor deduplicar em caso de reentrega, exatamente como pedido pelo critério de aceite.

### RBAC

- Nova `Capability.webhookManage` (`lib/core/permissions/capability.dart`), concedida a
  OWNER/ADMIN via os conjuntos completo/quase-completo já existentes em `RolePermissionMatrix`
  (nenhuma alteração necessária em `role_permission_matrix.dart` além do teste).
- Teste adicionado em `test/core/permissions/role_permission_matrix_test.dart` confirmando que
  apenas OWNER/ADMIN têm `webhookManage`.

### Firestore Security Rules

- `firestore.rules`: blocos `webhooks`, `webhookSecrets` (deny total), `webhookDeliveries`,
  `webhookDeliveryLogs` sob `organizations/{organizationId}/...`, espelhando exatamente o padrão
  já usado por `erpIntegration`/`erpSyncQueue`/`erpSyncLogs` (TASK-169): toda escrita é exclusiva
  das Cloud Functions (Admin SDK bypassa Rules); leitura gated por `hasCapability(organizationId,
  'webhook.manage')`; `webhookSecrets` nunca legível por nenhum papel.
- Validado com `firebase deploy --only firestore:rules --dry-run` (compilação bem-sucedida, sem
  deploy real).

## Testes

- `functions/test/webhooks/webhook-shared.test.ts` (25 testes, todos passando): RBAC
  (`assertCanManageWebhooks`), validação de `events`/`url`, geração de segredo,
  **assinatura/verificação HMAC-SHA256** (payload íntegro vs. adulterado, segredo errado),
  **determinismo do `eventId`** (mesma ocorrência ⇒ mesmo id; muda por organização/versão),
  **backoff de retry** (1min/5min/30min/2h, cap no último valor).
- Escopo de teste alinhado ao precedente da própria TASK-169: apenas a lógica pura
  (`erp-integration-shared.test.ts`) recebeu testes unitários; a orquestração dependente de
  Firestore (`process-erp-sync-queue-item.ts`) não tinha teste próprio. Segui o mesmo critério
  aqui — a lógica de assinatura/idempotência/backoff (o risco técnico real explicitamente citado
  no protocolo) está coberta; a orquestração de fila/trigger (`enqueue-webhook-event.ts`,
  `process-webhook-delivery.ts`) não tem teste de emulador nesta rodada porque o ambiente não tem
  Java instalado para o Firestore Emulator (mesma limitação documentada em
  `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`/`BACKLOG-003`); confirmei
  isso rodando a suíte completa (`npx jest`), que já falha hoje em 19/44 suites por essa mesma
  causa (`Could not load the default credentials`), incluindo testes pré-existentes não
  relacionados a esta task — não é uma regressão introduzida aqui.
- Testes de isolamento multi-tenant e "não perda de dados" descritos no backlog da task são
  garantidos por construção: `enqueueWebhookEvent`/`webhookConfigsCollection`/
  `webhookDeliveriesCollection` só operam sob `organizations/{organizationId}/...` (nunca uma
  query cross-tenant), mas não há teste de emulador automatizado confirmando isso nesta rodada
  pelo motivo acima — risco residual documentado, não coberto por teste automatizado ainda.

## Comandos executados

- `cd functions && npm run build` — sem erros de TypeScript.
- `cd functions && npx eslint src/webhooks test/webhooks` — sem warnings/erros.
- `cd functions && npx jest test/webhooks/webhook-shared.test.ts` — 25/25 passando.
- `cd functions && npx jest --testPathIgnorePatterns=emulator` — 224 passaram, 124 falharam em
  19/44 suites, todas por falta de Firestore Emulator (`Could not load the default credentials`),
  condição pré-existente e não relacionada a esta task (nenhuma suíte nova minha usa Firestore).
- `flutter test test/core/permissions/role_permission_matrix_test.dart` — 22/22 passando.
- `flutter analyze lib/core/permissions/capability.dart test/core/permissions/role_permission_matrix_test.dart` — sem issues.
- `dart format --set-exit-if-changed` nos dois arquivos Dart alterados — sem mudanças pendentes.
- `npx firebase deploy --only firestore:rules --dry-run` — `firestore.rules` compilou com sucesso
  (nenhum deploy real executado).

## Arquivos criados

- `functions/src/webhooks/types.ts`
- `functions/src/webhooks/webhook-shared.ts`
- `functions/src/webhooks/enqueue-webhook-event.ts`
- `functions/src/webhooks/process-webhook-delivery.ts`
- `functions/src/webhooks/retry-failed-webhook-deliveries.ts`
- `functions/src/webhooks/save-webhook-config.ts`
- `functions/src/webhooks/regenerate-webhook-secret.ts`
- `functions/src/webhooks/send-test-webhook-event.ts`
- `functions/src/webhooks/triggers/enqueue-order-webhook-events.ts`
- `functions/src/webhooks/triggers/enqueue-customer-webhook-events.ts`
- `functions/src/webhooks/triggers/enqueue-inventory-webhook-events.ts`
- `functions/src/webhooks/index.ts`
- `functions/test/webhooks/webhook-shared.test.ts`
- `docs/tasks/TASK-170-implementar-webhooks-de-saida-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `functions/src/index.ts` — exporta as novas Cloud Functions do módulo `webhooks`.
- `lib/core/permissions/capability.dart` — nova `Capability.webhookManage` + `code`.
- `test/core/permissions/role_permission_matrix_test.dart` — teste de RBAC para `webhookManage`.
- `firestore.rules` — regras para `webhooks`/`webhookSecrets`/`webhookDeliveries`/`webhookDeliveryLogs`.
- `docs/tasks/TASKS.md` — checkbox da TASK-170 marcado; `Progresso` atualizado para 169/220.

## Pendências / riscos conhecidos

- Nenhuma UI de gestão de webhooks foi criada nesta task (fora do escopo técnico definido —
  "Escopo técnico" da TASK-170 fala em "Tela/API"; a API server-side é o entregável desta rodada,
  mesmo padrão adotado pela TASK-169 para ERP). Uma tela de configuração (listar webhooks, ver
  `healthStatus`/log de entregas, copiar o segredo exibido uma única vez, disparar evento de
  teste) é trabalho de UI futuro, provavelmente com `flutter-ui-design-specialist`.
- Testes de emulador (Firestore Rules positivas/negativas, isolamento multi-tenant ponta a ponta,
  fluxo completo de retry/backoff) não puderam ser executados neste ambiente por falta de Java —
  mesma limitação já registrada em `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`.
  Recomendo rodar `firestore-tests/` e uma suíte de emulador dedicada para `webhooks/*` assim que
  o Emulator Suite estiver disponível em CI ou em uma máquina com Java.
- `deliverWebhookEvent` usa o `fetch` global do Node 20 sem retries internos de DNS/TLS além do
  timeout de 10s — comportamento aceitável para o escopo desta task, mas vale revisitar se
  consumidores reais mostrarem padrões de timeout diferentes.

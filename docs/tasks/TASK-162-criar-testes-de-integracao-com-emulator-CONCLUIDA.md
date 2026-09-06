# TASK-162 — Criar testes de integração com Firebase Emulator (CONCLUÍDA)

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Agente utilizado:** `flutter-senior-architect` (execução direta, sem sub-delegação — o escopo já
estava mapeado após levantamento do estado real do repositório).

## Resumo

O repositório já chegava a esta task com uma suíte de integração contra o Firebase Emulator Suite
bastante madura, construída ao longo de ~160 tasks anteriores:

- `firestore-tests/firestore.rules.test.js` (TASK-030): testes positivo/negativo de `firestore.rules`
  cobrindo `customers`, `orders`, `priceLists`, `auditLogs` e dezenas de outras entidades, incluindo
  vários cenários cross-tenant (Org A nunca lê/escreve dado da Org B) já validados diretamente contra
  as Rules reais no Emulator.
- `storage-tests/storage.rules.test.js` (TASK-031): idem para `storage.rules`, incluindo Cross-Service
  Security Rules (Storage relendo Membership no Firestore).
- `functions/test/orders/submit-order.test.ts` e `functions/test/orders/decide-order-approval.test.ts`:
  testes de integração reais (Firestore Admin SDK contra o Emulator, não mockados) para geração de
  número de pedido e aprovação/rejeição.
- `integration_test/`: testes de integração client-side (Flutter) para `CloudFunctionsService`,
  `FirebaseAuthDataSource`, `FirestoreCollectionDataSource`, `FirebaseStorageDataSource` e o repositório
  de variantes de produto.

Levantamento de gaps contra os "Testes obrigatórios" e "Critérios de aceite" da task encontrou duas
lacunas reais e um item de automação ausente, que foram o escopo efetivo implementado aqui:

1. **`calculatePricing` (motor de precificação server-side) só tinha teste unitário mockado**
   (`functions/test/pricing/calculate-pricing.test.ts`, com uma implementação fake de
   `Firestore.DocumentReference`/`CollectionReference` em memória) — violando a regra explícita da task
   ("não apenas teste unitário mockado"). Não existia nenhum teste rodando o `onCall` real contra um
   Firestore Emulator real para essa function.
2. **Concorrência da geração de número de pedido só era testada para o cenário de idempotência** (duas
   chamadas simultâneas com o **mesmo** `orderId`/payload, que devem colapsar em um único pedido) — não
   havia teste cobrindo duas submissões **diferentes** e genuinamente concorrentes disputando o mesmo
   contador `orderNumberSequences/{companyId}`, que é o cenário literal pedido pela task ("unicidade sob
   concorrência").
3. **Não existia um comando único, plugável em CI**, que rodasse toda a suíte (Rules + Functions +
   integração client-side Flutter) via `firebase emulators:exec` — cada suíte só tinha seu comando
   documentado isoladamente em comentários de arquivo.

## Arquivos criados

- `functions/test/pricing/calculate-pricing.emulator.test.ts` — novo teste de integração real (Firebase
  Admin SDK + `firebase-functions-test`, mesmo padrão de `submit-order.test.ts`) para o `onCall`
  `calculatePricing`, cobrindo: preço correto sem desconto; desconto manual dentro do limite (sem
  aprovação); desconto acima do limite de aprovação mas dentro do máximo (`approvalRequired: true`);
  desconto acima do máximo (`blocked: true`); bloqueio quando não há política de desconto ativa para o
  papel do usuário; idempotência (mesma `idempotencyKey` replica a resposta cacheada em
  `pricingCalculations/{idempotencyKey}`); conflito de idempotência (mesma key, payload diferente →
  `already-exists`); chamada não autenticada (`unauthenticated`); usuário sem Membership na organização
  (`permission-denied`). 9 testes, nenhum mock de Firestore — todos contra o Emulator real.
- `package.json` (raiz do repositório) — orquestração dos 4 comandos de integração já existentes/criados
  em um único ponto de entrada (`npm run test:integration`), pensado para ser plugado diretamente num
  job de CI na TASK-165 (ver "Decisões técnicas").
- `docs/tasks/TASK-162-criar-testes-de-integracao-com-emulator-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `functions/test/orders/submit-order.test.ts` — adicionado o teste `'assigns unique, non-colliding
  sequential order numbers to two genuinely concurrent submissions of two different orders'`: duas
  chamadas `submitOrder` com `orderId` diferentes (`order-1`, `order-2`) disparadas via `Promise.all`,
  validando que os dois pedidos recebem números sequenciais únicos (`000001`/`000002`, sem colisão nem
  repetição), que exatamente 2 documentos de pedido existem ao final e que o estoque foi debitado pelas
  duas submissões (10 → 6). Este teste depende da concorrência real de transação do Firestore Emulator
  (retry otimista do "loser"), não de um mock — não seria possível reproduzir a garantia real sem o
  Emulator.
- `docs/tasks/TASKS.md` — checkbox da TASK-162 marcado como concluído e contador de progresso
  incrementado.

## Testes obrigatórios da task — cobertura final

| Requisito | Onde |
|---|---|
| Integração da Cloud Function de precificação (preço correto, desconto bloqueado/aprovação) | `functions/test/pricing/calculate-pricing.emulator.test.ts` (novo) |
| Geração de número de pedido — unicidade sob concorrência (2 submissões simultâneas) | `functions/test/orders/submit-order.test.ts` (teste novo, adicionado ao describe existente) |
| Rules positivo/negativo — `customers`, `orders`, `priceLists`, `auditLogs` | `firestore-tests/firestore.rules.test.js` (já existente, TASK-030 — auditado, cobertura confirmada) |
| Multi-tenant negativo (Org A nunca lê/escreve dado da Org B) | `firestore-tests/firestore.rules.test.js` e `storage-tests/storage.rules.test.js` (já existentes — múltiplos testes "cross-tenant" auditados) |
| Pipeline automatizado via `firebase emulators:exec` cobrindo Functions e Rules | `package.json` raiz, script `test:integration` (novo) |

## Comandos executados e resultados reais

Ambiente sem Java instalado (`java -version` → `command not found`), portanto os emuladores de
Firestore/Storage (que exigem JRE) **não podem ser iniciados neste sandbox** — limitação de ambiente
pré-existente e já documentada em `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`.
O Firebase CLI está instalado (`firebase --version` → `15.24.0`), mas sem Java `firebase
emulators:exec` não consegue subir o Emulator Suite. Isso significa que **nenhum teste que dependa do
Emulator rodando (os novos e os pré-existentes) pôde ser executado de fato nesta sessão** — nem
inventei resultado de execução para eles.

O que foi realmente executado e o resultado real:

- `npm run lint` (`eslint src test`) dentro de `functions/` → **passou sem erros/warnings**, cobrindo o
  arquivo novo e o arquivo alterado.
- `npx jest --listTests` dentro de `functions/` → o novo arquivo
  (`test/pricing/calculate-pricing.emulator.test.ts`) foi corretamente descoberto pelo `testMatch`
  do Jest, junto dos demais 37 arquivos de teste já existentes.
- `npx tsc` com uma cópia local e temporária do `tsconfig.json` de `functions/` (mesmas
  `compilerOptions` reais, apenas com `test/pricing/calculate-pricing.emulator.test.ts` e
  `test/orders/submit-order.test.ts` incluídos além de `src/**/*.ts`, já que o `tsconfig.json` real
  exclui `test/` do type-check de build) → **compilou sem nenhum erro**. O arquivo temporário foi
  removido ao final, não faz parte do commit.
- `node -e "JSON.parse(...)"` sobre o `package.json` novo da raiz → JSON válido, scripts conferidos.

Não executados nesta sessão (ambiente sem Java/Emulator, resultado seria inventado):

- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`
- `firebase emulators:exec --only firestore,storage "npm --prefix storage-tests test"`
- `firebase emulators:exec --only auth,firestore "npm --prefix functions test"` (inclui os 2 novos
  cenários de `calculate-pricing.emulator.test.ts` e o novo teste de concorrência em
  `submit-order.test.ts`)
- `firebase emulators:exec --only auth,firestore,storage,functions "flutter test integration_test -d chrome"`
- `npm run test:integration` (o orquestrador novo, que só encadeia os 4 comandos acima)

Nenhum arquivo Dart foi criado ou alterado nesta task (o gap real estava inteiramente do lado
Functions/Node), então `dart format`/`flutter analyze`/`flutter test` não se aplicam a este diff.

## Decisões técnicas

- **Não recriei a arquitetura de testes já estabelecida.** O texto original da task fala em
  `firebase emulators:exec "flutter test integration_test"` como se toda a suíte vivesse no lado
  Flutter; na prática, ao longo do projeto real, Rules e Functions passaram a ser testadas em
  suítes Node/Jest dedicadas (`firestore-tests/`, `storage-tests/`, `functions/test/`), com
  `integration_test/` (Flutter) reservado para a camada de datasource client-side. Essa divisão já
  está consolidada em ~10 tasks concluídas anteriores (TASK-030, TASK-031, TASK-088, TASK-101,
  TASK-102/103, TASK-094 etc.) e documentada no `README.md`. Romper esse padrão para forçar tudo
  dentro de `integration_test/` duplicaria testes já corretos e divergiria da convenção real do
  repositório — por isso o `package.json` novo orquestra as 4 suítes existentes em vez de reescrevê-las.
- **`calculate-pricing.emulator.test.ts` não substitui `calculate-pricing.test.ts`.** O arquivo
  pré-existente (fake Firestore em memória) continua cobrindo exaustivamente as ramificações do motor de
  precificação em isolamento e roda rápido sem Emulator — mantido como está. O novo arquivo valida o
  mesmo Cloud Function ponta a ponta (o `onCall` real, o cache de idempotência real lendo/escrevendo no
  Firestore real, os documentos reais de `priceLists`/`paymentTerms`/`discountPolicies`), que é
  exatamente o que a task pede ("não apenas teste unitário mockado") e que o arquivo fake não conseguia
  garantir.
- **O teste de concorrência do número de pedido usa dois `orderId` diferentes**, não repete o teste de
  idempotência já existente (que usa o mesmo `orderId` de propósito, para provar deduplicação). O
  cenário pedido pela task — unicidade sob concorrência de duas submissões simultâneas — só é
  genuinamente exercitado quando os dois pedidos são realmente distintos e disputam o mesmo contador.
- **`package.json` na raiz roda cada suíte em uma invocação separada de `firebase emulators:exec`**, em
  vez de um único Emulator Suite compartilhado por todas as suítes. Isso reflete a mesma escolha já
  presente nos comentários de cabeçalho de cada suíte (`--only firestore` para Rules puras, `--only
  firestore,storage` para Storage Rules com Cross-Service Rules, etc.) e evita interferência de dados
  entre suítes que usam `projectId`s lógicos diferentes mas compartilham o mesmo Emulator físico sob
  `singleProjectMode: true`. O trade-off é~4 inicializações de Emulator em vez de 1; aceitável dado que
  o objetivo imediato é ter *um comando* plugável em CI (`npm run test:integration`), não otimizar o
  tempo total de execução — isso pode ser revisitado na TASK-165 se o tempo de pipeline for um problema.

## Riscos e pendências

- **Risco de ambiente, não de código:** nenhum teste (novo ou pré-existente) que dependa do Firebase
  Emulator pôde ser executado de fato neste sandbox por falta de Java — mesma limitação documentada em
  `docs/backlog/BACKLOG-002-suite-de-testes-firestore-rules-em-ci.md`. Os testes novos foram
  type-checados e lint-ados, mas **não têm confirmação de execução real (verde) nesta sessão**. Alguém
  com Java instalado (ou a TASK-165 configurando CI com JRE) precisa rodar `npm run test:integration` (ou
  os 4 comandos individuais) pelo menos uma vez antes de considerar este pacote de testes validado em
  produção.
- BACKLOG-002 continua pendente (suíte sem CI) — o `package.json` novo é o artefato que a TASK-165 deve
  consumir para fechar esse backlog junto com a criação do pipeline de CI.
- BACKLOG-003 (Firestore Rules em "modo teste" no projeto real `vestipro`) é ortogonal a esta task — não
  foi tocado aqui; o `firestore.rules` versionado no repositório (usado pelos testes) continua correto.

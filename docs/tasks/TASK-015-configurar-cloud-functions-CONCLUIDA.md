# TASK-015 — Concluída (2026-08-21)

## Resumo

Projeto de Cloud Functions inicializado em TypeScript em `functions/` (antes um placeholder JS
vazio da TASK-010), estruturado por domínio (`src/health` com a função de exemplo `healthCheck`;
`src/auth`, `src/pricing`, `src/orders`, `src/insights`, `src/admin` reservados e vazios de
propósito, cada um apontando para a task que vai populá-lo) e com `src/shared/callable-meta.ts`
(helper de correlation id compartilhado por toda função futura). `healthCheck` é uma callable sem
regra de negócio, usada só para validar o pipeline de ponta a ponta (build, lint, deploy, emulador,
wrapper client-side, correlation id, erro). Do lado Flutter, `lib/core/functions/` ganhou
`CloudFunctionsService` — único ponto do app autorizado a chamar `cloud_functions` — com correlation
id, metadata de app/plataforma (sob a chave `_meta`, para nunca colidir com o payload de cada
função), retry com backoff restrito a códigos de erro transitórios, medição de tempo de resposta
(seam para a TASK-019) e conversão de `FirebaseFunctionsException` para a hierarquia
`AppException`/`Failure` já existente. `FirebaseFunctions` foi registrado como `@lazySingleton` em
`lib/app/injection_module.dart`, conectando ao Functions Emulator fora do `prod` (mesmo padrão de
Firestore/Storage). Pipeline de deploy documentado em `functions/README.md`, respeitando a ADR-0002
(um único projeto Firebase real, `vestipro`; dev/staging nunca deployam, só usam o emulador).

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `.firebaserc` (alias `default` → `vestipro`, ADR-0002)
- `functions/README.md`
- `functions/tsconfig.json`
- `functions/eslint.config.js`
- `functions/jest.config.js`
- `functions/src/index.ts`
- `functions/src/health/health-check.ts`
- `functions/src/shared/callable-meta.ts`
- `functions/src/auth/index.ts` (reservado, TASK-029)
- `functions/src/pricing/index.ts` (reservado, TASK-088)
- `functions/src/orders/index.ts` (reservado, TASK-101)
- `functions/src/insights/index.ts` (reservado, TASK-121)
- `functions/src/admin/index.ts` (reservado, TASK-033)
- `functions/test/health-check.test.ts`
- `functions/test/callable-meta.test.ts`
- `lib/core/functions/app_client_metadata.dart`
- `lib/core/functions/cloud_functions_exception_mapper.dart`
- `lib/core/functions/cloud_functions_service.dart`
- `lib/core/functions/configure_functions.dart`
- `lib/core/functions/functions.dart` (barrel público do módulo)
- `test/core/functions/cloud_functions_exception_mapper_test.dart`
- `test/core/functions/cloud_functions_service_test.dart`
- `integration_test/core/functions/cloud_functions_service_integration_test.dart`
- `docs/tasks/TASK-015-configurar-cloud-functions-CONCLUIDA.md`

## Arquivos alterados

- `functions/package.json` (reescrito: TypeScript, ESLint, Jest, `firebase-admin`,
  `firebase-functions-test`, scripts `build`/`lint`/`test`/`serve`/`shell`/`deploy`/`logs`)
- `functions/package-lock.json` (regenerado por `npm install`)
- `firebase.json` (bloco `functions[0].predeploy`: `lint` + `build` antes de todo deploy)
- `lib/app/injection_module.dart` (`@lazySingleton FirebaseFunctions firebaseFunctions(AppEnvironment)`
  chamando `configureFunctions`)
- `lib/app/injection.config.dart` (regenerado por `build_runner`, registra `FirebaseFunctions`,
  `AppClientMetadataProvider`/`PackageInfoClientMetadataProvider` e `CloudFunctionsService`)
- `README.md` (seção "Backend e Firebase": Functions já conectado, e onde/por quê)
- `docs/tasks/TASKS.md` (checkbox da TASK-015 e progresso)

## Arquivos removidos

- `functions/index.js` (placeholder JS da TASK-010, substituído por `src/index.ts` + build TS →
  `lib/index.js`, gitignorado)

## Arquitetura utilizada

Lado servidor: `functions/src/` por domínio, cada pasta reservada com um `index.ts` só com
`export {}` e um comentário apontando a task que a populará — nenhuma é importada por
`src/index.ts` até ter uma função real para exportar. `src/shared/callable-meta.ts` define o
contrato `_meta`/`resolveCorrelationId` que qualquer função futura (não só `healthCheck`) pode
reusar. Lado cliente: `lib/core/functions/` segue exatamente o padrão já estabelecido por
`lib/core/database/` (TASK-013) e `lib/core/storage/` (TASK-014) — `configureFunctions` (emulador),
um mapper de exceção (`cloud_functions_exception_mapper.dart`) e um barrel público
(`functions.dart`). `AppClientMetadataProvider`/`PackageInfoClientMetadataProvider` isolam
`PackageInfo.fromPlatform()` (método estático, não mockável diretamente) atrás de uma interface
mockável, mesmo padrão de `ImageCompressor` (TASK-014). `CloudFunctionsService` tem duas
construtoras: a padrão (só as 3 dependências reais, a que o `injectable` gera provider para) e
`CloudFunctionsService.withDependencies` (`@visibleForTesting`, aceita `Uuid`/callback de métricas
customizados) — ver "Decisões técnicas".

## Regras de negócio implementadas

- Nenhuma regra de negócio de produto (task de infraestrutura). `healthCheck` não tem lógica de
  negócio nenhuma, de propósito — existe só para validar o pipeline.
- Toda chamada a Cloud Functions no app passa por `CloudFunctionsService.call<T>()` — nenhuma
  feature futura pode chamar `cloud_functions` diretamente (mesma regra de fronteira já aplicada a
  `firebase_storage`/`cloud_firestore` nas TASK-013/014).
- `requireAuth` é um guard client-side, fail-fast, para chamadas que só fazem sentido autenticado —
  documentado explicitamente como não substituindo a validação server-side real (`AGENTS.md`:
  nunca confiar só no client para autorização).
- Retry automático (`CloudFunctionsService`) é restrito aos códigos de erro transitórios definidos
  em `transientCloudFunctionsErrorCodes` (`unavailable`, `deadline-exceeded`, `internal`, `aborted`,
  `cancelled`) — nunca em código de validação/permissão. Documentado como depender de toda função
  real ser idempotente (`AGENTS.md`), já que o wrapper pode reenviar a mesma chamada.

## Regras Firebase implementadas

- `configureFunctions` conecta `FirebaseFunctions` ao Functions Emulator (`useFunctionsEmulator`,
  host/porta de `lib/core/environment/`) para todo flavor que não seja `prod` — mesmo padrão
  ADR-0002 já usado por Auth/Firestore/Storage. `FirebaseFunctions` é `@lazySingleton`: só conecta
  quando algo de fato resolve essa dependência via DI.
- `firebase.json`: bloco `functions[0].predeploy` roda `npm run lint` e `npm run build` antes de
  qualquer `firebase deploy --only functions` — nunca deploya `src/` sem passar por eles.
- `.firebaserc` fixa o alias `default` → `vestipro` (ADR-0002: um único projeto Firebase real).
  `functions/README.md` documenta que `development`/`staging` nunca deployam (só Emulator Suite);
  só `production` deploya, sempre contra `vestipro`.
- `healthCheck` não lê/escreve nenhum dado do Firestore/Storage — não há regra de segurança nova
  para validar aqui (a próxima função real por domínio trará suas próprias regras de autorização
  server-side, conforme `AGENTS.md`).

## Analytics implementado

Nenhum (fora do escopo desta task; TASK-017).

## Crashlytics implementado

Nenhum (TASK-016). Erros de Cloud Functions são mapeados para `AppException`/`Failure`s tipadas em
vez de vazar `FirebaseFunctionsException` ou crashar.

## Impacto offline

Nenhuma mudança de comportamento offline existente. `CloudFunctionsService` não tem cache/outbox
próprio — chamadas de função sempre exigem rede (mesmo comportamento que qualquer callable sempre
teve); a integração com Outbox/sync fica para quando uma feature real de domínio (pedido, preço)
precisar chamar uma função a partir de uma mutação offline.

## Impacto multi-tenant

Nenhum ainda: `healthCheck` não lê `organizationId`. O comentário em
`functions/src/health/health-check.ts` documenta explicitamente que toda função de domínio futura
(`auth`, `pricing`, `orders`, `insights`, `admin`) deve validar o vínculo real do usuário autenticado
com a organização no servidor antes de qualquer operação — reforçando a regra já presente em
`AGENTS.md`, para a próxima task que popular essas pastas não esquecer.

## Testes criados

- `functions/test/health-check.test.ts` (Jest): resposta `status: 'ok'` com timestamp válido,
  correlation id ecoado quando enviado sob `_meta`, correlation id gerado quando o caller não envia
  nenhum, `authenticated` refletindo `request.auth`.
- `functions/test/callable-meta.test.ts` (Jest): `resolveCorrelationId` devolve o id do caller,
  gera um novo quando `meta` é `undefined`, e gera um novo quando o caller manda só espaços.
- `test/core/functions/cloud_functions_exception_mapper_test.dart`: cada código relevante do
  protocolo callable (`unauthenticated`, `permission-denied`, `not-found`, `already-exists`,
  `aborted`, `failed-precondition`, `unavailable`, `deadline-exceeded`, `cancelled`,
  `resource-exhausted`, `invalid-argument`, `out-of-range`, `internal`, `unimplemented`,
  `data-loss`, código desconhecido) mapeia para o `AppException` esperado e converte para uma
  `Failure` via `mapAppExceptionToFailure`; mais um teste dedicado garantindo que
  `transientCloudFunctionsErrorCodes` contém exatamente o conjunto esperado e nunca inclui um código
  de validação/permissão.
- `test/core/functions/cloud_functions_service_test.dart` (mocktail): payload enviado inclui os
  dados do caller e `_meta` (correlation id fixo via `Uuid` mockado + metadata do
  `AppClientMetadataProvider` mockado); `requireAuth` lança `UnauthorizedException` sem nunca chamar
  `httpsCallable` quando não há usuário logado, e deixa passar quando há; `timeout` é encaminhado
  como `HttpsCallableOptions`; retry acontece até `maxAttempts` só para um código transitório
  (`unavailable`) simulado via uma subclasse de teste de `FirebaseFunctionsException` (ver "Decisões
  técnicas"), e nunca para `invalid-argument`/`permission-denied` (falha já na primeira tentativa).
- `integration_test/core/functions/cloud_functions_service_integration_test.dart`: teste real de
  integração contra o Functions Emulator — `healthCheck` retornando `ok` e ecoando o correlation id
  gerado pelo wrapper; uma função inexistente mapeando para `NotFoundException` de ponta a ponta;
  um timeout client-side de 1ms mapeando para `NetworkException` de ponta a ponta (depois do wrapper
  tentar `maxAttempts` vezes, por ser `deadline-exceeded`, um código transitório). Ver "Evidências"
  e "Riscos conhecidos" sobre execução real desta suíte nesta sessão.

## Comandos executados

```bash
# functions/ (Node/TypeScript)
npm install
npm run build
npm run lint
npm test

# raiz (Flutter)
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --target lib/main_dev.dart --output build/web-dev-check

# validação real de ponta a ponta contra o Functions Emulator
firebase emulators:start --only functions --project vestipro
curl -X POST http://127.0.0.1:5001/vestipro/us-central1/healthCheck -H "Content-Type: application/json" -d '{"data": {"_meta": {"correlationId": "curl-test-123"}}}'
curl -i -X POST http://127.0.0.1:5001/vestipro/us-central1/doesNotExist -H "Content-Type: application/json" -d '{"data": {}}'
flutter test integration_test/core/functions/cloud_functions_service_integration_test.dart -d chrome
flutter test integration_test/core/functions/cloud_functions_service_integration_test.dart -d windows
```

## Resultado do formatter

`Formatted 125 files (0 changed)` na execução final (o único arquivo que precisou de ajuste,
`cloud_functions_service.dart`, já tinha sido corrigido em uma passada anterior).

## Resultado do analyzer

`No issues found!`.

## Resultado dos testes

- `functions/`: `npm test` → 2 suítes, 7 testes, todos passaram.
- Flutter: `flutter test` → **135 testes, todos passaram** (109 pré-existentes + 26 novos desta
  task: mapper de exceções de Cloud Functions e `CloudFunctionsService`).
- `flutter build web --target lib/main_dev.dart` → `Built build\web-dev-check` (removido após a
  validação, é apenas saída de build gitignorada) — evidência de que o novo código compila no
  target Web.

## Decisões técnicas

- **Envelope `_meta` em vez de campos soltos no payload.** A task pedia correlation id e
  versão/plataforma "como metadata". Em vez de misturar esses campos com os dados de negócio de
  cada função (risco real de colisão de nome — ex.: uma função de pricing que um dia precise de um
  campo `platform` próprio), todo metadata do wrapper vai sob a chave reservada `_meta`
  (`{ ...data, _meta: { correlationId, appVersion, buildNumber, platform } }`), com um contrato
  espelhado dos dois lados: `AppClientMetadata`/`CloudFunctionsService` no Flutter e
  `CallableMeta`/`resolveCorrelationId` em `functions/src/shared/callable-meta.ts`. Isso também
  evita que cada função de domínio futura precise reimplementar sua própria extração de
  correlation id.
- **`CloudFunctionsService` com duas construtoras** (padrão + `.withDependencies`,
  `@visibleForTesting`). O `injectable` tenta resolver via DI **todo** parâmetro do construtor
  usado para gerar o provider, inclusive named/opcionais — tentar expor `Uuid`/um callback de
  métricas como parâmetros opcionais do construtor principal fazia o `build_runner` falhar com
  "depends on unregistered type" para `Uuid` e para o `typedef` de callback (que não faz sentido
  registrar no container). A construtora nomeada evita isso sem exigir um `Uuid` "de verdade"
  registrado no `injection_module.dart` só para satisfazer o gerador, e sem forçar um valor real de
  métricas antes de existir qualquer consumidor real (TASK-019).
- **Medição de tempo de resposta via `CloudFunctionCallMetricsRecorder` opcional, no-op por
  padrão.** A task pede "medição de tempo de resposta (preparando integração futura com Performance
  Monitoring na TASK-019)" — sem um `PerformanceMonitor` ainda existente no `core/` para conectar de
  verdade, a escolha foi medir sempre com `Stopwatch` e expor o resultado por um único callback
  parametrizável (nome da função, duração, sucesso, tentativa), sem inventar nenhuma abstração maior
  de observabilidade. A TASK-019 só precisa passar um `onCallMetrics` real pela construtora de teste
  (ou promovê-la a construtora nomeada estável) — nenhuma mudança na lógica de `call<T>()`.
- **Simular erro de Cloud Functions em teste unitário via subclasse de
  `FirebaseFunctionsException`.** O construtor real é `@protected` (só acessível por subclasses),
  então os testes definem `_FakeFirebaseFunctionsException extends FirebaseFunctionsException` e
  chamam `super(...)` — uso legítimo de membro protegido (por isso não aparece no `flutter analyze`)
  que evita precisar de um emulador real só para testar a lógica de retry/mapeamento de erro no
  nível de unidade.
- **`healthCheck` não precisou de uma função "de teste" adicional para simular timeout/erro.** Os
  dois cenários pedidos pela task ("erro simulado (timeout, função inexistente)") saem de
  `healthCheck` sozinha: um nome de função inexistente já produz um 404 real do emulador, que o SDK
  do `cloud_functions` mapeia para `functions/not-found` (confirmado empiricamente com o SDK JS
  contra o emulador real desta sessão — ver "Evidências"); e um `timeout` client-side
  absurdamente curto (`HttpsCallableOptions.timeout`) produz um `functions/deadline-exceeded` real,
  mesmo contra uma função tão rápida quanto `healthCheck` (também confirmado empiricamente). Isso
  evita ter que decidir se uma Cloud Function só para gerar erros de teste valeria a pena ser
  deployada para produção — pela ADR-0002 (projeto único), qualquer função em `functions/src`
  deploya para o `vestipro` real, sem projeto de staging para isolar esse tipo de função utilitária.
- **`firebase-admin` incluído como dependência e `initializeApp()` chamado em `src/index.ts`**
  mesmo sem nenhuma função ainda usando Firestore/Auth Admin — é o boilerplate padrão que toda
  função real de domínio (RBAC, pricing, número de pedido) vai precisar para ler/validar dados
  server-side; inicializar uma vez no entrypoint evita que a primeira task de domínio precise
  lembrar de fazer isso.
- **Região da Cloud Function não definida explicitamente** (`onCall` sem `region` nas opções) —
  fica no default do SDK (`us-central1`) dos dois lados (server via `firebase-functions/v2/https`,
  client via `FirebaseFunctions.instance`), evitando qualquer risco de descompasso de região entre
  deploy e chamada. Uma decisão futura de região mais próxima do Brasil (ex.: `southamerica-east1`)
  não foi tomada nesta task por falta de um requisito real de latência documentado — quando isso
  for decidido, deve virar uma ADR (mesmo padrão da ADR-0002), não uma escolha implícita aqui.

## Riscos conhecidos

- **`integration_test/core/functions/cloud_functions_service_integration_test.dart` não pôde ser
  executado de ponta a ponta nesta sessão, pela mesma limitação de ambiente já documentada nas
  TASK-012/013/014**: `flutter test ... -d chrome` falha com "Web devices are not supported for
  integration tests yet." (limitação do pacote `integration_test`, não do código) e
  `flutter test ... -d windows` falha com "No Windows desktop project configured" (o projeto nunca
  adicionou suporte a desktop Windows). Diferente das tasks anteriores, porém, **o Functions
  Emulator não precisa de JRE** — foi de fato iniciado nesta sessão
  (`firebase emulators:start --only functions --project vestipro`) e o pipeline completo foi
  validado com chamadas HTTP reais e com o SDK JS oficial do `cloud_functions` (não simulado):
  `healthCheck` respondeu `{"result":{"status":"ok",...,"correlationId":"curl-test-123",...}}`
  ecoando o correlation id enviado sob `_meta`; sem correlation id, gerou um novo; uma função
  inexistente respondeu `404` e, testado com o SDK JS oficial contra o mesmo emulador, mapeou para
  `functions/not-found`; um timeout client-side de 1ms mapeou para `functions/deadline-exceeded`.
  Essas são exatamente as regras que `mapCloudFunctionsExceptionToAppException` e
  `CloudFunctionsService` implementam — a pendência real é só não ter executado esse fluxo *através*
  do `flutter test integration_test/...`, e sim através de chamadas HTTP/SDK JS diretas ao mesmo
  emulador.
- Nenhuma feature de domínio usa `CloudFunctionsService` ainda — a primeira validação de uso real
  (e a primeira função com regra de negócio de fato) acontece a partir da task que popular
  `src/auth`, `src/pricing`, `src/orders`, `src/insights` ou `src/admin`.
- `functions/package-lock.json` foi gerado nesta máquina (Node v24.18.0, acima do `engines.node: 20`
  declarado — esperado, é a versão de runtime do Cloud Functions, não da máquina de
  desenvolvimento) — `npm install` emitiu um aviso `EBADENGINE` esperado, sem impacto no
  build/lint/test.

## Pendências

- Validar `integration_test/core/functions/cloud_functions_service_integration_test.dart` de ponta
  a ponta via `flutter test ... -d chrome` em um ambiente com `chromedriver` instalado, ou em CI com
  um dispositivo Android/iOS real (mesma pendência já registrada nas TASK-012/013/014).
- Cada task que popular `src/auth`, `src/pricing`, `src/orders`, `src/insights` ou `src/admin` deve
  implementar a validação real de vínculo usuário-organização no servidor antes de qualquer
  operação — documentado no comentário de `healthCheck` e nesta conclusão, mas ainda não tem código
  nenhum de verdade além do placeholder de cada pasta.
- Decidir a região das Cloud Functions via ADR quando houver um requisito real de latência (ver
  "Decisões técnicas").
- Push depende de autorização explícita do usuário.

## Evidências

- `functions/`: `npm run build` (sem erro), `npm run lint` (sem erro), `npm test` → `Test Suites: 2
  passed, 2 total. Tests: 7 passed, 7 total.`
- `flutter analyze` → `No issues found!`.
- `flutter test` → `All tests passed!` (135 testes).
- `flutter build web --target lib/main_dev.dart` → `Built build\web-dev-check`.
- `firebase emulators:start --only functions --project vestipro` → emulador real iniciado nesta
  sessão, escutando em `127.0.0.1:5001`.
- `curl -X POST http://127.0.0.1:5001/vestipro/us-central1/healthCheck -d '{"data":
  {"_meta":{"correlationId":"curl-test-123"}}}'` →
  `{"result":{"status":"ok","serverTimestamp":"2026-08-21T23:17:44.031Z","correlationId":"curl-test-123","authenticated":false}}`
  (real, contra o emulador rodando nesta sessão).
- `curl -i -X POST http://127.0.0.1:5001/vestipro/us-central1/doesNotExist -d '{"data":{}}'` →
  `HTTP/1.1 404 Not Found` (real).
- SDK JS oficial (`firebase/functions`) contra o mesmo emulador, chamando `doesNotExist`: `code:
  functions/not-found`; chamando `healthCheck` com `timeout: 1`: `code:
  functions/deadline-exceeded` — ambos reais, não simulados, confirmando o comportamento que
  `mapCloudFunctionsExceptionToAppException` mapeia para `NotFoundException`/`NetworkException`.
- `flutter test integration_test/core/functions/... -d chrome` → `Web devices are not supported for
  integration tests yet.` (real, evidência da limitação de ambiente, não simulada).
- `flutter test integration_test/core/functions/... -d windows` → `No Windows desktop project
  configured.` (real, evidência da limitação de ambiente, não simulada).

## Commit

Realizado.

## Push

Não executado nesta task; depende de autorização explícita do usuário.

## Hash do commit

Preenchido após o commit desta sessão.

## Branch

`main`

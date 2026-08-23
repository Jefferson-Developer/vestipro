# TASK-037 — Concluída (2026-08-23)

## Resumo

Implementada a criação da primeira Organization como operação transacional e idempotente
executada exclusivamente por uma Cloud Function callable (`createOrganization`,
`functions/src/organizations/create-organization.ts`), substituindo o fluxo 100% client-side que
existia desde a TASK-026/TASK-030 (`CreateOrganizationUseCase` → `EnsureSystemRolesUseCase` →
`AssignRoleToUserUseCase` escrevendo direto no Firestore, através de 3 "janelas de bootstrap"
deliberadas nas Security Rules). A Function cria a Organization, semeia os 7 system roles fixos,
concede a Membership `OWNER` ao usuário autenticado e grava uma entrada de auditoria
(`organization.created`) em uma única transação Firestore com o Admin SDK — que ignora as Security
Rules por definição. As 3 janelas de bootstrap foram removidas de `firestore.rules`: nenhuma dessas
escritas é mais permitida a partir do cliente, nem mesmo para quem seria o criador legítimo.
`OrganizationRepository.create`/`CreateOrganizationUseCase` (já existentes desde a TASK-026) foram
mantidos com a mesma assinatura pública, mas `FirestoreOrganizationDataSource.create` passou a
chamar a Function via `CloudFunctionsService` em vez de escrever no Firestore diretamente.

## Agentes utilizados

- `flutter-senior-architect` (único exigido pela task).

## Arquivos criados

- `functions/src/organizations/create-organization.ts` — Cloud Function callable
  `createOrganization`.
- `functions/test/create-organization.test.ts` — 7 testes contra o Firestore Emulator real
  (`firebase-functions-test` + Admin SDK).
- `docs/tasks/TASK-037-implementar-criacao-da-primeira-organizacao-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `functions/src/index.ts` — exporta `createOrganization`.
- `firestore.rules` — removidas as 3 janelas de bootstrap (`organizations` create, seed dos 7
  system roles, self-grant da Membership OWNER) e a função `isOrganizationCreator` (agora não
  usada); `organizations.get` simplificado para `isActiveMember` (o `resource == null`/`createdBy`
  não são mais necessários, já que a Membership nasce atomicamente com a Organization); nova
  coleção `organizationOwners/{userId}` com `read, write: if false` explícito (marcador de
  idempotência usado apenas pela Function via Admin SDK).
- `firestore-tests/firestore.rules.test.js` — os 6 testes de bootstrap (3 positivos, 3 negativos)
  foram substituídos por 7 testes negativos comprovando que nenhuma das 3 escritas é mais permitida
  pelo cliente (nem pelo criador legítimo), mais 2 testes novos para `organizationOwners` e 1 teste
  extra validando que `role.manage` continua não permitindo `isSystemRole: true` pelo caminho
  normal.
- `lib/features/organizations/data/datasources/firestore_organization_data_source.dart` —
  `create` deixou de escrever via `runTransaction` no Firestore e passou a chamar
  `CloudFunctionsService.call('createOrganization', ...)`, com `requireAuth: true`; novo método
  privado que interpreta a resposta JSON da Function (datas como strings ISO-8601, não
  `Timestamp`) em um `OrganizationDto`. `getById`/`updateSettings` permanecem inalterados (Firestore
  direto).
- `lib/features/organizations/domain/repositories/organization_repository.dart` — docstring de
  `create` atualizada para descrever a nova idempotência (baseada em "quem já criou uma
  Organization", não apenas no `id` reenviado).
- `lib/features/organizations/domain/usecases/create_organization_use_case.dart` — docstring
  atualizada na mesma linha.
- `lib/features/organizations/domain/usecases/ensure_system_roles_use_case.dart` — docstring
  atualizada explicando que o caso de uso foi superado, para o fluxo de onboarding, pela Cloud
  Function (permanece como peça testada para um eventual uso administrativo futuro fora do
  onboarding, mas sem chamador real hoje).
- `lib/features/audit_log/domain/value_objects/audit_action.dart` — novo valor
  `AuditAction.organizationCreated` (`organization.created`), o único do catálogo nunca escrito por
  código Dart (é gravado server-side pela Function) — necessário para que
  `AuditLogEntryMapper`/`ListAuditLogEntriesUseCase` consigam interpretar essas entradas.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) para injetar
  `CloudFunctionsService` em `FirestoreOrganizationDataSource`.
- `test/features/organizations/data/datasources/firestore_organization_data_source_test.dart` —
  grupo `create` reescrito: em vez de mockar `Transaction`/`DocumentReference`, mocka
  `FirebaseFunctions`/`HttpsCallable`/`FirebaseAuth`/`AppClientMetadataProvider` e usa
  `CloudFunctionsService.withDependencies(...)` real (o mesmo padrão de
  `test/core/functions/cloud_functions_service_test.dart`), já que `CloudFunctionsService` é
  `final class` e não pode ser mockada via `implements` fora de sua própria library.
- `docs/tasks/TASKS.md` — checkbox da TASK-037 marcado e `Progresso` atualizado para `37 / 220`.

Nenhum outro arquivo foi alterado. `lib/main.dart` tem uma modificação não relacionada a esta task
(troca de entrypoint `main_dev.dart`/`main_prod.dart`, deixada por uma sessão anterior) que foi
deliberadamente ignorada — não lida, não revertida, não incluída em nenhum commit desta task.

## Arquitetura utilizada

- Clean Architecture feature-first preservada: nenhuma camada nova precisou ser criada porque
  `Organization`/`OrganizationRepository`/`CreateOrganizationUseCase` já existiam (TASK-026) — a
  mudança ficou inteiramente contida na implementação de `data/datasources`
  (`FirestoreOrganizationDataSource`), que é exatamente o ponto de que Clean Architecture existe
  para isolar: o domain nunca soube (e continua não sabendo) que a criação passou a acontecer via
  Cloud Function.
- `FirestoreOrganizationDataSource.create` nunca escreve `Map<String, dynamic>` do Firestore fora
  de `data/`, nem decodifica a resposta da Function fora de `data/`: o parsing JSON→DTO acontece
  inteiramente dentro do próprio datasource, em um método privado dedicado.
- `functions/src/organizations/create-organization.ts` segue o mesmo padrão de
  `functions/src/health/health-check.ts` (TASK-015): `onCall`, `resolveCorrelationId`,
  `logger.info` estruturado — nenhum padrão novo de Cloud Function foi introduzido.
- Toda regra de negócio sensível (quem se torna OWNER, quais roles existem, idempotência) permanece
  no backend (Cloud Function + Firestore Rules), nunca no client — client apenas invoca a Function
  e interpreta a resposta.

## Regras de negócio implementadas

- `createOrganization` roda inteiramente dentro de uma única transação Firestore
  (`db.runTransaction`): cria `organizations/{organizationId}`, os 7 documentos de
  `.../roles/{ROLE_CODE}` (`isSystemRole: true`), a Membership `OWNER` em
  `.../members/{uid}` (`status: 'active'`, `version: 1`), o marcador
  `organizationOwners/{uid}` e a entrada de auditoria `organization.created` em
  `.../auditLogs/{id}` — ou tudo é escrito, ou nada é (rollback automático do Firestore ao lançar
  qualquer exceção antes do fim da transação).
- Idempotência não depende do cliente reenviar o mesmo `organizationId`: a primeira leitura da
  transação é sempre `organizationOwners/{uid}` — se já existir, a Organization apontada por ele é
  devolvida sem nenhuma escrita nova, mesmo que o payload da retentativa carregue um
  `organizationId` diferente (cenário de app reiniciado/perda de estado local). Testado
  explicitamente (`is idempotent... even when the retry carries a different organizationId`).
- `uid` usado como criador/OWNER é sempre `request.auth.uid` (nunca um campo do payload) —
  `createdBy`, `userId` da Membership e `actorUserId` da auditoria vêm todos dele.
- Chamada não autenticada é rejeitada com `unauthenticated` antes de qualquer leitura/escrita.
- Payload com qualquer campo obrigatório em branco é rejeitado com `invalid-argument` antes de
  abrir a transação.
- Nenhum estado parcial é possível: um guard defensivo (leitura de todos os 7 documentos de role
  antes de qualquer escrita) lança `internal` se algum já existir de forma inesperada — testado
  simulando exatamente esse cenário e comprovando que nada (Organization, Membership, marcador de
  owner) fica persistido após a falha.
- Auditoria: `actorName` da entrada `organization.created` vem, em ordem de preferência, do campo
  `name` de `users/{uid}` (perfil criado no cadastro, TASK-035), do `name` do token de autenticação,
  do e-mail do token, ou `'unknown'` — nunca fica vazio.

## Regras Firebase implementadas

- `firestore.rules`: as 3 janelas de bootstrap client-side (criar `organizations` direto, semear os
  7 system roles antes de ter Membership, autoconceder a Membership OWNER) foram **removidas**;
  `organizations.create` agora é `if false` (só a Function, via Admin SDK, cria); `roles.create` e
  `members.create` só aceitam o caminho normal (role custom com `role.manage`; convite com
  `user.invite`), nunca mais `isSystemRole: true` nem a primeira Membership OWNER pelo cliente.
  `organizations.get` simplificado para `isActiveMember(organizationId)` (o campo `createdBy` não
  precisa mais autorizar leitura, já que a Membership nasce atomicamente com a Organization).
- Nova coleção `organizationOwners/{userId}`: `read, write: if false` explícito — só a Function
  (Admin SDK, que ignora Rules) grava/lê; documentado como decisão deliberada (explícito em vez de
  confiar no deny-by-default implícito).
- `firestore-tests/firestore.rules.test.js`: 51 testes no total (era 42 antes desta task) —
  removidos os 6 testes de bootstrap (3 positivos que não fazem mais sentido, 3 negativos
  redundantes com o novo comportamento), adicionados 7 negativos novos (organizations/roles/members
  não criáveis pelo cliente mesmo pelo criador legítimo, `organizationOwners` sempre negado) e 1
  positivo/negativo extra validando `role.manage` vs. `isSystemRole: true`.

## Analytics implementado

Nenhum evento novo nesta task — não há tela/BLoC de onboarding ainda (isso é escopo da TASK-038,
wizard de configuração inicial); a Cloud Function registra apenas `logger.info` estruturado
(`correlationId`, `uid`, `organizationId`, `alreadyExisted`), sem nenhum dado sensível.

## Crashlytics implementado

Nenhuma mudança de captura de erro no client: `FirestoreOrganizationDataSource.create` propaga
`AppException`/`Failure` como qualquer outro caminho de erro já tratado pelo `CrashReporter`
central (TASK-016) — nenhum `print`, nenhuma supressão silenciosa.

## Impacto offline

Nenhuma regressão: a criação da Organization já era uma escrita online-only (Firestore direto)
antes desta task; agora é uma chamada de Cloud Function online-only — em ambos os casos, sem rede a
operação falha e o chamador recebe uma `Failure` tipada. Persistência local/Outbox para este fluxo
específico continua fora de escopo (mesma pendência já registrada pela TASK-026), já que criar a
primeira Organization inerentemente exige um servidor confiável (não é uma mutação de negócio
comum que se beneficie de fila offline).

## Impacto multi-tenant

Reforça o isolamento multi-tenant na origem: antes desta task, a criação do tenant raiz dependia de
3 janelas de Security Rules abertas (ainda que estreitas) para o client bootstrapar a si mesmo.
Agora essas janelas não existem mais — o único caminho que cria `organizations`, seus 7 system
roles e a primeira Membership é uma Cloud Function server-side, que nunca confia em nenhum campo do
payload do cliente para decidir `createdBy`/`userId`/`actorUserId` (sempre `request.auth.uid`).
Testado no Firestore Emulator (Rules) e diretamente contra a Function (Admin SDK) que nem o próprio
criador legítimo consegue mais escrever essas 3 coisas via client.

## Testes criados

- `functions/test/create-organization.test.ts` (7 testes, Firestore Emulator real via Admin SDK +
  `firebase-functions-test`): criação completa (Organization + 7 roles + Membership OWNER + audit
  log), idempotência (retry do mesmo uid com `organizationId` diferente retorna a Organization
  original, sem duplicar), rollback completo em falha simulada no meio da transação (nada persiste,
  nem mesmo o marcador de owner), rejeição de chamada não autenticada sem escrever nada, rejeição
  de payload com campo em branco, `actorName` da auditoria a partir do perfil `users/{uid}` e, na
  ausência dele, a partir do token de autenticação.
- `test/features/organizations/data/datasources/firestore_organization_data_source_test.dart`
  (grupo `create` reescrito): chamada da callable com os campos corretos do DTO e parsing da
  resposta; comportamento idempotente do ponto de vista do datasource
  (`alreadyExisted: true` ainda retorna um `OrganizationDto` válido); `UnauthorizedException` sem
  chamar a Function quando não há usuário logado; propagação da `AppException` já mapeada pelo
  `CloudFunctionsService` a partir de um código de erro do Cloud Functions; `ServerException` para
  respostas com formato inesperado (campo `organization` ausente ou com tipo errado).
- `firestore-tests/firestore.rules.test.js`: 7 testes novos/reescritos comprovando que as 3
  janelas de bootstrap foram removidas de fato (negado mesmo para o criador legítimo), 2 testes
  para `organizationOwners` (nunca lido/escrito pelo cliente) e 1 teste extra para `role.manage`
  vs. `isSystemRole: true`.

## Comandos executados

```bash
cd functions && npm run build
cd functions && npm run lint
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix functions test -- create-organization"
firebase emulators:exec --only firestore "npm --prefix functions test"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → `Formatted 460 files (1 changed) in 2.01 seconds.` (o único
arquivo alterado nesta passada foi o teste do datasource, recém-reescrito).

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 10.9s)`.

## Resultado dos testes

- `npm run build` (functions/TypeScript): sem erros.
- `npm run lint` (functions/ESLint): sem erros/avisos.
- `firebase emulators:exec --only firestore "npm --prefix functions test"`: `Test Suites: 3 passed,
  3 total` / `Tests: 14 passed, 14 total` (inclui os 7 testes novos de `create-organization.test.ts`
  mais os 7 já existentes de `health-check`/`callable-meta`).
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`: `Tests: 51 passed,
  51 total` (era 42 antes desta task).
- `flutter test` (suíte completa): `+795: All tests passed!` (exit code 0).

## Decisões técnicas

- **Idempotência via marcador `organizationOwners/{uid}`, não apenas via `organizationId`
  reenviado**: a task pede para "verificar no início da Function se o usuário autenticado já possui
  uma Organization como criador antes de prosseguir" — implementei isso como a primeira leitura da
  transação, desacoplado do `organizationId` do payload. Isso é estritamente mais forte do que
  confiar só na estabilidade do `id` entre retentativas (o que o contrato de
  `OrganizationRepository.create` já pedia desde a TASK-026): mesmo que o cliente perca o `id`
  gerado localmente entre tentativas (ex.: app reinstalado, estado local perdido), o backend ainda
  garante uma única Organization por criador.
- **`organizationId` continua vindo do cliente, não gerado pela Function**: mantém
  `OrganizationRepository.create(id: ...)` sem quebrar sua assinatura/contrato já estabelecido pela
  TASK-026 (evita duplicar/redesenhar `CreateOrganizationUseCase`), e é seguro porque a real
  garantia de unicidade está no marcador de owner, não no id em si (ver decisão acima) — um id
  colidindo com uma Organization de outro dono já é tratado como `already-exists`.
- **`FirestoreOrganizationDataSource` mantido (não dividido em duas classes)**: embora `create` não
  use mais `cloud_firestore` diretamente, dividir a classe em "datasource Firestore" +
  "datasource Cloud Function" separados exigiria duplicar a implementação de `OrganizationDataSource`
  e mudar a composição em `OrganizationRepositoryImpl` sem nenhum ganho arquitetural real (a
  interface já é só três métodos coesos sobre o mesmo agregado). Preferi manter a classe única, com
  docstring explicando claramente por que `create` é a exceção.
- **Resposta da Function parseada sem reusar `OrganizationDto.fromJson`**: esse factory exige
  `Timestamp` do `cloud_firestore` (formato de uma leitura direta do Firestore); a resposta de uma
  Cloud Function callable é JSON puro, com datas como string ISO-8601. Construir o `OrganizationDto`
  diretamente pelo construtor (que já aceita `DateTime`) evitou introduzir uma segunda variante de
  `fromJson` ou enfraquecer a validação existente do parsing "real" do Firestore.
- **Teste do datasource usa `CloudFunctionsService.withDependencies(...)` real, não um mock da
  classe**: `CloudFunctionsService` é `final class` (Dart 3 modifiers), portanto não pode ser mockada
  via `extends Mock implements` fora de sua própria library — segui exatamente o padrão já usado em
  `test/core/functions/cloud_functions_service_test.dart` (mockar `FirebaseFunctions`/`FirebaseAuth`/
  `AppClientMetadataProvider` e instanciar o serviço real com esse seam de teste).
- **`EnsureSystemRolesUseCase` mantido, não removido**: mesmo sem chamador real após esta task (a
  seeding real agora é server-side), removê-lo quebraria "não remover comportamento existente sem
  justificativa" sem necessidade — é uma peça testada e potencialmente reutilizável por uma
  ferramenta administrativa futura fora do onboarding. Docstring atualizada para deixar claro que
  não é mais parte do caminho real de onboarding.
- **"Atualizar o estado local (organização ativa)" deliberadamente não implementado como
  sessão/guard nesta task**: o arquivo da task pede isso como consequência do sucesso da criação
  ("para permitir a navegação para o wizard"), não como um item de escopo técnico próprio com
  critério de aceite dedicado. Como `CreateOrganizationUseCase` já devolve a `Organization` criada
  por completo, o consumidor natural desse resultado é a tela/BLoC de onboarding — que é
  literalmente o escopo da TASK-038 ("wizard de configuração inicial"), a próxima task do backlog,
  e que hoje não existe ainda (não há tela alguma consumindo `CreateOrganizationUseCase`). Construir
  uma sessão/guard real de "organização ativa" agora, sem nenhuma tela/rota real para proteger,
  repetiria exatamente o risco que a TASK-026 já registrou e evitou deliberadamente ("religar um
  guard real sem o fluxo de sessão/organização ativa que o alimenta criaria uma dependência
  quebrada"). Ver "Pendências" abaixo.

## Riscos conhecidos

- `ActiveOrganizationGuard` continua sendo `AlwaysAllowActiveOrganizationGuard` — o comentário em
  `lib/core/navigation/active_organization_guard.dart` previa que TASK-026+TASK-037 juntas trariam
  o guard real, mas nenhuma das duas tasks tinha, em seu próprio arquivo de escopo/critérios de
  aceite, esse item como requisito explícito, e não há ainda nenhuma rota `:orgId` real no
  `AppRouter` para proteger (isso só chega em TASK-042 em diante, conforme já registrado na
  TASK-029). Substituir o guard fica para quando a tela/rota que efetivamente precisa dele existir
  — provavelmente TASK-038 ou TASK-042, dependendo de qual delas introduzir a primeira rota real
  com organização ativa em escopo.
- `EnsureSystemRolesUseCase`/`AssignRoleToUserUseCase` (para o caso específico de auto-concessão de
  OWNER) não têm mais nenhum caminho de Rules que os deixe funcionar para o cenário de onboarding —
  qualquer chamada futura acidental a partir de uma tela cairia em `permission-denied`. Isso é
  intencional (documentado no próprio código), mas vale registrar para quem for construir a TASK-038
  não tentar reusar esse caminho para a criação da Organization em si.
- A resposta de `createOrganization` é validada defensivamente no client (`ServerException` em
  formato inesperado), mas não há teste de contrato automatizado comparando o schema TypeScript
  (`CreateOrganizationResponse`) com o parsing Dart (`_organizationDtoFromCallableResponse`) — os
  dois precisam ser mantidos em sincronia manualmente, mesmo risco já aceito para
  `roleHasCapability`/`RolePermissionMatrix` (TASK-030).

## Pendências

- Consumir `CreateOrganizationUseCase` de uma tela/BLoC de onboarding real, incluindo a atualização
  do estado local de "organização ativa" e a navegação para o wizard — escopo da TASK-038.
- Substituir `AlwaysAllowActiveOrganizationGuard` por um guard real assim que existir uma rota
  `:orgId` de fato no `AppRouter` para proteger.
- Nenhuma pendência bloqueia a conclusão desta task: os 4 critérios de aceite (criação exclusiva
  via Function, criador sempre OWNER, idempotência comprovada por teste, nenhum estado inconsistente
  sob falha parcial) estão implementados e testados.

## Evidências

- `functions/src/organizations/create-organization.ts` e `functions/test/create-organization.test.ts`.
- `firestore.rules` (blocos `organizations`, `roles`, `members`, `organizationOwners`) e
  `firestore-tests/firestore.rules.test.js`.
- `lib/features/organizations/data/datasources/firestore_organization_data_source.dart` e seu teste.
- Saída de `firebase emulators:exec --only firestore "npm --prefix functions test"`
  (`Tests: 14 passed, 14 total`), de `firebase emulators:exec --only firestore "npm --prefix
  firestore-tests test"` (`Tests: 51 passed, 51 total`) e de `flutter test`
  (`+795: All tests passed!`), reproduzidas nas seções "Resultado dos testes" acima.

## Commit

Criado com sucesso (`lib/main.dart`, alteração pré-existente não relacionada a esta task, foi
deliberadamente deixado de fora do commit).

## Push

Autorizado nesta rodada; executado com sucesso após o commit.

## Hash do commit

`59b04b2`

## Branch

`main`

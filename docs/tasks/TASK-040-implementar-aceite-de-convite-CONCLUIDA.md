# TASK-040 — Concluída (2026-08-23)

## Resumo

Implementado o fluxo completo de aceite de convite (TASK-040, EPIC-04), consumindo o token gerado
pela TASK-039: rota tipada `/invite/:token` (`InviteAcceptanceRoute`) que abre `AcceptInvitePage`,
a qual valida o token contra a nova Cloud Function `validateInvite` **antes** de mostrar qualquer
opção ao usuário, e então — dependendo de haver ou não uma sessão ativa compatível — deixa criar
uma conta nova (reaproveitando o `SignUpForm` da TASK-035, com o e-mail travado no do convite) ou
apenas confirmar o vínculo de uma conta já autenticada. A aceitação em si é feita pela nova Cloud
Function callable `acceptInvite`, transacional: cria/atualiza o Membership do chamador com a role
exata do convite e marca o `Invite` como `accepted`, tudo em uma única transação Firestore junto
com a entrada de auditoria.

Convite expirado (detectado de forma lazy por `expiresAt`, já que nenhum código deste projeto
jamais escreve `status: 'expired'`), já aceito e revogado são tratados com mensagens específicas e
claras — nunca um erro técnico cru. A regra de e-mail divergente entre convite e conta foi decidida
e documentada explicitamente: **bloqueada**, tanto no cliente (UX, direciona a sair da conta atual)
quanto — de forma definitiva — no servidor (`acceptInvite` rejeita com `permission-denied` se o
e-mail autenticado não bater com o do convite, case-insensitive).

## Agentes utilizados

- `flutter-senior-architect` (Cloud Functions `validateInvite`/`acceptInvite`, domain/data da nova
  feature de aceite, índice do Firestore, RBAC/segurança server-side, testes de Emulator).
- `flutter-ui-design-specialist` (BLoC/estado de UI de `AcceptInvitePage`, extensão do `SignUpForm`
  para suportar e-mail travado, estados de erro específicos, reaproveitamento do Design System).

## Arquivos criados

Backend (Cloud Functions, TypeScript):

- `functions/src/invites/validate-invite.ts` — Cloud Function callable `validateInvite` (sem
  autenticação obrigatória).
- `functions/src/invites/accept-invite.ts` — Cloud Function callable `acceptInvite` (transacional,
  exige autenticação).
- `functions/test/invites/validate-invite.test.ts` (7 testes, Firestore Emulator real).
- `functions/test/invites/accept-invite.test.ts` (8 testes, Firestore Emulator real).

Frontend (extensão da feature `lib/features/invites/`):

- `domain/value_objects/invite_acceptance_outcome.dart`.
- `domain/entities/invite_preview.dart`, `domain/entities/accepted_invite.dart` (+ `.freezed.dart`
  gerados via build_runner).
- `domain/repositories/invite_acceptance_repository.dart`.
- `domain/usecases/validate_invite_use_case.dart`, `domain/usecases/accept_invite_use_case.dart`.
- `data/dtos/invite_preview_dto.dart`, `data/dtos/accepted_invite_dto.dart`.
- `data/mappers/invite_acceptance_mapper.dart`.
- `data/datasources/invite_acceptance_data_source.dart` (contrato) e
  `data/datasources/cloud_functions_invite_acceptance_data_source.dart` (Cloud Functions).
- `data/repositories/invite_acceptance_repository_impl.dart`.
- `presentation/bloc/accept_invite_event.dart`, `accept_invite_state.dart`, `accept_invite_bloc.dart`
  (+ `.freezed.dart` gerados).
- `presentation/pages/accept_invite_page.dart`.

Testes (Dart, mirror 1:1 da estrutura acima):

- `test/features/invites/domain/usecases/validate_invite_use_case_test.dart`,
  `accept_invite_use_case_test.dart`.
- `test/features/invites/data/dtos/invite_preview_dto_test.dart`,
  `accepted_invite_dto_test.dart`.
- `test/features/invites/data/mappers/invite_acceptance_mapper_test.dart`.
- `test/features/invites/data/datasources/cloud_functions_invite_acceptance_data_source_test.dart`.
- `test/features/invites/data/repositories/invite_acceptance_repository_impl_test.dart`.
- `test/features/invites/presentation/bloc/accept_invite_bloc_test.dart`.
- `test/features/invites/presentation/pages/accept_invite_page_test.dart`.

Documentação:

- `docs/tasks/TASK-040-implementar-aceite-de-convite-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `functions/src/index.ts` — exporta `validateInvite` e `acceptInvite`.
- `functions/src/invites/invite-shared.ts` — extraído `hashInviteToken` (reaproveitado por
  `generateInviteToken`); novos `findInviteByTokenHash` (busca por `collectionGroup('invites')`,
  aceita uma `Transaction` opcional para leitura atômica) e `resolveInviteOutcome` (resolve
  `'valid'|'expired'|'accepted'|'revoked'` a partir de um `Invite` já encontrado, tratando expiração
  de forma lazy via `expiresAt`, independente do campo `status`).
- `firestore.indexes.json` — novo `fieldOverride` para `tokenHash` em `invites` com
  `queryScope: COLLECTION_GROUP`, necessário para a query `collectionGroup('invites').where('tokenHash', '==', ...)`
  funcionar em produção (índices de campo único não cobrem automaticamente o escopo de collection
  group).
- `lib/core/navigation/app_route_paths.dart` — nova `InviteAcceptanceRoute` (`/invite/:token`).
- `lib/core/navigation/app_router.dart` — novo parâmetro `acceptInvitePageBuilder` e `GoRoute`
  correspondente.
- `lib/app/bootstrap.dart` — injeta o `AcceptInvitePage` real (via `AcceptInviteBloc`/`SignUpBloc`
  do container de DI) no novo `acceptInvitePageBuilder`.
- `lib/features/authentication/presentation/widgets/sign_up_form.dart` — três novos parâmetros
  opcionais, com defaults que preservam o comportamento anterior: `initialEmail` (pré-preenche o
  campo, sincronizando com `SignUpBloc` via `SignUpEvent.emailChanged` em `initState`), `lockEmail`
  (torna o campo somente leitura) e `showAlternateAuthLink` (permite ocultar o link "Já tem conta?
  Entrar", que perderia o contexto do convite se navegasse para `/login`).
- `lib/features/invites/invites.dart` — barrel atualizado com todos os novos arquivos.
- `lib/core/analytics/analytics_events.dart` — novo `AnalyticsEvents.inviteAccepted`
  (`'invite_accepted'`).
- `lib/features/audit_log/domain/value_objects/audit_action.dart` — novo
  `AuditAction.userInviteAccepted` (`'user.inviteAccepted'`), nunca escrito por código Dart, apenas
  interpretado de volta (gravado pela Cloud Function `acceptInvite`).
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) para registrar as
  novas classes `@injectable`/`@LazySingleton`.
- `test/core/navigation/app_router_test.dart`, `test/core/navigation/session_auth_guard_test.dart` —
  helpers de construção do `AppRouter` atualizados com o novo `acceptInvitePageBuilder`; novo teste
  de extração do parâmetro `token`.
- `test/core/analytics/analytics_events_test.dart` — `invite_accepted` adicionado à lista esperada.
- `test/features/audit_log/domain/value_objects/audit_action_test.dart` — asserção para o novo
  código.
- `docs/tasks/TASKS.md` — checkbox da TASK-040 marcado e `Progresso` atualizado para `40 / 220`.

Nenhum outro arquivo foi alterado. `lib/main.dart` tem uma modificação pré-existente não
relacionada a esta task (troca de entrypoint `main_dev.dart`/`main_prod.dart`, deixada por uma
sessão anterior) que foi deliberadamente ignorada — não lida, não revertida, não incluída em
nenhum commit desta task.

## Arquitetura utilizada

- Feature-first + Clean Architecture: extensão de `lib/features/invites/` com um segundo contrato
  de domínio, `InviteAcceptanceRepository` — deliberadamente **separado** de `InviteRepository`
  (gestão de convites por um OWNER/ADMIN já autenticado, sempre escopada por `organizationId`),
  porque aqui o chamador só tem um `token`: o `organizationId` é *resolvido* pela própria
  `validateInvite`/`acceptInvite`, nunca conhecido de antemão. Misturar os dois contratos quebraria
  o invariante que `InviteRepository` já documenta ("nenhuma chamada pode ser construída sem escopo
  de tenant por engano").
- `validateInvite`/`acceptInvite` seguem o mesmo padrão de `createOrganization`/`createInvite`:
  `onCall`, `resolveCorrelationId`, validação de payload antes de qualquer leitura/escrita,
  `logger.info` estruturado sem dado sensível. `acceptInvite` faz **toda** leitura de precondição
  (`Invite` por hash do token, Organization, Membership anterior) dentro da mesma transação que as
  escritas — mesmo padrão de atomicidade total de `createOrganization`, mais forte que o padrão
  "lê fora, escreve dentro" que `resendInvite`/`revokeInvite` (TASK-039) aceitaram conscientemente.
- `AcceptInviteBloc` segue o padrão de `SignUpBloc`/`OnboardingBloc`: `@injectable`, eventos/estados
  `freezed`, nenhuma regra de negócio na `presentation/`. `AcceptInvitePage` nunca chama
  `ValidateInviteUseCase`/`AcceptInviteUseCase`/`AuthRepository` diretamente.
- `AcceptInvitePage` reaproveita o `SignUpForm` (TASK-035) em vez de duplicar um formulário de
  cadastro — a extensão do widget (três parâmetros opcionais, todos com default que preserva o
  comportamento anterior) foi preferida a criar um segundo formulário quase idêntico.

## Regras de negócio implementadas

- Token validado **sempre** contra `validateInvite` antes de qualquer opção ser mostrada ao usuário
  — nunca validado apenas no client.
- `validateInvite` nunca lança exceção para um estado de negócio esperado (token
  desconhecido/expirado/aceito/revogado) — todos são valores distintos de
  `ValidateInviteResponse.outcome`/`InviteAcceptanceOutcome`, cada um com mensagem específica em
  `AcceptInvitePage`. Só uma falha técnica real (rede, servidor) chega como erro genérico.
  `HttpsError` só é usado para entrada malformada (`token` ausente).
- Expiração sempre calculada de forma lazy a partir de `expiresAt` vs. o horário atual, no
  server, independentemente do que o `status` do documento diz — decisão necessária porque nenhum
  código deste projeto jamais escreve `status: 'expired'` (não há cron/trigger para isso, ver
  comentário de `RESENDABLE_STATUSES` em `resend-invite.ts`, já existente).
- A role do vínculo é **exatamente** a definida no convite — o usuário nunca escolhe outra,
  garantido tanto por não haver campo de escolha na UI quanto por `acceptInvite` sempre gravar
  `Invite.roleName` no Membership, ignorando qualquer coisa que o cliente possa enviar.
- **Regra de e-mail divergente (decidida e documentada nesta task): bloqueada.** Aceitar o convite
  de outra pessoa com uma conta de e-mail diferente nunca é permitido — nem criando conta nova (o
  campo de e-mail fica travado no e-mail do convite, `SignUpForm(lockEmail: true)`) nem com uma
  conta já autenticada (`AcceptInviteBloc` compara `sessionUser.email` com `invite.email`,
  case-insensitive, e bloqueia a UI oferecendo apenas "Sair e continuar"). A autoridade real é
  sempre `acceptInvite`, que faz a mesma comparação server-side e rejeita com `permission-denied`
  independentemente do que o cliente decidiu mostrar.
- Um convite só pode ser aceito uma vez: `status: 'accepted'` é terminal e `resolveInviteOutcome`
  rejeita qualquer segunda tentativa com `failed-precondition` e mensagem específica
  ("Este convite já foi utilizado."), verificado dentro da mesma transação que grava a aceitação —
  uma corrida entre duas chamadas simultâneas nunca duplica o vínculo nem deixa o convite em estado
  inconsistente. Diferente de `revokeInvite`, `acceptInvite` **não** limpa `tokenHash` ao aceitar —
  o `status: 'accepted'` já basta para bloquear reuso, e mantê-lo permite que uma segunda tentativa
  receba a mensagem específica de "já utilizado" em vez de um genérico "não encontrado".
- Toda aceitação bem-sucedida gera uma entrada de auditoria (`user.inviteAccepted`: ator, role
  atribuída, organização, timestamp) na mesma transação Firestore da escrita principal.
- Aceitar vínculo de conta já existente preserva `createdAt`/`createdBy`/`teamIds` do Membership
  anterior (se houver) e incrementa `version` — nunca perde histórico administrativo por trás de um
  aceite de convite.

## Regras Firebase implementadas

- Nenhuma alteração em `firestore.rules`: `invites.create/update/delete` já eram `if false`
  incondicionalmente desde a TASK-039 — `acceptInvite` (Admin SDK) já era o único caminho possível
  para essa escrita, e a leitura do próprio Membership recém-criado (`organizations/{id}/members/{uid}`)
  já é permitida pela regra existente (`isActiveMember`), que passa a valer no instante em que o
  documento é escrito.
- `firestore.indexes.json`: novo `fieldOverride` de `tokenHash` com `queryScope: COLLECTION_GROUP`
  — sem ele, a query `collectionGroup('invites').where('tokenHash', '==', ...)` que
  `validateInvite`/`acceptInvite` fazem seria rejeitada pelo Firestore real em produção (funciona
  no Emulator sem índice explícito, mas não em produção).

## Analytics implementado

- `AnalyticsEvents.inviteAccepted` (`'invite_accepted'`), disparado por `AcceptInviteBloc` só após
  `acceptInvite` retornar sucesso, com um único parâmetro (`role`, o código da role atribuída) —
  nunca o e-mail/uid (dado pessoal), mesma restrição já documentada para `invite_sent`.

## Crashlytics implementado

Nenhuma captura nova dedicada: toda falha de `InviteAcceptanceRepository`/
`InviteAcceptanceDataSource` propaga como `Failure`/`AppException` já tratada pelo `CrashReporter`
central (TASK-016), mesmo padrão de toda outra feature.

## Impacto offline

Nenhuma mutação desta feature é offline-first: `validateInvite`/`acceptInvite` são chamadas de
Cloud Function online-only (mesma decisão de `createInvite`/`createOrganization`) — sem rede, a
operação falha com uma `Failure` tipada, sem persistência local/Outbox. Aceitável: o aceite de
convite é uma operação única de onboarding, não uma operação comercial recorrente que precise
sobreviver offline.

## Impacto multi-tenant

- `validateInvite`/`acceptInvite` nunca recebem `organizationId` do cliente — ele é sempre
  *resolvido* a partir do `Invite` que o token (hash) aponta, via `findInviteByTokenHash`
  (`collectionGroup('invites')`), nunca de um campo solto do payload.
- `acceptInvite` só escreve dentro de `organizations/{organizationId}` derivado exatamente do
  `Invite` encontrado — nunca de outro tenant.
- O e-mail do chamador é sempre lido de `request.auth.token.email` (Firebase Auth, servidor),
  nunca de nada que o cliente possa enviar no payload.

## Testes criados

- `functions/test/invites/validate-invite.test.ts` (7 testes, Firestore Emulator real via Admin SDK
  + `firebase-functions-test`): convite válido com contexto completo, token desconhecido (`notFound`,
  sem vazar dados), convite já aceito, convite revogado, convite expirado por `expiresAt` mesmo com
  `status` ainda `pending`, token ausente (`invalid-argument`), resposta nunca inclui `tokenHash`/token.
- `functions/test/invites/accept-invite.test.ts` (8 testes): aceite cria Membership com a role do
  convite + marca `accepted` + grava auditoria; segunda aceitação do mesmo token rejeitada
  (`failed-precondition`); convite expirado rejeitado; convite revogado rejeitado; e-mail divergente
  rejeitado (`permission-denied`, convite permanece `pending`); token desconhecido (`not-found`);
  chamada não autenticada (`unauthenticated`); vínculo de conta já existente preserva
  `createdAt`/`createdBy`/`teamIds` e incrementa `version`.
- Lado Dart, 33 testes novos, espelhando 1:1 a estrutura da extensão: `validate_invite_use_case_test.dart`,
  `accept_invite_use_case_test.dart` (validação client-side + delegação/propagação de falha),
  `invite_preview_dto_test.dart`, `accepted_invite_dto_test.dart` (parsing/validação de payload),
  `invite_acceptance_mapper_test.dart` (mapeamento de outcome/role, incluindo códigos desconhecidos),
  `cloud_functions_invite_acceptance_data_source_test.dart` (payload enviado às duas Cloud
  Functions, `requireAuth` diferenciado entre `validate`/`accept`),
  `invite_acceptance_repository_impl_test.dart`, `accept_invite_bloc_test.dart` (outcome válido sem
  sessão, e-mail coincidente/divergente com sessão ativa, cada outcome inválido, falha técnica
  distinta de outcome de negócio, aceite com analytics, falha de aceite sem analytics, sign-out),
  `accept_invite_page_test.dart` (mensagem específica para convite expirado, fluxo completo de
  criação de conta nova com e-mail travado até a navegação de sucesso, confirmação direta com sessão
  já compatível, bloqueio + recuperação por sign-out com e-mail divergente).
- `test/core/navigation/app_router_test.dart`: novo teste de extração do parâmetro `token` da rota
  `/invite/:token`.

## Comandos executados

```bash
cd functions && npm run build
cd functions && npm run lint
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix functions test -- invites"
firebase emulators:exec --only firestore "npm --prefix functions test"
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/invites/
flutter test test/features/invites/presentation/ test/core/navigation/
flutter test
flutter build web
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → `Formatted 565 files (0 changed)` na última passada (após
todas as correções de formatação automática já aplicadas nas passadas anteriores).

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 10.8s)`.

## Resultado dos testes

- `npm run build` (functions/TypeScript): sem erros.
- `npm run lint` (functions/ESLint): sem erros/avisos.
- `firebase emulators:exec --only firestore "npm --prefix functions test"`: `Test Suites: 8 passed,
  8 total` / `Tests: 55 passed, 55 total` (40 já existentes da TASK-039 e anteriores + 7 de
  `validate-invite` + 8 de `accept-invite`).
- `flutter test test/features/invites/`: `+84: All tests passed!` (era +57 após a TASK-039).
- `flutter test` (suíte completa do repositório): `+947: All tests passed!`.
- `flutter build web`: `√ Built build\web`.

Não foi necessário rodar `firebase emulators:exec ... firestore-tests` nesta task: nenhuma regra em
`firestore.rules` foi alterada (a subcoleção `invites` já era `create/update/delete: if false`
incondicional desde a TASK-039, e a leitura de `members` já cobria o caso do próprio usuário lendo
seu Membership recém-criado).

## Decisões técnicas

- **Expiração sempre lazy, nunca confiada ao campo `status`** — `resolveInviteOutcome` (novo em
  `invite-shared.ts`) recalcula `expired` a partir de `expiresAt` vs. `now` toda vez, porque nenhuma
  função deste projeto jamais escreve `status: 'expired'` (não há cron/trigger — só existe como
  valor teoricamente aceito por `resend-invite.ts`'s `RESENDABLE_STATUSES`, herdado como está).
  Confiar apenas no campo armazenado deixaria todo convite "pendente" tecnicamente expirado como
  eternamente aceitável.
- **`acceptInvite` não limpa `tokenHash` ao aceitar (diferente de `revokeInvite`)** — decisão
  deliberada: `status: 'accepted'` já é suficiente para bloquear qualquer reuso (o
  `resolveInviteOutcome` rejeita antes de chegar a comparar hash), e preservar o hash permite que
  uma segunda tentativa com o mesmo token receba a mensagem específica "Este convite já foi
  utilizado" em vez do genérico "Convite não encontrado" que a limpeza causaria. Validado por
  teste (`rejects a second acceptance of the same token`).
- **E-mail divergente: bloqueado, nunca permitido** — a alternativa (permitir aceitar com qualquer
  conta, desde que o token seja válido) foi descartada: o token por e-mail é a única prova de que a
  organização quis convidar aquele endereço específico; aceitar com outro e-mail quebraria essa
  garantia sem nenhum ganho de usabilidade real. Reforçado em duas camadas (UX client-side +
  autoridade real server-side), nunca apenas uma.
- **`acceptInvite` lê tudo dentro da transação (`findInviteByTokenHash` aceita uma `Transaction`
  opcional)** — mais forte que o padrão "lê fora, escreve dentro" que `resendInvite`/`revokeInvite`
  aceitaram na TASK-039: como aceitar é uma operação "consumir uma vez só" com efeitos permanentes
  (Membership), o mesmo padrão de atomicidade total de `createOrganization` foi escolhido em vez do
  mais simples.
- **`SignUpForm` estendido em vez de duplicado** — `initialEmail`/`lockEmail`/`showAlternateAuthLink`
  são todos opcionais com default que preserva exatamente o comportamento anterior da TASK-035;
  `SignUpPage` continua funcionando sem nenhuma mudança de comportamento.
- **`AcceptInvitePage` não foi wireada para reaproveitar `SignUpPage` inteira** — o
  `BlocListener<SignUpBloc>` de `SignUpView` navega incondicionalmente para `OnboardingWizardRoute`
  no sucesso, o que não serve ao fluxo de convite (que precisa chamar `acceptInvite` a seguir, não
  ir para o onboarding). `AcceptInvitePage` compõe seu próprio `BlocProvider<SignUpBloc>` +
  `BlocListener` em torno de `SignUpForm` diretamente, evitando duplicar o formulário sem herdar um
  comportamento de navegação incompatível.

## Riscos conhecidos

- Sem deep link nativo (Android/iOS) ativado — decisão já registrada e adiada desde antes desta
  task (`docs/architecture/navigation.md`): a rota `/invite/:token` funciona hoje via `go_router`
  (inclusive Flutter Web), mas abrir o link de um e-mail em um device sem o app instalado ainda
  depende de o usuário acessar a versão Web.
- Se o usuário sem conta preferir entrar com uma conta já existente (mas está deslogado), o link
  "Já tem conta? Entrar" leva para `/login` sem nenhum mecanismo de retorno automático a
  `/invite/:token` após o login — o usuário precisa reabrir o link do e-mail manualmente depois de
  entrar. TASK-041 (sessão persistente) é a candidata natural para resolver isso de forma completa
  (redirect-after-login), mas está fora do escopo desta task.
- `SYSTEM_ROLE_RANK`/`systemRoleRank` continuam sincronizados manualmente entre TypeScript e Dart —
  mesmo risco já registrado pela TASK-030/037/039, não agravado nem resolvido por esta task.

## Pendências

- Redirect-after-login de volta para `/invite/:token` quando o usuário escolhe "Já tem conta?
  Entrar" estando deslogado — depende do trabalho de sessão persistente da TASK-041.
- Deep link nativo (Android/iOS) — pendência já registrada antes desta task, não within scope.
- Nenhuma pendência bloqueia a conclusão desta task: os critérios de aceite (aceite funcional para
  conta nova e conta existente; convite expirado/já usado/revogado tratado com mensagem clara; role
  correta validada no backend; `dart format`/`flutter analyze`/`flutter test` sem erros) estão
  implementados e testados.

## Evidências

- `functions/src/invites/validate-invite.ts`, `functions/src/invites/accept-invite.ts` e
  `functions/test/invites/{validate,accept}-invite.test.ts` (15 testes novos).
- `lib/features/invites/` (extensão da feature) e `test/features/invites/` (33 testes novos).
- Saída de `firebase emulators:exec --only firestore "npm --prefix functions test"`
  (`Tests: 55 passed, 55 total`), de `flutter test` (`+947: All tests passed!`) e de
  `flutter build web` (`√ Built build\web`), reproduzidas nas seções "Resultado dos testes" acima.

## Commit

Criado com sucesso (`lib/main.dart`, alteração pré-existente não relacionada a esta task, foi
deliberadamente deixado de fora do commit).

## Push

Autorizado nesta rodada; executado com sucesso após o commit.

## Hash do commit

Ver seção "Hash do commit" da resposta final desta task.

## Branch

`main`

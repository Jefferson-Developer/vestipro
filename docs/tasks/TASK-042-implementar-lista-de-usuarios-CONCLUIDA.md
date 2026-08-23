# TASK-042 — Concluída (2026-08-23)

## Resumo

Implementada a listagem administrativa de usuários da organização (`UserListPage`), com busca por
nome/e-mail (debounce no `AppSearchField`), filtros combináveis por role e status, paginação
"carregar mais" e ações contextuais opcionais de acesso rápido para gerenciar perfil/permissão
(TASK-043) e desativar usuário (TASK-046). Como pré-requisito, o `Membership` passou a carregar um
snapshot denormalizado de `name`/`email`, escrito pelas Cloud Functions `createOrganization` e
`acceptInvite` — únicos pontos que hoje criam um Membership —, e a regra de Firestore de `members`
foi dividida em `get` (qualquer membro ativo, como já era) e `list` (agora restrito a quem tem
`user.changeRole`, hoje só OWNER/ADMIN).

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, RBAC, Firestore Rules, Cloud Functions)
- `flutter-ui-design-specialist` (UI, Design System, responsividade)

## Arquivos criados

- `lib/features/users/domain/entities/organization_user.dart` (+ `.freezed.dart` gerado)
- `lib/features/users/domain/usecases/list_organization_users_use_case.dart`
- `lib/features/users/presentation/bloc/user_list_event.dart` (+ `.freezed.dart`)
- `lib/features/users/presentation/bloc/user_list_state.dart` (+ `.freezed.dart`)
- `lib/features/users/presentation/bloc/user_list_bloc.dart`
- `lib/features/users/presentation/pages/user_list_page.dart`
- `lib/features/users/users.dart`
- `test/features/users/domain/usecases/list_organization_users_use_case_test.dart`
- `test/features/users/presentation/bloc/user_list_bloc_test.dart`
- `test/features/users/presentation/pages/user_list_page_test.dart`

## Arquivos alterados

- `firestore.rules` — `members/{userId}`: `allow read` dividido em `allow get`
  (`isActiveMember`, inalterado) e `allow list` (agora exige `user.changeRole`).
- `firestore-tests/firestore.rules.test.js` — 3 novos testes: OWNER lista os members da própria
  organização; SALES_REP não consegue listar; OWNER não consegue listar members de outra
  organização (cross-tenant).
- `functions/src/organizations/create-organization.ts` — a Membership OWNER passa a gravar
  `name`/`email` denormalizados (reaproveitando o `actorName`/`profileSnapshot` já lidos para o
  audit log).
- `functions/src/invites/accept-invite.ts` — idem, reaproveitando `actorName`/`callerEmail` já
  computados no fluxo de aceite.
- `functions/test/create-organization.test.ts` / `functions/test/invites/accept-invite.test.ts` —
  novas asserções/teste cobrindo o `name`/`email` denormalizados.
- `lib/features/organizations/domain/entities/membership.dart` — novos campos opcionais `name`/
  `email` (nulos por padrão; nenhuma constução existente precisou ser alterada).
- `lib/features/organizations/data/dtos/membership_dto.dart` — parse/serialização opcional de
  `name`/`email`.
- `lib/features/organizations/data/mappers/membership_mapper.dart` — passa `name`/`email` adiante
  nos dois sentidos.
- `test/features/organizations/data/dtos/membership_dto_test.dart` /
  `test/features/organizations/data/mappers/membership_mapper_test.dart` — novos casos cobrindo os
  campos novos.
- `docs/tasks/TASKS.md` — checkbox da TASK-042 marcado e progresso atualizado (42/220).

## Arquitetura utilizada

Clean/feature-first + BLoC, seguindo exatamente o precedente de `InviteListBloc`/`InviteListPage`
(TASK-039). `lib/features/users/` não tem camada de dados própria: `ListOrganizationUsersUseCase`
compõe diretamente `MembershipRepository`/`TeamRepository` (já existentes em `organizations/`),
mesmo precedente de `InviteFormBloc` (que já depende de `MembershipRepository` fora da própria
feature). `UserListPage` nunca acessa Firestore/repositório diretamente — toda transição de estado
passa por `UserListBloc`.

Decisão deliberada: busca (nome/e-mail), filtros (role/status) e paginação ("carregar mais") são
resolvidos **em memória**, sobre a lista completa retornada por `ListOrganizationUsersUseCase`
(que por sua vez usa `MembershipRepository.listByOrganization`, já limitado a 500 documentos por
`FirestoreCollectionDataSource.getPage`) — não são uma query Firestore por keystroke. Motivo:
`Membership` e `users/{uid}` não podem ser unidos (`join`) por uma query Firestore, e a busca por
texto (nome/e-mail) exigiria ou um índice de busca dedicado (inexistente no projeto) ou denormalizar
um campo already-lowercased para range query — nenhum dos dois se justifica para o tamanho real de
um roster interno de uma organização B2B (dezenas a poucas centenas de usuários). Ver "Riscos
conhecidos" para o ponto exato em que essa decisão deveria ser revisitada.

## Regras de negócio implementadas

- Listagem sempre escopada pela organização ativa (`organizationId` explícito em toda a cadeia:
  bloc → use case → `MembershipRepository`/`TeamRepository`).
- Acesso restrito a perfis administrativos: `UserListPage` envolve todo o conteúdo em
  `PermissionBuilder` exigindo `Capability.userChangeRole` (hoje, só OWNER/ADMIN) — quem não tem a
  capability nunca vê a tabela, apenas o fallback "Você não tem permissão para acessar esta
  página." (`ForbiddenPage`), e a query nunca chega a ser montada (o `UserListBloc` só é criado e
  só dispara `started` depois de `PermissionBuilder` resolver `granted == true`).
- Busca por nome/e-mail (case-insensitive, contains) e filtros por role (7 system roles) e por
  status (ativo/desativado), combináveis entre si.
- Paginação "carregar mais" (`AppPagination`, modo `loadMore`) sobre a lista já filtrada.
- Ações contextuais "gerenciar perfil/permissão" e "desativar usuário" existem como pontos de
  extensão (`onManageUser`/`onDeactivateUser`, callbacks opcionais) mas ficam ocultas até TASK-043/
  TASK-046 existirem — nenhum botão leva a lugar nenhum hoje.

## Regras Firebase implementadas

- `firestore.rules`: `organizations/{organizationId}/members/{userId}` — `allow get` inalterado
  (qualquer membro ativo); `allow list` (query administrativa) agora exige
  `hasCapability(organizationId, 'user.changeRole')`. Nenhum caso de uso em produção hoje chama
  `MembershipRepository.listByOrganization` fora deste fluxo (validado por busca no código antes da
  alteração), então a restrição não quebra nenhum caminho existente.
- `functions/src/organizations/create-organization.ts` / `functions/src/invites/accept-invite.ts`:
  únicos dois pontos que criam/recriam um Membership — ambos agora gravam `name`/`email`
  denormalizados a partir do `users/{uid}` profile (ou fallback do auth token), reaproveitando
  cálculos que já existiam para o audit log (`actorName`) e para a validação de e-mail do convite
  (`callerEmail`).

## Analytics implementado

Nenhum evento de Analytics específico foi adicionado nesta task (fora do escopo pedido — a listagem
em si não é uma conversão/ação de negócio a instrumentar; ações de gerenciar/desativar, quando
existirem em TASK-043/046, são o ponto natural para instrumentar).

## Crashlytics implementado

Nenhum ponto de captura dedicado foi necessário: erros de carregamento já são tratados como
`Failure` tipada e exibidos via `AppErrorState`/`AppDataTable` (estado `error` com retry), seguindo o
mesmo padrão de todo o app.

## Impacto offline

A listagem depende de uma leitura online (`members` `list`, restrita por regra a quem tem
`user.changeRole`) — não há cache offline dedicado nesta task; uma falha de rede é reportada como
`ConnectivityFailure` e tratada como qualquer outra falha de carregamento (estado `error` com
"Tentar novamente").

## Impacto multi-tenant

Escopo por `organizationId` reforçado em duas camadas: (1) todo o caminho Dart
(`UserListBloc`/`ListOrganizationUsersUseCase`/`MembershipRepository`/`TeamRepository`) exige
`organizationId` explícito; (2) `firestore.rules` nega qualquer `list` de `members` cuja
organização não seja a do membership ativo do requisitante — validado por um novo teste específico
de cross-tenant.

## Testes criados

- `test/features/users/domain/usecases/list_organization_users_use_case_test.dart` — junção
  Membership+Team, fallback de nome/e-mail ausentes, propagação de falha de listagem, roster vazio,
  falha isolada de `TeamRepository` não bloqueia a lista.
- `test/features/users/presentation/bloc/user_list_bloc_test.dart` — carregamento (sucesso/falha),
  busca, filtros combinados (role+status), limpeza de filtro, paginação "carregar mais" (inclusive
  no-op quando não há mais itens, sem re-consultar o repositório).
- `test/features/users/presentation/pages/user_list_page_test.dart` — ocultação da tela para
  SALES_REP (sem `user.changeRole`), renderização para OWNER, layout em tabela (desktop) vs. cards
  (mobile), estado vazio.
- `test/features/organizations/data/dtos/membership_dto_test.dart` /
  `.../data/mappers/membership_mapper_test.dart` — novos casos para os campos `name`/`email`.
- `firestore-tests/firestore.rules.test.js` — 3 novos testes de `list` (permitido para OWNER,
  negado para SALES_REP, negado cross-tenant).
- `functions/test/create-organization.test.ts` / `functions/test/invites/accept-invite.test.ts` —
  novas asserções/teste para o `name`/`email` denormalizados.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib/features/users lib/features/organizations/domain/entities/membership.dart lib/features/organizations/data/dtos/membership_dto.dart lib/features/organizations/data/mappers/membership_mapper.dart test/features/users test/features/organizations/data/dtos/membership_dto_test.dart test/features/organizations/data/mappers/membership_mapper_test.dart
flutter analyze
flutter test
cd functions && npm run build && npm run lint
firebase emulators:exec --only firestore "npm --prefix functions test"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
```

## Resultado do formatter

`dart format --set-exit-if-changed`: sem alterações pendentes (0 arquivos alterados na verificação
final).

## Resultado do analyzer

`flutter analyze`: **No issues found!**

## Resultado dos testes

- `flutter test`: **989 testes, todos passando** (suite completa do projeto, incluindo os novos
  arquivos desta task).
- `cd functions && npm run build`: sem erros de tipo.
- `cd functions && npm run lint`: sem apontamentos.
- `firebase emulators:exec --only firestore "npm --prefix functions test"`: **8 suites, 56 testes,
  todos passando**.
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`: **1 suite, 60
  testes, todos passando**.

Observação sobre o ambiente: o Firebase Emulator Suite exige Java, que não estava no `PATH` por
padrão nesta máquina; foi localizado e usado o JBR (`java` 21) empacotado com o Android Studio já
instalado (`C:\Program Files\Android\Android Studio\jbr\bin`) apenas para esta sessão de shell — não
foi feita nenhuma instalação/alteração permanente no ambiente.

## Decisões técnicas

1. **Denormalizar `name`/`email` no `Membership`** em vez de o cliente ler `users/{uid}` de outros
   usuários: `firestore.rules` já nega isso (`allow get: if request.auth.uid == userId; allow list:
   if false;`), então um "join" no cliente é estruturalmente impossível sem enfraquecer essa regra
   (o que não seria aceitável). Os dois únicos pontos que criam um `Membership`
   (`createOrganization`, `acceptInvite`) já resolviam um nome (`actorName`, para o audit log) e um
   e-mail (`callerEmail`/`request.auth.token.email`) — bastou reaproveitar e persistir.
2. **`firestore.rules`: dividir `allow read` de `members` em `get`/`list`** em vez de introduzir uma
   nova Cloud Function agregadora: nenhum caso de uso em produção hoje chama
   `MembershipRepository.listByOrganization` fora do fluxo desta task (confirmado por busca no
   código antes da alteração), então a nova restrição de `list` é estritamente aditiva em termos de
   segurança e não quebra nada existente.
3. **Busca/filtro/paginação em memória**, não uma query Firestore por keystroke — ver "Arquitetura
   utilizada" acima para o raciocínio completo.
4. **Reaproveitar `systemRoleNameLabel`/`systemRoleNameFromCode`** (ambos já existentes em
   `lib/features/invites/`) em vez de duplicar o mapeamento de rótulos de role — import cross-
   feature deliberado (mesmo precedente de `InviteFormBloc` importando `MembershipRepository` de
   `organizations/`). Para os chips de filtro (painel lateral estreito do `AppAdminPageLayout`), um
   rótulo mais curto (`_roleFilterLabel`) evita overflow que o rótulo completo ("Proprietário
   (OWNER)") causaria.
5. **Ações "gerenciar perfil/permissão" e "desativar usuário" como callbacks opcionais**
   (`onManageUser`/`onDeactivateUser`), ausentes por padrão: as páginas de destino (TASK-043/046)
   ainda não existem, e um botão sem destino real seria pior UX do que nenhum botão.
6. **Rota não registrada em `app_router.dart`** — mesmo precedente de `InviteListPage`/
   `InviteUserPage` (TASK-039), que também não estão roteadas ainda. Fica para uma task futura de
   navegação/menu administrativo.

## Riscos conhecidos

- **Escalabilidade**: busca/filtro/paginação em memória sobre até 500 membros (limite atual de
  `FirestoreCollectionDataSource.getPage`) é adequado para o tamanho esperado de uma equipe interna
  B2B, mas não escalaria para organizações com milhares de usuários. Se isso deixar de ser verdade,
  revisitar com uma query Firestore real (`orderBy('name')` + range query) ou um índice de busca
  dedicado.
- **`name`/`email` são um snapshot, não um espelho vivo**: se um usuário editar seu próprio nome no
  futuro (não há essa tela ainda), o `Membership.name` não é atualizado automaticamente — ficaria
  desatualizado até uma futura sincronização. Documentado nos comentários do código.
- **Memberships criados antes desta task** (se já existirem em ambientes de desenvolvimento/QA) não
  têm `name`/`email` — `ListOrganizationUsersUseCase` cai no fallback (`userId` como nome, e-mail
  vazio exibido como "—"), sem quebrar a listagem.

## Pendências

- Registrar `UserListPage` em `app_router.dart` com `PermissionAuthorizationGuard` (capability
  `user.changeRole`) quando a navegação administrativa for definida — não fazia parte do escopo
  desta task (mesmo estado de `InviteListPage`).
- Conectar `onManageUser`/`onDeactivateUser` reais quando TASK-043/TASK-046 existirem.
- Resolver nomes de equipe ("Equipe") depende de `Team`s já cadastrados; TASK-044 (equipes
  comerciais) ainda não tem UI própria de criação — a coluna funciona, mas hoje normalmente
  aparecerá vazia ("—") em organizações sem equipes cadastradas manualmente.

## Evidências

Ver "Resultado dos testes" acima (989 testes Flutter, 56 testes de Cloud Functions, 60 testes de
Firestore Rules, todos passando).

## Commit

Ver hash abaixo.

## Push

Autorizado e executado nesta rodada.

## Hash do commit

Registrado após o `git commit` (ver resposta final da task).

## Branch

`main`

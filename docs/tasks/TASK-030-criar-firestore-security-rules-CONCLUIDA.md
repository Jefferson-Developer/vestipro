# TASK-030 — Concluída (2026-08-22)

## Resumo

Implementadas as Firestore Security Rules reais para `organizations/{organizationId}` e as
subcoleções modeladas em TASK-026 a TASK-029 (`companies`, `branches`, `roles`, `teams`, `members`),
substituindo o placeholder "deny all" (introduzido na TASK-010). Toda leitura/escrita passa a exigir
um Membership real e ativo do usuário autenticado, relido a partir do próprio Firestore — nunca a
partir de um `organizationId`/role alegado pelo cliente. RBAC (TASK-029) é espelhado nas rules por
uma função `roleHasCapability` equivalente à `RolePermissionMatrix`. Foi criada também a infraestrutura
de testes de rules (`firestore-tests/`, com `@firebase/rules-unit-testing` + Jest) e 32 testes
positivos/negativos (incluindo cross-tenant explícito, payload forjado, role sem capability e
tentativa de alterar role de sistema) foram escritos e executados com sucesso no Firebase Emulator
Suite.

## Agentes utilizados

- `flutter-senior-architect` (único exigido pela task).

## Arquivos criados

- `firestore-tests/package.json` — dependências (`@firebase/rules-unit-testing`, `jest`) e script
  `npm test` para o pacote de testes de rules.
- `firestore-tests/firestore.rules.test.js` — 32 testes positivos/negativos contra o Firestore
  Emulator, cobrindo `organizations`, `companies`, `branches`(indireto via mesma lógica), `roles`,
  `teams`(indireto) e `members`.
- `docs/tasks/TASK-030-criar-firestore-security-rules-CONCLUIDA.md` — este arquivo.

## Arquivos alterados

- `firestore.rules` — substituído o placeholder "deny all" pelas regras reais descritas abaixo.
- `.gitignore` — adicionado `/firestore-tests/node_modules/` (mesmo padrão já usado para
  `/functions/node_modules/`).
- `docs/tasks/TASKS.md` — checkbox da TASK-030 marcado e `Progresso` atualizado para `30 / 220`.

## Arquitetura utilizada

N/A para código Dart (task é 100% Firestore Rules + testes JS). Nenhum arquivo `lib/` foi alterado;
os nomes de campo/coleção usados nas rules foram conferidos diretamente contra os DTOs já existentes
(`organization_dto.dart`, `company_dto.dart`, `branch_dto.dart`, `role_dto.dart`, `team_dto.dart`,
`membership_dto.dart`) para garantir que a rule reflita exatamente o que o app grava.

## Regras de negócio implementadas

- `isActiveMember(organizationId)`: único ponto que decide pertencimento a uma Organization — sempre
  relê `organizations/{organizationId}/members/{request.auth.uid}` e exige `status == 'active'`.
  Nunca confia em nenhum campo do documento sendo lido/escrito.
- `roleHasCapability(roleName, capabilityCode)`: espelha
  `lib/core/permissions/role_permission_matrix.dart` (TASK-029) — OWNER com tudo, ADMIN com tudo
  exceto `organization.transferOwnership`, SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE com os
  subconjuntos exatos da matriz Dart, READ_ONLY e roles desconhecidas em default-deny.
- `hasCapability(organizationId, capabilityCode)`: reverifica `isActiveMember` e só então consulta a
  matriz — nunca aceita a capability resolvida no cliente.
- Campos imutáveis protegidos via `unchanged(field)`: `organizationId`/`companyId` em
  companies/branches/roles/teams/members; `name`/`slug`/`status`/`createdAt`/`createdBy` na própria
  Organization; `isSystemRole` em roles.
- Roles de sistema (`isSystemRole == true`) nunca podem ser atualizados nem excluídos por regra —
  espelha `assertRoleIsMutable` (TASK-028/`lib/features/organizations/domain/entities/role.dart`).
- 3 janelas de bootstrap deliberadas e estreitas, necessárias porque `CreateOrganizationUseCase` →
  `EnsureSystemRolesUseCase` → `AssignRoleToUserUseCase` (papel OWNER) ainda rodam direto do cliente,
  em sequência, sem Cloud Function (onboarding com Function é a TASK-037, fora do escopo desta task):
  1. Qualquer usuário autenticado pode criar sua própria Organization
     (`request.resource.data.createdBy == request.auth.uid`).
  2. O criador da Organization (`Organization.createdBy`, verificado via `get()`, nunca via payload)
     pode semear exatamente os 7 system roles fixos (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`,
     `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`) antes de ter Membership.
  3. O criador da Organization pode conceder a si mesmo o Membership `OWNER` (`roleId`/`roleName ==
     'OWNER'`), também verificado contra `Organization.createdBy`, nunca contra o payload.
  Fora dessas 3 janelas, todo `create` de role custom ou de novo Membership exige a capability real
  (`role.manage`/`user.invite`) de quem já é membro ativo.
- `organizations` nunca permite `list` (nenhuma query "listar todos os tenants"); toda leitura exige
  conhecer o `organizationId` de antemão (via path).

## Regras Firebase implementadas

Arquivo `firestore.rules` completo (ver arquivo para o texto integral e comentários). Cobertura:

- `organizations/{organizationId}`: get/create/update conforme acima; list e delete sempre negados.
- `organizations/{organizationId}/companies/{companyId}`: read para qualquer membro ativo;
  create/update/delete exigem `company.manage`.
- `organizations/{organizationId}/branches/{branchId}`: read para qualquer membro ativo;
  create/update/delete exigem `branch.manage`; `organizationId`/`companyId` imutáveis.
- `organizations/{organizationId}/roles/{roleId}`: read para qualquer membro ativo; create/update/
  delete de roles custom exigem `role.manage`; roles de sistema protegidos (ver acima); bootstrap dos
  7 system roles restrito ao criador da Organization.
- `organizations/{organizationId}/teams/{teamId}`: read para qualquer membro ativo; create/update/
  delete exigem `team.manage`.
- `organizations/{organizationId}/members/{userId}`: read para qualquer membro ativo; create exige
  `user.invite` (ou bootstrap OWNER); update exige `user.changeRole` ou `user.deactivate`; delete
  sempre negado (não há caso de uso de exclusão — desativação é feita via `status: 'inactive'`).

`firebase.json` não precisou de alteração (já apontava para `firestore.rules`/porta 8080 do emulador
desde a TASK-010).

## Analytics implementado

N/A — task não envolve eventos de produto/Analytics.

## Crashlytics implementado

N/A — task não envolve código Dart/cliente.

## Impacto offline

Nenhum: Security Rules atuam apenas nas escritas/leituras que efetivamente chegam ao Firestore.
Mutations enfileiradas no Outbox continuam do jeito que já eram — ao sincronizar, passam a ser
avaliadas pelas regras reais em vez do "deny all" anterior (que já bloqueava tudo mesmo, então nenhum
fluxo offline existente é afetado por esta mudança: nada podia gravar antes, e agora só quem tem
Membership/capability real consegue).

## Impacto multi-tenant

Este é o núcleo da task: isolamento cross-tenant agora é garantido no próprio backend, não apenas no
cliente. Testado explicitamente (ver `firestore-tests/firestore.rules.test.js`): um usuário com
Membership só na Org A nunca consegue ler nem escrever nenhum documento da Org B, mesmo tentando
declarar `organizationId` da Org B no payload de escrita.

## Testes criados

`firestore-tests/firestore.rules.test.js` — 32 casos com `@firebase/rules-unit-testing` +
`initializeTestEnvironment`, contra o Firestore Emulator real (não é fake/mocked):

- Positivos: OWNER lê/atualiza Organization; membro ativo lê Company/Role/Membership da própria org;
  OWNER cria/exclui Company; OWNER cria role custom; OWNER convida novo Membership; OWNER troca role
  de outro membro; as 3 janelas de bootstrap (criar Organization própria, semear os 7 system roles,
  conceder a si mesmo o Membership OWNER) funcionam para o criador legítimo.
- Negativos: usuário não autenticado não lê nada; membro da Org A não lê Organization/Company/
  Membership da Org B (cross-tenant explícito); usuário sem Membership não escreve na Org B mesmo
  forjando `organizationId` no payload; SALES_REP não atualiza settings, não cria/exclui Company, não
  cria role custom, não convida membro, não troca a própria role (falta de capability); ninguém
  renomeia/exclui um system role; nenhuma das 3 janelas de bootstrap funciona para quem não é o
  criador real da Organization; Membership com `status: 'inactive'` perde acesso de leitura.

## Comandos executados

```bash
cd firestore-tests && npm install
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
git status --porcelain=v1
```

Nenhum arquivo `.dart` foi criado/alterado nesta task, então `dart format`, `flutter analyze` e
`flutter test` não foram executados — não haveria nada de Dart para validar (protocolo em
`AGENTS.md`/`TASK-030-criar-firestore-security-rules.md` pede essas ferramentas "quando houver código
Dart/Flutter afetado", o que não é o caso aqui).

## Resultado do formatter

Não aplicável (nenhum arquivo Dart alterado).

## Resultado do analyzer

Não aplicável (nenhum arquivo Dart alterado).

## Resultado dos testes

`firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`:

```text
Test Suites: 1 passed, 1 total
Tests:       32 passed, 32 total
Snapshots:   0 total
Time:        3.415 s
```

Observação de ambiente: o Firebase CLI precisa de `java` no PATH para o emulador do Firestore; a
máquina não tinha um JDK dedicado instalado, então o JBR embutido no Android Studio
(`C:\Program Files\Android\Android Studio\jbr\bin`) foi usado só para esta execução, adicionado ao
PATH da sessão do shell — nenhuma configuração permanente do sistema foi alterada.

## Decisões técnicas

- RBAC das rules (`roleHasCapability`) duplica manualmente a matriz de
  `lib/core/permissions/role_permission_matrix.dart` em vez de tentar compartilhar código com o
  Dart (Firestore Rules não executam Dart). Documentado extensivamente em comentário no topo do
  `firestore.rules` para reduzir o risco de as duas tabelas divergirem no futuro sem que alguém note.
- As 3 janelas de bootstrap (criar a própria Organization / semear os 7 system roles / conceder a si
  mesmo o Membership OWNER) foram desenhadas para não depender de nenhum `organizationId` cru do
  payload: todas re-verificam contra `Organization.createdBy`, um campo imutável desde a criação
  (a própria regra de `update` da Organization bloqueia alterá-lo). Isso preserva o princípio "nunca
  confiar só no organizationId do cliente" mesmo no caso limite em que ainda não existe Membership.
- Leitura (`get`/`list`) de `companies`/`branches`/`roles`/`teams`/`members` foi liberada para
  qualquer membro ativo da organização (independente de capability), já que nenhuma capability de
  leitura foi modelada em TASK-029 — apenas escrita é gated por capability. Isso é intencional e
  equivalente ao que o app já expõe hoje (ex.: uma tela de RBAC precisa listar roles/membros mesmo
  para perfis sem permissão de editá-los).
- `organizations` nunca permite `list` — forço todo acesso a conhecer o `organizationId` de antemão,
  em vez de depender de uma query "todas as organizations que eu vejo" (que não existe hoje no app;
  quando existir, deve usar uma coleção denormalizada própria, não uma query aberta no root
  `organizations`).

## Riscos conhecidos

- **Duplicação da matriz RBAC**: `roleHasCapability` nas rules precisa ser atualizado manualmente
  toda vez que `RolePermissionMatrix` (Dart) mudar. Não há teste automatizado que compare as duas
  tabelas linha a linha hoje — um teste de "paridade" (ex.: gerar as rules ou ao menos a tabela a
  partir de uma única fonte, ou um teste Dart que serializa a matriz e compara com uma cópia
  string do trecho das rules) é um risco/pendência a considerar em uma task futura de manutenção do
  RBAC.
- **Bootstrap sem Cloud Function**: as 3 janelas de bootstrap só existem porque o onboarding de
  Organization ainda é 100% client-side. Quando a TASK-037 (onboarding) trocar isso por uma Cloud
  Function que cria Organization + system roles + Membership OWNER numa única operação
  server-side/admin-privileged, essas 3 janelas de `create` podem e devem ser removidas do
  `firestore.rules` (o cliente deixaria de escrever esses documentos diretamente).
- **Custom roles**: `role.manage` já libera criar/editar/excluir roles custom (`isSystemRole:
  false`), mas ainda não existe nenhum use case Dart que crie um role custom — a capability de RBAC
  (`RolePermissionMatrix.capabilitiesForRoleName`) hoje resolve vazio para qualquer role fora dos 7
  nomes de sistema. As rules já suportam o caso futuro, mas ele ainda não é exercitado pelo app.
- **Ambiente sem JDK dedicado**: rodar os testes de rules localmente depende de `java` no PATH; nesta
  máquina isso só foi possível usando o JBR do Android Studio. Recomendo instalar um JDK dedicado
  (ou documentar isso no README do time) para não depender do IDE estar instalado.

## Pendências

- Nenhuma pendência bloqueando a conclusão desta task: `firestore.rules` cobre todas as coleções do
  escopo, com deny-by-default, e todos os testes (positivos, negativos e cross-tenant) passam no
  emulador real.
- TASK-031 (Storage Security Rules) e TASK-032 (App Check) continuam pendentes, como já esperado pela
  ordem do backlog.

## Evidências

- `firestore.rules` (raiz do repositório).
- `firestore-tests/firestore.rules.test.js` e saída do comando `firebase emulators:exec --only
  firestore "npm --prefix firestore-tests test"` (32/32 testes passando, reproduzida na seção
  "Resultado dos testes" acima).

## Commit

Pendente de execução no fluxo desta task (ver seção "Push"/"Hash do commit" na resposta final).

## Push

Autorizado nesta rodada; executado após o commit.

## Hash do commit

Ver resposta final da task (preenchido após `git commit` real).

## Branch

`main`

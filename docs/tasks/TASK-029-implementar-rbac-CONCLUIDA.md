# TASK-029 — Concluída (2026-08-22)

## Resumo

Implementado o RBAC (Role-Based Access Control) configurável do VestiPro (`tasks.md`, seção 3.3):
uma matriz de permissões (`Capability` x `SystemRoleName`) validada em duas camadas — UI (oculta/
desabilita ação) e backend (contrato documentado para TASK-030, ainda a implementar como Cloud
Function/Firestore Security Rule) — mais um `PermissionService` reutilizável, um
`AuthorizationGuard` para rotas `go_router` e um `PermissionBuilder` para ações de UI.

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task).

## Arquivos criados

- `lib/core/permissions/capability.dart`
- `lib/core/permissions/role_permission_matrix.dart`
- `lib/core/permissions/permission_service.dart`
- `lib/core/permissions/permission_builder.dart`
- `lib/core/permissions/permissions.dart`
- `lib/core/navigation/authorization_guard.dart`
- `lib/core/navigation/permission_authorization_guard.dart`
- `test/core/permissions/role_permission_matrix_test.dart`
- `test/core/permissions/permission_service_test.dart`
- `test/core/permissions/permission_builder_test.dart`
- `test/core/navigation/permission_authorization_guard_test.dart`

## Arquivos alterados

- `lib/core/navigation/navigation.dart` — exporta os dois novos arquivos de guard.
- `lib/app/injection.config.dart` — regenerado via `build_runner` para registrar `PermissionService`
  como `@lazySingleton`.
- `docs/tasks/TASKS.md` — checkbox da TASK-029 marcado e `Progresso: 29 / 220`.

## Arquitetura utilizada

- `Capability` (enum, `core/permissions/capability.dart`): 22 ações administrativas sensíveis
  cobrindo clientes, catálogo/preço, pedidos, descontos, estoque, finanças, usuários/roles/equipes/
  empresas/filiais, configurações e relatórios. Cada valor documenta, via `CapabilityCode.code`
  (`resource.action`), qual regra/Function a TASK-030 deve validar de forma independente.
- `RolePermissionMatrix` (`core/permissions/role_permission_matrix.dart`): tabela única e auditável
  `SystemRoleName -> Set<Capability>` — nenhum outro ponto do app decide isso via `if/else`
  espalhado. `OWNER` é resolvido como `Capability.values` inteiro (garantia estrutural, não
  enumeração manual), `ADMIN` é `Capability.values` menos `organizationTransferOwnership` (garante
  `OWNER` superset de `ADMIN` por construção). `READ_ONLY` é o conjunto vazio. Custom roles (fora de
  `SystemRoleName`) resolvem para conjunto vazio (default-deny) — `Role` ainda não persiste lista de
  capabilities própria, isso é explicitamente apontado como trabalho futuro no docstring da classe.
- `PermissionService` (`core/permissions/permission_service.dart`, `@lazySingleton`): API
  `resolveCapabilities`/`hasPermission`/`hasAnyPermission`, resolvendo sempre a partir do
  `Membership` real do usuário via `MembershipRepository.getByUser` (nunca do `organizationId`/role
  que o cliente afirma). `Membership` com `MembershipStatus.inactive`, ou inexistente
  (`NotFoundFailure`), resolvem para conjunto vazio; qualquer outra falha do repositório propaga
  como `AppFailure`, permitindo o chamador distinguir "negado" de "não foi possível verificar".
- `AuthorizationGuard` (`core/navigation/authorization_guard.dart`): contrato
  `FutureOr<String?> redirect(context, state, {required Capability requiredCapability})`, seguindo o
  mesmo padrão de extension point de `AuthGuard`/`ActiveOrganizationGuard` já existentes (interface +
  stub `AlwaysAllowAuthorizationGuard`). Diferente dos outros dois guards (compartilhados
  globalmente por `AppRouter`), este é amarrado por rota individual (`GoRoute.redirect`), já que cada
  rota administrativa exige uma capability diferente — não há, ainda, nenhuma rota real protegida
  por capability no `AppRouter` (isso só chega a partir da TASK-042, telas administrativas), então
  `AppRouter` não foi alterado nesta task.
- `PermissionAuthorizationGuard` (`core/navigation/permission_authorization_guard.dart`):
  implementação real do guard acima, usando `AuthRepository.currentUser` (sessão) +
  `state.pathParameters['orgId']` + `PermissionService.hasPermission`. Fail-closed: sem sessão, sem
  `orgId` ou falha na resolução sempre redirecionam para `ForbiddenRoute`.
- `PermissionBuilder` (`core/permissions/permission_builder.dart`): widget `FutureBuilder`-based,
  contraparte de UI do guard — mostra `builder(context, false)` (ou `placeholderBuilder`) enquanto
  carrega/falha, e só `true` quando `PermissionService` confirma a capability.
- DI: `PermissionService` registrado via `@lazySingleton` (injectable/get_it), resolvendo
  `MembershipRepository` já registrado desde a TASK-028 — sem uso de `GetIt.instance` direto em
  regra de negócio. Os guards não são registrados via `@injectable`, mantendo a mesma convenção de
  `SessionAuthGuard`/`AuthGuard`/`ActiveOrganizationGuard` (guards são construídos explicitamente
  onde usados, não resolvidos globalmente pelo container).

## Regras de negócio implementadas

- Matriz de permissões configurável por role, testada para os 7 perfis (`OWNER`, `ADMIN`,
  `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`).
- `OWNER` é sempre superset estrito de `ADMIN` (garantido estruturalmente, não apenas testado).
- `READ_ONLY` nunca tem nenhuma capability (testado para todas as 22 capabilities, não apenas por
  omissão).
- Troca de role é refletida na próxima verificação sem cache: `PermissionService` não guarda estado
  entre chamadas — cada `hasPermission`/`hasAnyPermission` relê o `Membership` atual via
  `MembershipRepository`, eliminando por design o risco de invalidação incorreta.
- Membership inativo (`MembershipStatus.inactive`) nunca concede capability, mesmo para `OWNER`.

## Regras Firebase implementadas

Nenhuma nesta task — é escopo explícito da TASK-030 (Firestore Security Rules) e de Cloud Functions
futuras. Esta task deixa o contrato documentado: cada `Capability.code` (`resource.action`) é o nome
que a regra/Function correspondente deve validar de forma independente, nunca confiando no resultado
client-side do `PermissionService`. Isso está documentado nos docstrings de `Capability`,
`PermissionService` e `AuthorizationGuard`.

## Analytics implementado

Nenhum evento novo nesta task (task de infraestrutura de segurança, sem tela/ação de usuário final
ainda wireada). Nenhuma regressão nos eventos existentes.

## Crashlytics implementado

Nenhuma mudança — `PermissionService`/guards não capturam exceções silenciosamente; falhas de
`MembershipRepository` propagam como `Failure` tipado, sem `print` nem supressão de erro.

## Impacto offline

`PermissionService` depende de `MembershipRepository.getByUser`, cujo comportamento offline (cache
local/Drift, se houver) é responsabilidade da TASK-028/implementação de sync — não alterado aqui.
Uma falha de conectividade ao resolver o Membership propaga como `AppFailure`, e tanto
`PermissionAuthorizationGuard` quanto `PermissionBuilder` tratam essa falha como "negado" (fail
closed), nunca como "permitido por padrão".

## Impacto multi-tenant

Toda resolução de permissão exige `organizationId` explícito e passa por
`MembershipRepository.getByUser(organizationId, userId)` — nunca infere a organização ativa nem
confia em um `organizationId` fora desse caminho. Nenhuma query nova foi criada sem escopo de tenant.

## Testes criados

- `role_permission_matrix_test.dart`: matriz completa por role (positivo/negativo), superset
  OWNER/ADMIN, invariante `READ_ONLY` vazio para as 22 capabilities, auditabilidade
  (`capabilitiesFor` determinístico), resolução por código de role bruto (`capabilitiesForRoleName`)
  e default-deny para role customizado desconhecido.
- `permission_service_test.dart`: `hasPermission`/`hasAnyPermission` para role sem Membership,
  Membership inativo, falha de repositório propagada, `READ_ONLY` sempre falso para todas as
  capabilities, e teste explícito de que uma promoção de role é refletida imediatamente na próxima
  chamada (sem cache obsoleto).
- `permission_builder_test.dart`: branch concedido, branch negado, fail-closed em falha do serviço,
  e `placeholderBuilder` durante o carregamento.
- `permission_authorization_guard_test.dart`: teste de integração leve com `GoRouter` real — permite
  navegação quando a capability é concedida, redireciona para `ForbiddenRoute` quando negada, quando
  não há sessão, e quando o `PermissionService` falha (fail-closed).

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/permissions test/core/navigation/permission_authorization_guard_test.dart
dart format --set-exit-if-changed lib/core/permissions lib/core/navigation test/core/permissions test/core/navigation lib/app/injection.config.dart
flutter analyze
flutter test
```

## Resultado do formatter

`dart format` reformatou 5 arquivos recém-criados na primeira passada (espaçamento padrão) e não
alterou mais nada na segunda verificação — sem exit code de erro.

## Resultado do analyzer

`flutter analyze` → "No issues found! (ran in 5.9s)".

## Resultado dos testes

`flutter test` (suíte completa) → "All tests passed!" (632 testes, incluindo os 29 novos desta task:
14 da matriz, 10 do `PermissionService`, 4 do `PermissionBuilder` e 4 do `PermissionAuthorizationGuard`
— a contagem exata por arquivo está nos logs de execução).

## Decisões técnicas

- `core/permissions` depende diretamente de `features/organizations/domain` (`Membership`,
  `MembershipRepository`, `MembershipStatus`, `SystemRoleName`) — decisão deliberada, já que o
  próprio enunciado da task exige resolver permissões "a partir do Membership/role ativo do usuário
  na organização corrente". Não há teste de arquitetura no repositório proibindo essa direção (o
  único boundary test existente restringe imports em `features/organizations/domain`, não em
  `core`), e a dependência é unidirecional e documentada.
- `PermissionService` não implementa cache algum — decisão deliberada para satisfazer trivialmente a
  regra "nunca cache indefinido sem invalidação": sem cache, não há invalidação para acertar ou
  errar. Se uma camada de cache for adicionada no futuro (ex.: para reduzir leituras Firestore
  repetidas), ela precisará invalidar em toda troca de role, replicando o teste já escrito aqui.
- `AuthorizationGuard` não foi amarrado ao `_redirect` global do `AppRouter` (diferente de
  `AuthGuard`/`ActiveOrganizationGuard`): permissão é inerentemente por-rota (cada rota exige uma
  capability diferente), então o padrão adotado é `GoRoute(redirect: (c, s) =>
  guard.redirect(c, s, requiredCapability: ...))` por rota administrativa individual, a partir da
  TASK-042 em diante. Isso segue o mesmo precedente já estabelecido pelo próprio `ActiveOrganizationGuard`
  (ainda stub, real só na TASK-037): criar o contrato + implementação real e testável agora, sem
  forçar a integração em uma tela que ainda não existe.
- A matriz de capabilities por role (`SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`) foi
  definida com julgamento de arquiteto a partir do padrão de força de vendas B2B descrito em
  `tasks.md`, já que a especificação não detalha capability-a-capability por perfil — ver
  "Pendências" abaixo.

## Riscos conhecidos

- A distribuição exata de capabilities entre `SALES_MANAGER`/`SALES_REP`/`SALES_ASSISTANT`/`FINANCE`
  é uma primeira versão razoável, não uma decisão de negócio validada por
  `vestipro-commercial-ops-strategist`/`vestipro-sales-representative-specialist` (não exigidos pelo
  arquivo da task, que lista apenas `flutter-senior-architect`). Times de produto podem querer
  ajustar `role_permission_matrix.dart` — a estrutura/testes já cobrem esse ajuste sem exigir
  redesenho.
- `PermissionAuthorizationGuard`/`PermissionBuilder` ainda não estão wireados em nenhuma tela real
  (não há rota administrativa protegida por capability no `AppRouter` hoje) — uso real começa a
  partir da TASK-042.
- Roles customizadas (não-sistema) resolvem sempre para conjunto vazio; suportar capabilities
  configuráveis por role customizada exigirá estender `Role` (hoje sem esse campo) em task futura.

## Pendências

- TASK-030 (Firestore Security Rules) deve implementar, para cada `Capability` sensível listada
  aqui, a validação server-side equivalente, usando `Capability.code` como referência de nomeação.
- Wiring de `PermissionAuthorizationGuard`/`PermissionBuilder` em rotas/telas administrativas reais
  (TASK-042 em diante).
- Revisão de produto/negócio da matriz de capabilities por role (ver "Riscos conhecidos").

## Evidências

- `flutter analyze`: "No issues found!".
- `flutter test`: "All tests passed!" (632 testes).

## Commit

Único commit incluindo código de produção, testes, `injection.config.dart` regenerado e atualização
de `docs/tasks/TASKS.md`.

## Push

Sim (autorizado nesta rodada).

## Hash do commit

Ver saída de `git log -1` após o commit nesta mesma execução.

## Branch

main

# TASK-033 — Concluída (2026-08-23)

## Resumo

Implementada a coleção central de auditoria administrativa `auditLogs`, imutável e escopada por
tenant, em `organizations/{organizationId}/auditLogs/{logId}` (`tasks.md`, seções 13 e 20). Criada a
feature `lib/features/audit_log/` (entidade `AuditLogEntry`, catálogo `AuditAction`, contrato
`AuditLogRepository`, use cases `RecordAuditLogUseCase`/`ListAuditLogEntriesUseCase`, DTO, mapper,
datasource Firestore e repositório), a nova capability RBAC `Capability.auditLogView`
(`audit.log.view`, concedida automaticamente a `OWNER`/`ADMIN`) e a integração real com
`AssignRoleToUserUseCase` (TASK-028/029), que agora grava uma entrada `role.changed` a cada troca de
role bem-sucedida. `firestore.rules` passou a tornar `auditLogs` append-only (permite `create` do
próprio ator, nega `update`/`delete` para qualquer papel, inclusive `OWNER`), com 10 novos testes
positivos/negativos no Firebase Emulator Suite (42/42 passando).

## Agentes utilizados

- `flutter-senior-architect` (único exigido pela task).

## Arquivos criados

- `lib/features/audit_log/domain/value_objects/audit_action.dart` — catálogo padronizado de ações
  auditáveis (`AuditAction` + `.code`), evitando strings mágicas espalhadas.
- `lib/features/audit_log/domain/entities/audit_log_entry.dart` (+ `.freezed.dart` gerado) —
  entidade imutável `AuditLogEntry`.
- `lib/features/audit_log/domain/audit_log_entry_factory.dart` — fábrica pura
  (`AuditLogEntryFactory.build`) que gera `id`/`timestamp` e sanitiza `previousValue`/`newValue`
  (remove `password`, `senha`, `token`, `secret`, `apikey`, `creditcard`, `cpf`, `cnpj`, entre
  outras chaves sensíveis, case-insensitive). Compartilhada por `RecordAuditLogUseCase` e por
  `AssignRoleToUserUseCase` (organizations), evitando duplicar a lógica de saneamento.
- `lib/features/audit_log/domain/repositories/audit_log_repository.dart` — contrato
  `AuditLogRepository` com apenas `record`/`listByOrganization` (sem `update`/`delete`).
- `lib/features/audit_log/domain/usecases/record_audit_log_use_case.dart` — valida e grava uma
  entrada via `AuditLogEntryFactory` + `AuditLogRepository.record`.
- `lib/features/audit_log/domain/usecases/list_audit_log_entries_use_case.dart` — lista o audit log
  com RBAC (checa `Capability.auditLogView` via `PermissionService` antes de delegar ao
  repositório).
- `lib/features/audit_log/data/dtos/audit_log_entry_dto.dart` — shape Firestore de
  `auditLogs/{id}`.
- `lib/features/audit_log/data/mappers/audit_log_entry_mapper.dart` — DTO ⇄ entidade,
  incluindo `actionToEntity`/`actionToDto`.
- `lib/features/audit_log/data/datasources/audit_log_data_source.dart` +
  `firestore_audit_log_data_source.dart` — implementação Firestore via
  `FirestoreCollectionDataSource<AuditLogEntryDto>` (sem `update`/`softDelete`, só `set`/`getPage`).
- `lib/features/audit_log/data/repositories/audit_log_repository_impl.dart` — implementação real do
  contrato.
- `lib/features/audit_log/audit_log.dart` — barrel público da feature.
- Testes (todos novos): `test/features/audit_log/domain/domain_import_boundary_test.dart`,
  `entities/audit_log_entry_test.dart`, `value_objects/audit_action_test.dart`,
  `audit_log_entry_factory_test.dart`, `usecases/record_audit_log_use_case_test.dart`,
  `usecases/list_audit_log_entries_use_case_test.dart`,
  `data/dtos/audit_log_entry_dto_test.dart`, `data/mappers/audit_log_entry_mapper_test.dart`,
  `data/repositories/audit_log_repository_impl_test.dart`.

## Arquivos alterados

- `lib/core/permissions/capability.dart` — novo `Capability.auditLogView` (`audit.log.view`);
  automaticamente concedido a `OWNER` (superset de `Capability.values`) e a `ADMIN` (todas exceto
  `organizationTransferOwnership`), sem exigir alteração em `RolePermissionMatrix`.
- `lib/features/organizations/domain/usecases/assign_role_to_user_use_case.dart` — passou a exigir
  `actorName` e a gravar uma entrada `AuditAction.roleChanged` (via `AuditLogRepository` +
  `AuditLogEntryFactory`) após cada criação/atualização de Membership bem-sucedida; propaga a
  falha da gravação de auditoria em vez de descartá-la silenciosamente.
- `test/features/organizations/domain/usecases/assign_role_to_user_use_case_test.dart` — atualizado
  para o novo parâmetro `actorName`, mock de `AuditLogRepository` e novos casos (entrada capturada
  com `previousValue`/`newValue` corretos, nenhuma gravação quando a mutação falha, e propagação de
  falha quando a própria gravação de auditoria falha).
- `firestore.rules` — novo bloco `match /auditLogs/{logId}`: `read` exige
  `hasCapability(organizationId, 'audit.log.view')`; `create` exige membro ativo e
  `actorUserId == request.auth.uid` (nunca em nome de outro usuário); `update`/`delete` sempre
  `false`, para qualquer papel.
- `firestore.indexes.json` — índice composto `auditLogs` (`action` ASC + `timestamp` DESC), exigido
  pela combinação de filtro por ação + ordenação por timestamp em `listByOrganization`.
- `firestore-tests/firestore.rules.test.js` — fixture `auditLogDoc(...)` e novo `describe`
  `organizations/{organizationId}/auditLogs/{logId}` com 10 testes.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) com os novos
  providers (`AuditLogEntryMapper`, `AuditLogDataSource`/`FirestoreAuditLogDataSource`,
  `AuditLogRepository`/`AuditLogRepositoryImpl`, `RecordAuditLogUseCase`,
  `ListAuditLogEntriesUseCase`) e a nova dependência de `AssignRoleToUserUseCase`.
- `docs/tasks/TASKS.md` — checkbox da TASK-033 marcado e `Progresso` atualizado para `33 / 220`.

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo exatamente o padrão já usado por
`lib/features/organizations/`: `domain/entities` (freezed) → `domain/repositories` (contrato,
sem `update`/`delete`) → `domain/usecases` → `data/dtos` + `data/mappers` → `data/datasources`
(compondo `FirestoreCollectionDataSource<T>` genérico, nunca `cloud_firestore` direto) →
`data/repositories` (impl injetável via `@LazySingleton`/`@injectable`).

Decisão de desenho relevante: `AssignRoleToUserUseCase` (feature `organizations`) depende
diretamente de `AuditLogRepository` (interface) e da fábrica pura `AuditLogEntryFactory` — não de
`RecordAuditLogUseCase` (classe `final`) — porque `final class` não pode ser mockada
(`extends Mock implements ...`) fora da própria library em Dart. Reutilizar a fábrica evita
duplicar a lógica de saneamento/geração de id sem introduzir uma dependência não-testável entre
use cases de features diferentes.

## Regras de negócio implementadas

- `AuditLogEntry` é imutável: nenhum campo é alterado após a criação; o contrato
  `AuditLogRepository` nunca expõe `update`/`delete`.
- Catálogo padronizado `AuditAction` (`role.changed`, `user.invited`, `user.deactivated`,
  `user.deleted`, `company.deleted`, `branch.deleted`, `team.deleted`, `role.deleted`,
  `organization.settingsUpdated`) — nenhuma feature grava uma string livre como ação.
- Toda troca de role bem-sucedida (`AssignRoleToUserUseCase`, TASK-028/029) gera uma entrada
  `role.changed` com `previousValue`/`newValue` (`{roleId, roleName}`); quando é a primeira
  atribuição (Membership criado agora), `previousValue` é `null`.
- `previousValue`/`newValue` nunca armazenam chaves sensíveis: `AuditLogEntryFactory` remove
  `password`, `senha`, `token`, `secret`, `apikey`/`api_key`, `creditcard`/`credit_card`, `cpf`,
  `cnpj` (case-insensitive), sem nunca mutar o mapa original.
- Leitura do audit log respeita RBAC: `ListAuditLogEntriesUseCase` verifica
  `Capability.auditLogView` via `PermissionService` (hoje, apenas `OWNER`/`ADMIN`) antes de
  delegar ao repositório — quem não tem a capability nunca chega a consultar o Firestore.
- Se a gravação da entrada de auditoria falhar, `AssignRoleToUserUseCase` propaga essa falha em vez
  de descartá-la silenciosamente (`tasks.md`, seção 13: "nenhuma [ação sensível] pode passar em
  silêncio") — ver limitação conhecida abaixo sobre a mutação e o log não serem atômicos hoje.

## Regras Firebase implementadas

- `firestore.rules`, bloco `organizations/{organizationId}/auditLogs/{logId}`:
  - `read`: exige `hasCapability(organizationId, 'audit.log.view')` (mesma função
    `roleHasCapability` já usada pelas demais coleções — `OWNER` sempre `true`, `ADMIN` sempre
    `true` exceto `organization.transferOwnership`; nenhum outro papel do sistema tem essa
    capability hoje).
  - `create`: exige `isActiveMember(organizationId)`, `organizationId` do payload igual ao da
    path, e `actorUserId == request.auth.uid` — impossível registrar uma ação em nome de outro
    usuário (impersonação).
  - `update`/`delete`: sempre `false`, para qualquer papel, incluindo `OWNER` — append-only real,
    não apenas por convenção do cliente.
- `firestore.indexes.json`: índice composto `auditLogs` (`action` ASC, `timestamp` DESC), necessário
  para consultas que filtram por `action` e ordenam por `timestamp` simultaneamente.

## Analytics implementado

Nenhum evento de Analytics novo nesta task (fora do escopo pedido — a task não lista evento de
analytics entre os critérios de aceite). Nenhum log/print com dado sensível foi adicionado.

## Crashlytics implementado

N/A — nenhuma tela nem fluxo assíncrono complexo novo que precise de captura de erro dedicada; as
falhas seguem o padrão já existente (`AppResult`/`Failure`) de todo o resto do domínio.

## Impacto offline

Nenhuma mudança na infraestrutura de Outbox/sync existente. Como `AuditLogRepository`/
`AssignRoleToUserUseCase` fazem uma escrita Firestore direta (mesmo padrão client-side já usado por
`AssignRoleToUserUseCase` antes desta task, que ainda não passa pelo Outbox), a gravação da
auditoria segue exatamente a mesma característica online/offline que a troca de role já tinha: sem
conectividade, a chamada falha como qualquer outra escrita Firestore direta hoje — não há
regressão. Registrado como pendência de melhoria futura (ver "Riscos conhecidos").

## Impacto multi-tenant

Toda leitura/escrita de `auditLogs` é escopada por `organizationId` desde o path (Firestore Rules
releem sempre o Membership real do path, nunca um campo do payload) — mesmo princípio de isolamento
já usado por `companies`/`branches`/`roles`/`teams`/`members`. Testado explicitamente no Emulator:
um `OWNER` da Org A nunca lê nem escreve na `auditLogs` da Org B, mesmo tentando declarar o
`organizationId` da Org B no payload.

## Testes criados

- Domain: `audit_log_entry_test.dart` (equalidade por valor, `copyWith` sem mutar o original,
  `previousValue`/`newValue` opcionais), `audit_action_test.dart` (códigos únicos e estáveis),
  `audit_log_entry_factory_test.dart` (geração de id/timestamp, saneamento de chaves sensíveis
  case-insensitive, não mutação do mapa original), `domain_import_boundary_test.dart` (domain sem
  Flutter/Firebase/Drift).
- Use cases: `record_audit_log_use_case_test.dart` (grava com dados corretos, saneia antes de
  persistir, `ValidationFailure` sem chamar o repositório, propaga falha do repositório),
  `list_audit_log_entries_use_case_test.dart` (OWNER recebe entradas; SALES_REP e usuário sem
  Membership são negados sem nunca chegar ao repositório; `ValidationFailure` para campos em
  branco).
- Data: `audit_log_entry_dto_test.dart` (parsing completo/parcial, `toJson` nunca inclui `id`,
  `ValidationException` para payload inválido), `audit_log_entry_mapper_test.dart` (round-trip
  DTO ⇄ entidade, resolução de todo `AuditAction` a partir do código persistido),
  `audit_log_repository_impl_test.dart` (sucesso, isolamento por organização, filtro por ação,
  mapeamento de exceções para `Failure`).
- `assign_role_to_user_use_case_test.dart` (atualizado): entrada de auditoria capturada com
  `previousValue`/`newValue` corretos tanto na criação quanto na atualização de Membership; nenhuma
  gravação quando a mutação falha; falha da gravação de auditoria propagada mesmo com a mutação já
  bem-sucedida.
- `firestore-tests/firestore.rules.test.js` (10 novos testes): `create` permitido para membro ativo
  sobre si mesmo; negado ao forjar `actorUserId`; negado sem Membership; negado sem autenticação;
  negado ao forjar `organizationId` cross-tenant; `read` permitido para `OWNER`
  (`audit.log.view`) e negado para `SALES_REP`; negado cross-tenant; `update`/`delete` sempre
  negados, mesmo para `OWNER`.

## Comandos executados

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd firestore-tests && npm install   # (node_modules já existia, sem novas dependências)
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
git status --porcelain=v1
```

## Resultado do formatter

```text
Formatted 405 files (0 changed) in 1.67 seconds.
```

## Resultado do analyzer

```text
Analyzing VestiPro...
No issues found! (ran in 10.6s)
```

## Resultado dos testes

`flutter test` (suíte completa, após corrigir uma comparação de `DateTime`/`Timestamp` sensível a
timezone no teste do DTO):

```text
00:23 +678: All tests passed!
```

`firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`:

```text
Test Suites: 1 passed, 1 total
Tests:       42 passed, 42 total
Snapshots:   0 total
Time:        3.833 s
```

(32 testes já existentes da TASK-030 + 10 novos de `auditLogs`, todos passando no Firestore
Emulator real.)

## Decisões técnicas

- **`AuditLogEntryFactory` como fábrica pura, não método de `RecordAuditLogUseCase`**: precisava
  ser reutilizável por `AssignRoleToUserUseCase` (feature `organizations`) sem forçar essa segunda
  feature a depender de uma classe `final` de outra feature (mocktail não consegue
  `extends Mock implements` uma `final class` fora da própria library). Manter a lógica de
  id/timestamp/saneamento em uma função estática elimina a duplicação sem introduzir uma
  dependência não-testável.
- **Registro client-side, documentado como limitação com plano de migração**: a task pede
  "preferencialmente Cloud Functions"; como `AssignRoleToUserUseCase` (e todo o onboarding de
  Organization) já roda 100% client-side hoje — precedente explícito em
  `firestore.rules`/TASK-030 —, gravar a auditoria no mesmo use case, imediatamente após a mutação
  bem-sucedida, é consistente com o padrão já estabelecido no repositório e evita introduzir uma
  peça de infraestrutura (trigger Firestore/Cloud Function) fora do escopo desta task. A limitação
  e o plano de migração estão documentados nos comentários de `RecordAuditLogUseCase` e
  `AssignRoleToUserUseCase`.
- **`Capability.auditLogView` sem alterar `RolePermissionMatrix`**: como `_ownerCapabilities` é
  `Set(Capability.values)` e `_adminCapabilities` é "todas exceto
  `organizationTransferOwnership`", adicionar o valor ao enum já concede a capability a
  `OWNER`/`ADMIN` automaticamente, sem tocar na tabela — e sem conceder a nenhum outro papel, que
  segue defalt-deny.
- **Paginação sem expor tipo do Firestore no domain**: `AuditLogRepository.listByOrganization`
  usa `before: DateTime?` (não `DocumentSnapshot`) como cursor — a página seguinte é "toda entrada
  com `timestamp` estritamente anterior ao último item da página atual" — preservando a regra de
  que `domain/` nunca importa `cloud_firestore`.
- **`id`/`timestamp` client-side (`Uuid v4` + `DateTime.now().toUtc()`)**: mesmo padrão de
  `createdAt`/`updatedAt` já usado por `Membership`/`Company`/`Organization` neste repositório
  (nenhuma entidade hoje usa `FieldValue.serverTimestamp()`); mantém consistência em vez de
  introduzir um padrão novo isolado só para `auditLogs`.

## Riscos conhecidos

- **Escrita da Membership e do log de auditoria não são atômicas**: `AssignRoleToUserUseCase`
  primeiro muta o `Membership`, só depois grava o `AuditLogEntry`; se a segunda escrita falhar
  (rede, permissão), o `Membership` já foi alterado no Firestore mas a auditoria retorna falha ao
  chamador. Não há transação/batch cobrindo as duas coleções hoje. Mitigação futura recomendada:
  mover a troca de role para uma Cloud Function que escreva `Membership` + `AuditLogEntry` na
  mesma transação/batch (ou um trigger Firestore que observe a escrita em `members/{userId}` e
  grave a auditoria server-side, eliminando a dependência do cliente completar as duas chamadas).
- **Ainda depende do cliente para não "esquecer" de auditar**: como a gravação roda a partir do
  próprio use case (não de um trigger/Function), um bug futuro em outro caminho de código que
  escreva `Membership` diretamente (sem passar por `AssignRoleToUserUseCase`) não geraria
  automaticamente uma entrada de auditoria. As Firestore Rules cobrem isolamento/imutabilidade,
  não "toda escrita sensível terá um log automaticamente" — esse gap só se fecha com uma Cloud
  Function/trigger dedicada (mesma pendência já registrada na TASK-030 para o bootstrap de
  Organization).
- **Ainda não populado para as demais ações do catálogo**: `user.invited`, `user.deactivated`,
  `user.deleted`, `company.deleted`, `branch.deleted`, `team.deleted`, `role.deleted` e
  `organization.settingsUpdated` já existem no catálogo `AuditAction` e nas Firestore Rules
  (formato genérico, não específico de `role.changed`), mas nenhum use case atual os grava ainda
  porque — na data desta task — não existe use case de deleção de Company/Branch/Team/Role, nem de
  desativação de usuário, nem de update de settings integrado à auditoria (esses caminhos passam a
  existir só a partir de TASK-042/043/046 e outras tasks futuras do backlog). Quando essas tasks
  criarem os respectivos use cases, cada uma deve integrar `AuditLogRepository`/
  `AuditLogEntryFactory` do mesmo jeito que `AssignRoleToUserUseCase` faz aqui.
- **`actorName` depende de quem chama fornecer um snapshot correto**: como não existe hoje uma
  coleção de perfil de usuário (`users/{uid}` com `displayName`) no schema modelado, `actorName` é
  responsabilidade do caller (ex.: a tela que chamar `AssignRoleToUserUseCase` deve passar o
  `SessionUser.displayName` do ator autenticado). Nenhuma tela consome isso ainda (é TASK-042/043,
  fora do escopo desta task), então esse contrato só será exercitado de fato quando essas telas
  existirem.

## Pendências

- Migrar a gravação de auditoria de client-side para uma Cloud Function/trigger dedicada (fecha o
  gap de atomicidade e de "nunca esquecer de auditar" descrito acima) — não é bloqueante para esta
  task, mas é a recomendação explícita registrada nos comentários de código.
- Integrar `AuditLogRepository`/`AuditLogEntryFactory` aos futuros use cases de
  desativação/exclusão de usuário, empresa, filial, papel e atualização de configurações da
  Organization, conforme cada um for implementado pelo backlog (TASK-042 em diante).
- Nenhuma tela de auditoria (`docs/tasks/TASK-047-implementar-tela-de-auditoria-de-acessos.md`)
  foi criada nesta task — está fora do escopo de TASK-033 (que é EPIC-03/segurança) e é tratada
  por uma task própria mais adiante no backlog, que deve consumir
  `ListAuditLogEntriesUseCase`/`AuditLogEntry` já prontos aqui.

## Evidências

- `lib/features/audit_log/` (feature completa) e `lib/features/organizations/domain/usecases/assign_role_to_user_use_case.dart`.
- `firestore.rules` (bloco `auditLogs`) e `firestore-tests/firestore.rules.test.js` (describe
  `organizations/{organizationId}/auditLogs/{logId}`).
- Saída de `flutter test` (`00:23 +678: All tests passed!`) e de
  `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` (`42 passed, 42
  total`), reproduzidas nas seções "Resultado dos testes" acima.

## Commit

Ver resposta final da task (preenchido após `git commit` real).

## Push

Não autorizado nesta rodada — apenas `git commit` local, conforme instrução explícita recebida.

## Hash do commit

Ver resposta final da task (preenchido após `git commit` real).

## Branch

`main`

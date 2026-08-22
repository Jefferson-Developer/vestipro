# TASK-026 — Concluída (2026-08-22)

## Resumo

Modelada a entidade `Organization` como tenant raiz do multi-tenancy do VestiPro (`tasks.md`,
seção 3.1), em `lib/features/organizations/` seguindo Clean Architecture feature-first: entidade
imutável (`Organization`, `freezed`), value objects (`OrganizationSettings` com validação,
`OrganizationStatus`), contrato de repositório deliberadamente restrito (`create`, `getById`,
`updateSettings` — sem `update` genérico, para que nada consiga reescrever `id`), três casos de
uso (`CreateOrganizationUseCase`, `GetOrganizationUseCase`, `UpdateOrganizationSettingsUseCase`)
e a implementação de dados com Firestore: DTOs próprios (`OrganizationDto`,
`OrganizationSettingsDto`), mapper, um datasource Firestore dedicado
(`FirestoreOrganizationDataSource`, para a raiz `organizations/{id}`, distinto do
`FirestoreCollectionDataSource` genérico que só serve subcoleções sob um tenant) e
`OrganizationRepositoryImpl`. A criação é idempotente: `create` usa uma transação Firestore que
lê o documento antes de escrever e, se ele já existir (retry após falha de rede), devolve o que já
está lá em vez de sobrescrever ou falhar com conflito — preparando o terreno para a TASK-037. Esta
é a primeira feature do repositório a de fato usar o Firestore em runtime (até aqui só a
infraestrutura genérica existia, sem nenhum consumidor).

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `lib/features/organizations/domain/entities/organization.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/value_objects/organization_settings.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/value_objects/organization_status.dart`
- `lib/features/organizations/domain/repositories/organization_repository.dart`
- `lib/features/organizations/domain/usecases/create_organization_use_case.dart`
- `lib/features/organizations/domain/usecases/get_organization_use_case.dart`
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart`
- `lib/features/organizations/data/dtos/organization_dto.dart`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/organizations/data/datasources/organization_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_organization_data_source.dart`
- `lib/features/organizations/data/repositories/organization_repository_impl.dart`
- `lib/features/organizations/organizations.dart` (barrel do público da feature)
- `test/features/organizations/domain/entities/organization_test.dart`
- `test/features/organizations/domain/value_objects/organization_settings_test.dart`
- `test/features/organizations/domain/domain_import_boundary_test.dart`
- `test/features/organizations/domain/usecases/create_organization_use_case_test.dart`
- `test/features/organizations/domain/usecases/get_organization_use_case_test.dart`
- `test/features/organizations/domain/usecases/update_organization_settings_use_case_test.dart`
- `test/features/organizations/data/mappers/organization_mapper_test.dart`
- `test/features/organizations/data/repositories/organization_repository_impl_test.dart`
- `test/features/organizations/data/datasources/firestore_organization_data_source_test.dart`
- `docs/tasks/TASK-026-modelar-organization-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/app/injection.config.dart` — regenerado pelo `build_runner` (injectable) para registrar
  `OrganizationMapper`, `FirestoreOrganizationDataSource` (`as: OrganizationDataSource`),
  `OrganizationRepositoryImpl` (`as: OrganizationRepository`) e os três casos de uso no container
  de DI.
- `docs/tasks/TASKS.md` — checkbox da TASK-026 marcado e progresso atualizado para 26/220.

Nenhum outro arquivo pré-existente foi alterado. `lib/core/navigation/active_organization_guard.dart`
comenta explicitamente que TASK-026 **e** TASK-037 juntas substituirão o guard-stub — como a
TASK-037 (criação da primeira Organization no onboarding, com sessão/rota reais) ainda não existe,
optei por não tocar no guard agora: religar um guard real sem o fluxo de sessão/organização ativa
que o alimenta criaria uma dependência quebrada. Isso fica registrado em "Pendências" abaixo.

## Arquitetura utilizada

- Clean Architecture feature-first: `domain` (entidade/value objects/contrato/casos de uso) não
  importa Flutter, Firebase, `cloud_firestore` nem Drift — garantido por
  `domain_import_boundary_test.dart`, no mesmo formato do teste já existente para
  `features/settings`.
- `OrganizationRepository` é deliberadamente estreito: só expõe `create`, `getById` e
  `updateSettings`; não há `update` genérico, então nenhum caso de uso (presente ou futuro) tem
  como reescrever `Organization.id` através do contrato.
- `FirestoreOrganizationDataSource` não reaproveita `FirestoreCollectionDataSource` (que sempre
  escreve em `organizations/{organizationId}/{collectionName}`, ou seja, subcoleções de um
  tenant): o documento de uma Organization é a **raiz** do tenant, não uma subcoleção sua, então
  o datasource acessa `firestore.collection('organizations')` diretamente, seguindo a mesma
  convenção de erro (`mapFirestoreExceptionToAppException`) e nunca expondo `Map<String, dynamic>`
  fora de `data/`.
- Padrão de camadas idêntico ao já estabelecido em `lib/features/settings` e `lib/core/auth`:
  DTO com `fromJson`/`toJson` própria validação, `Mapper` `@lazySingleton`, `RepositoryImpl`
  `@LazySingleton(as: ...)` traduzindo `AppException` → `Failure` via `AppResult`, casos de uso
  `@injectable` finos que validam entrada antes de delegar ao repositório.

## Regras de negócio implementadas

- `id` imutável: não existe nenhum caminho de código (`UpdateOrganizationSettingsUseCase`,
  `OrganizationRepository.updateSettings`, `FirestoreOrganizationDataSource.updateSettings`) que
  aceite ou grave um novo `id` — o `update` do Firestore só envia `settings`, `updatedAt` e
  `updatedBy`.
- Criação idempotente: `FirestoreOrganizationDataSource.create` roda dentro de uma transação
  Firestore (`runTransaction`) que lê o documento antes de qualquer escrita; se ele já existir,
  devolve o documento existente em vez de sobrescrevê-lo ou lançar conflito — uma retentativa de
  rede após a criação já ter sido persistida não duplica nem corrompe a Organization.
- Soft delete estrutural: `Organization.deletedAt` existe e é `null` por padrão; nenhum método do
  repositório remove fisicamente o documento (mesma convenção de `FirestoreCollectionDataSource.softDelete`,
  hoje não invocada aqui porque a exclusão de Organization está fora do escopo desta task).
- Validação de payload: `CreateOrganizationUseCase` e `UpdateOrganizationSettingsUseCase` rejeitam
  campos obrigatórios em branco e delegam a validação de `OrganizationSettings` (moeda, país,
  idioma padrão) para `OrganizationSettings.validated`, retornando `ValidationFailure` com
  `fieldErrors` sem nunca chegar a chamar o repositório/Firestore com dado inválido.

## Regras Firebase implementadas

- `FirestoreOrganizationDataSource` opera exclusivamente sobre a coleção raiz `organizations`
  (`organizations/{id}`), nunca subcoleções.
- Toda excecão do SDK (`FirebaseException`) é convertida para a hierarquia própria do app via
  `mapFirestoreExceptionToAppException` (já existente, TASK-013) — nenhuma excecão do
  `cloud_firestore` escapa de `data/`.
- Autorização real de escrita (Security Rules validando que só quem cria a Organization se torna
  `OWNER`, e que ninguém além do backend pode reescrever `id`/`createdBy`) é explicitamente escopo
  da TASK-030, não desta task — esta task só prepara a estrutura de domínio/repositório compatível
  com essa futura regra, como pedido no arquivo da task.

## Analytics implementado

Nenhum (fora de escopo — TASK-026 é modelagem de domínio/dados; o evento de criação de
Organization pertence ao fluxo de onboarding da TASK-037).

## Crashlytics implementado

Nenhum específico desta feature; exceções não tratadas continuam alcançando o `CrashReporter`
central já configurado (TASK-016), sem necessidade de instrumentação adicional aqui.

## Impacto offline

Nenhum ainda: esta task modela apenas o caminho remoto (Firestore). Persistência local/Outbox para
criação de Organization offline-first é escopo de tasks futuras de sync — o contrato de
`OrganizationRepository` foi desenhado para não impedir isso (`create` já recebe um `id` gerado
pelo chamador, pré-requisito para que uma futura entrada de Outbox reutilize o mesmo `id` em
retries).

## Impacto multi-tenant

`Organization` é o próprio tenant raiz: todo o restante do modelo multi-tenant (Company, Branch,
Team, Role, etc. — seção 3.2/20 de `tasks.md`) será escrito sob `organizations/{id}`. Nenhuma
consulta implementada aqui pode retornar mais de uma Organization simultaneamente (`getById`
sempre busca por um único `id`).

## Testes criados

- `organization_test.dart`: igualdade por valor, organizações com IDs diferentes não são iguais,
  `copyWith` não muta a instância original, `deletedAt` nulo por padrão.
- `organization_settings_test.dart`: construção validada com trim, exceção de validação por campo
  em branco (incluindo todos os campos simultaneamente).
- `domain_import_boundary_test.dart`: domínio não importa Flutter/Firebase/`cloud_firestore`/Drift.
- `create_organization_use_case_test.dart`: delegação com campos "trimados", falha de validação
  (payload obrigatório em branco e settings inválidas) sem chamar o repositório, propagação de
  falha de rede do repositório.
- `get_organization_use_case_test.dart`: sucesso com id "trimado", falha de validação para id em
  branco sem chamar o repositório, propagação de `NotFoundFailure`.
- `update_organization_settings_use_case_test.dart`: delegação sem nenhum parâmetro capaz de mudar
  `id` (`id` do resultado permanece igual ao de entrada), falha de validação para id/updatedBy em
  branco e para settings inválidas (sem chamar o repositório em nenhum dos dois casos), propagação
  de `ConflictFailure`.
- `organization_mapper_test.dart`: DTO → entidade (incluindo `deletedAt` nulo e não-nulo), exceção
  de validação para status desconhecido, `toDto` como inverso exato de `toEntity`.
- `organization_repository_impl_test.dart`: sucesso de `create`/`getById`/`updateSettings`,
  criação idempotente (duas chamadas de `create` com o mesmo id retornam a mesma Organization,
  sem o repositório alterar o que o datasource — já idempotente — devolve),
  `NotFoundFailure` quando o datasource não encontra nada, mapeamento de `AppException`/exceção
  genérica para `Failure`, e verificação de que `updateSettings` nunca pede ao datasource para
  alterar o `id`.
- `firestore_organization_data_source_test.dart`: `create` escreve quando o documento não existe;
  `create` é idempotente (retry encontra o documento já existente na transação e devolve os dados
  existentes, sem chamar `transaction.set`); `getById` retorna `null`/mapeia documento existente;
  `updateSettings` envia só `settings`/`updatedAt`/`updatedBy` no `update()` do Firestore (nunca
  `id` ou `name`) e relê o documento; mapeamento de `FirebaseException` para `AppException` em
  todos os três métodos. Usa `mocktail` sobre `FirebaseFirestore`/`CollectionReference`/
  `DocumentReference`/`DocumentSnapshot`/`Transaction`, no mesmo padrão já usado no repositório
  para mockar SDKs Firebase concretos (`test/core/functions/cloud_functions_service_test.dart`);
  os `// ignore: subtype_of_sealed_class` são necessários porque `Query`/`DocumentReference`/
  `DocumentSnapshot` do `cloud_firestore` são anotados `@sealed`.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 278 files (0 changed) in 1.05 seconds.` — sem alterações pendentes após a formatação
inicial (que ajustou 7 arquivos novos desta task para o estilo padrão).

## Resultado do analyzer

`Analyzing VestiPro... No issues found! (ran in 5.8s)`.

## Resultado dos testes

`flutter test` completo: **462 testes, todos passando** (exit code 0), incluindo os 40 testes
novos desta task (`flutter test test/features/organizations` isolado: `+40, All tests passed!`).

## Decisões técnicas

- `FirestoreOrganizationDataSource` implementa `OrganizationDataSource` diretamente sobre
  `FirebaseFirestore`, sem passar por `FirestoreCollectionDataSource`, porque esse helper genérico
  sempre escopa o caminho como `organizations/{organizationId}/{collectionName}` — inadequado para
  o próprio documento raiz `organizations/{id}`.
- Idempotência de `create` implementada com `runTransaction` (leitura + escrita atômicas) em vez de
  apenas `set(..., SetOptions(merge: false))`: um `set` simples sobrescreveria silenciosamente
  campos como `createdAt`/`createdBy` em um retry se o payload local mudasse entre tentativas; a
  transação garante que, uma vez existente, o documento nunca é reescrito por uma segunda tentativa
  de criação.
- `OrganizationSettings.validated` (factory extra ao lado do construtor `const factory`) segue o
  mesmo padrão já usado por `AppVersion.parse` (`lib/features/settings/domain/value_objects/app_version.dart`),
  evitando introduzir uma convenção nova de validação de value object.
- Datas de auditoria (`createdAt`/`updatedAt`) são geradas em `OrganizationRepositoryImpl` com
  `DateTime.now().toUtc()` no momento da chamada, sem injetar um `Clock` — não havia precedente
  desse padrão em nenhum outro repositório do projeto, e a task não pede testes de congelamento de
  tempo; os testes de repositório verificam os demais campos e o comportamento de idempotência sem
  depender do valor exato do timestamp.

## Riscos conhecidos

- A validação/autorização real de que a criação da Organization só é aceita para o `OWNER`
  legítimo (e que `createdAt`/`createdBy`/`id` não podem ser forjados pelo cliente) depende das
  Firestore Security Rules da TASK-030 — hoje nada no cliente impede uma chamada mal-intencionada a
  `create` além da validação de formato; isso é esperado e está descrito no próprio arquivo da
  task.
- `lib/core/navigation/active_organization_guard.dart` permanece com
  `AlwaysAllowActiveOrganizationGuard` (não plugado a esta feature) até a TASK-037 existir — visto
  que o comentário do arquivo já previa a substituição conjunta por TASK-026+037.

## Pendências

- Ligar `ActiveOrganizationGuard` a `OrganizationRepository`/sessão real fica para a TASK-037
  (criação da primeira Organization no onboarding), como já estava documentado no próprio guard.
- Persistência local/offline (Outbox) para criação de Organization sem rede é escopo de tasks de
  sync futuras — o contrato já é compatível (id gerado pelo chamador), mas nenhum datasource local
  foi criado nesta task.
- Firestore Security Rules específicas para `organizations/{id}` ficam para a TASK-030.

## Evidências

- `flutter test test/features/organizations` → `+40, All tests passed!`
- `flutter test` (suíte completa) → `+462, All tests passed!` (exit code 0)
- `flutter analyze` → `No issues found!`

## Commit

Criado com sucesso.

## Push

Autorizado nesta sessão.

## Hash do commit

Ver seção "Commit" após a execução do `git commit` (preenchido no fechamento desta task, nunca
inventado antes do commit real).

## Branch

`main`

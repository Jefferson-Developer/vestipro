# TASK-054 — Concluída (2026-08-24)

## Resumo

Implementado o schema local (Drift) de clientes e a lógica de seleção/carga
inicial offline: três tabelas Drift (`CustomersTable`,
`CustomerAddressesTable`, `CustomerContactsTable`) espelhando `Customer`
(TASK-048) e seus endereços/contatos embutidos (TASK-050), um `AppDatabase`
inicial (schema versão 1) com migração testada, e um novo caso de uso
(`LoadInitialCustomerOfflineDataUseCase`) que resolve — reaproveitando
`PortfolioVisibilityService` e `PortfolioAssignmentRepository` já existentes —
qual conjunto de clientes cada papel pode baixar (`SALES_REP` só a própria
carteira, `SALES_MANAGER` a carteira da equipe, `ADMIN`/`OWNER` o escopo
organizacional completo), baixa esse conjunto paginando via
`CustomerRepository.listPortfolioPage`, aplica um limite configurável
(`maxCustomers`) para não sobrecarregar o dispositivo, e substitui o cache
local por completo (carga inicial, não incremental) através de um novo
repositório `CustomerLocalStoreRepository`.

Escopo mantido deliberadamente restrito ao que a task pede: schema + seleção
de carga inicial. O motor de sincronização incremental genérico (Outbox,
cursor, conflitos) continua pertencendo a EPIC-14 (TASK-108/TASK-109) e não
foi antecipado nem duplicado aqui — apenas documentado como ponto de extensão
sobre a mesma tabela/`AppDatabase`. A troca do repositório de clientes ativo
hoje (`SharedPreferencesCustomerRepository`, usado por TASK-051/TASK-052) pelo
armazenamento Drift também não faz parte desta task — ela só prepara a base
que essas telas consultarão offline quando essa integração for feita.

## Agentes utilizados

- `flutter-senior-architect` (checklist lido; implementação de schema local,
  domínio, dados e DI feita diretamente).

## Arquivos criados

Núcleo (banco local):
- `lib/core/database/tables/customers_table.dart`
- `lib/core/database/tables/customer_addresses_table.dart`
- `lib/core/database/tables/customer_contacts_table.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart` (gerado via `build_runner`)

Domínio (`customers`):
- `lib/features/customers/domain/repositories/customer_local_store_repository.dart`
- `lib/features/customers/domain/entities/customer_offline_load_summary.dart`
- `lib/features/customers/domain/usecases/load_initial_customer_offline_data_use_case.dart`

Dados (`customers`):
- `lib/features/customers/data/mappers/customer_local_mapper.dart`
- `lib/features/customers/data/repositories/drift_customer_local_store_repository.dart`

Testes:
- `test/core/database/app_database_test.dart`
- `test/features/customers/data/mappers/customer_local_mapper_test.dart`
- `test/features/customers/data/repositories/drift_customer_local_store_repository_test.dart`
- `test/features/customers/domain/usecases/load_initial_customer_offline_data_use_case_test.dart`

Documentação:
- `docs/tasks/TASK-054-implementar-carga-offline-de-clientes-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `lib/core/database/database.dart` — barrel passou a exportar `AppDatabase` e
  as três novas tabelas.
- `lib/app/injection_module.dart` — novo provider `@lazySingleton AppDatabase
  appDatabase()`, abrindo o banco local via `drift_flutter` (`driftDatabase`)
  de forma preguiçosa, seguindo o mesmo padrão já usado para os SDKs Firebase
  neste módulo.
- `lib/app/injection.config.dart` — regenerado pelo `injectable_generator`
  para ligar `AppDatabase`, `CustomerLocalMapper`,
  `DriftCustomerLocalStoreRepository` e `LoadInitialCustomerOfflineDataUseCase`.
- `lib/features/customers/customers.dart` — barrel público passou a exportar
  os novos tipos de domínio (`CustomerLocalStoreRepository`,
  `CustomerOfflineLoadSummary`, `LoadInitialCustomerOfflineDataUseCase`).

`lib/main.dart` não foi tocado (fora de escopo).

## Arquitetura utilizada

Clean/feature-first + BLoC preservada:
- `AppDatabase`/tabelas Drift ficam em `core/database` (infraestrutura),
  Drift-free do domínio.
- `CustomerLocalStoreRepository` é um contrato de domínio
  (`domain/repositories`), sem qualquer import de Drift; a implementação
  concreta (`DriftCustomerLocalStoreRepository`) mora em `data/repositories`.
- `LoadInitialCustomerOfflineDataUseCase` (domínio) não conhece Drift: só
  depende de `CustomerRepository`, `PortfolioVisibilityService`,
  `PortfolioAssignmentRepository` e `CustomerLocalStoreRepository` (todas
  abstrações).
- Conversões enum↔string (`type`/`status`/`syncStatus`) são delegadas ao
  `CustomerMapper` já existente (usado hoje pelo DTO Firestore), evitando
  duplicar essa regra — `CustomerLocalMapper` cuida apenas da parte específica
  de Drift (linhas/companions, JSON de `tags`/`customFields`, ordenação de
  endereços/contatos via coluna `position`).
- Nenhuma UI/BLoC acessa `AppDatabase` diretamente; o caso de uso e o
  repositório local não foram conectados a nenhuma tela nesta task (fora do
  escopo — TASK-054 é só schema + seleção de carga).

## Regras de negócio implementadas

- Seleção de carga por papel, reaproveitando `PortfolioVisibilityService`
  (já criado em TASK-045/051): `SALES_REP` → apenas a própria carteira
  (`CustomerVisibilityMode.ownCustomers`); `SALES_MANAGER` → carteira das
  equipes que gerencia/participa (`teams`); `ADMIN`/`OWNER` →
  `allOrganization`; qualquer outro papel ou membership inativo →
  `none`.
- Nunca baixar cliente fora da carteira/permissão: quando a visibilidade
  resolve para `none`, ou quando um `SALES_REP` não tem nenhuma atribuição de
  carteira ativa, o caso de uso **limpa** o cache local (chama
  `replaceInitialLoad` com lista vazia) em vez de simplesmente não fazer
  nada — evita manter no dispositivo dados de um papel/carteira anterior mais
  amplo após um rebaixamento de permissão.
- Paginação com limite configurável: a carga percorre
  `CustomerRepository.listPortfolioPage` em páginas de `pageSize` (1–100,
  padrão 100) até `hasMore == false` ou até atingir `maxCustomers` (padrão
  2000), o que evitar impacto de organizações muito grandes no dispositivo.
  Quando o corte por `maxCustomers` descarta clientes que existiam além do
  limite, o resultado marca `truncated: true`.
- `replaceInitialLoad` é uma substituição completa e idempotente do cache
  local por tenant (`organizationId`/`companyId`) — carga inicial, não
  incremental, conforme pedido explicitamente pela task.

## Regras Firebase implementadas

Nenhuma regra de Firestore/Storage nova — esta task não introduz uma fonte de
dados remota; ela consome o `CustomerRepository` já existente (hoje
implementado sobre `shared_preferences`, ver TASK-051) e persiste localmente
via Drift/SQLite.

## Analytics implementado

Nenhum evento novo. O caso de uso não expõe UI e não há um fluxo de
"download" acionável pelo usuário ainda (isso é VESTI-080/TASK-107); quando
essa tela existir, ela deve instrumentar o evento de "offline pack" já
previsto em `AGENTS.md`.

## Crashlytics implementado

Nenhuma integração direta. Falhas do caso de uso e do repositório local são
retornadas como `AppFailure` tipado (`UnexpectedFailure`,
`ValidationFailure`), no mesmo padrão do restante do domínio — quem chamar o
caso de uso decide se/como reporta ao Crashlytics.

## Impacto offline

Base de dados offline de clientes criada (schema versão 1). Ainda não está
conectada às telas de carteira (TASK-051)/detalhe 360º (TASK-052), que
continuam lendo do `SharedPreferencesCustomerRepository` — essa migração de
fonte de dados fica para uma task futura de EPIC-14/integração. Dados
sensíveis (documento, contatos) passam a ter, quando essa migração ocorrer,
um caminho de armazenamento fora de `shared_preferences` (arquivo
SQLite/Drift local); nenhuma criptografia adicional do arquivo do banco foi
implementada nesta task (ver Riscos conhecidos).

## Impacto multi-tenant

Toda leitura/escrita local é sempre escopada por `organizationId` +
`companyId`: `replaceInitialLoad` só apaga/insere linhas do tenant informado
(testado explicitamente — ver `app_database_test.dart` e
`drift_customer_local_store_repository_test.dart`, casos que garantem que
recarregar/zerar a carga de uma organização não afeta outra). As tabelas de
endereço/contato herdam `organizationId`/`companyId` denormalizados da
tabela pai para permitir esse escopo sem `JOIN`.

## Testes criados

- `app_database_test.dart`: schema criado corretamente na primeira abertura
  (tabelas `customers`, `customer_addresses`, `customer_contacts`); exclusão
  em cascata de endereços/contatos ao remover o cliente pai; `replaceCustomers`
  nunca toca linhas de outro tenant; leitura preserva a ordem de
  endereços/contatos pela coluna `position`.
- `customer_local_mapper_test.dart`: round-trip completo `Customer` → linhas
  Drift → `Customer` preservando endereços, contatos, tags, `customFields` e
  todos os campos de sincronização; round-trip de um cliente mínimo (sem
  endereços/contatos/tags); preservação de ordem de listas.
- `drift_customer_local_store_repository_test.dart`: `replaceInitialLoad`
  grava todos os clientes dados; uma segunda chamada substitui completamente
  o conjunto anterior (sem sobras); nunca vaza entre organizações/empresas
  diferentes; `getAll` retorna endereços/contatos junto do cliente.
- `load_initial_customer_offline_data_use_case_test.dart`: payload inválido é
  rejeitado sem tocar nenhum repositório; `ADMIN` baixa a organização inteira
  em múltiplas páginas sem precisar ler atribuições de carteira;
  `SALES_MANAGER` só recebe atribuições dos times que pode ver;
  `SALES_REP` sem atribuição ativa tem o cache local limpo em vez de baixar
  algo; papel sem visibilidade (`FINANCE`) também limpa o cache local; o
  limite `maxCustomers` corta o download e marca `truncated: true`.

## Comandos executados

```bash
flutter pub run build_runner build
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` reportou apenas os arquivos novos/
alterados nesta task antes de formatá-los (`customer_addresses_table.dart`,
`customer_contacts_table.dart`, `customer_local_mapper.dart`,
`drift_customer_local_store_repository.dart`, e os 4 arquivos de teste
novos); após a formatação automática, `dart format --set-exit-if-changed .`
não reportou mais nenhuma alteração pendente no restante do projeto.

## Resultado do analyzer

```
Analyzing VestiPro...
No issues found! (ran in 13.2s)
```

## Resultado dos testes

```
flutter test
...
00:41 +1164: All tests passed!
```

Todos os 1164 testes da suíte (incluindo os novos desta task) passaram, sem
nenhuma falha.

## Decisões técnicas

- **`AppDatabase` inicial nesta task, não esperando TASK-106**: como não
  existia nenhum banco Drift no projeto e TASK-054 exige explicitamente
  "Tabela Drift `CustomersTable`" e "migração Drift versionada e testada",
  o `AppDatabase` (schema versão 1) foi criado aqui, com apenas as três
  tabelas de clientes, e documentado no próprio arquivo como a base que
  TASK-106 (EPIC-14, schema local geral) deve estender — não recriar.
- **DI registrada, mas não conectada a nenhuma tela**: `AppDatabase` é
  resolvido de forma preguiçosa (`@lazySingleton`) via `drift_flutter`
  (`driftDatabase(name: 'vestipro_offline')`), mas nada na UI/BLoC hoje
  resolve `CustomerLocalStoreRepository`/`LoadInitialCustomerOfflineDataUseCase`
  — a tela de download (VESTI-080/TASK-107) é quem vai acionar isso.
- **Web ainda não suportado para o banco local**: `driftDatabase` no target
  Web exige `sqlite3.wasm`/`drift_worker.js` empacotados em `web/`, que não
  existem neste repositório. Como nada resolve `AppDatabase` hoje, isso é uma
  lacuna documentada e inofensiva por ora (ver Riscos conhecidos) — não uma
  regressão, já que nenhum fluxo existente passou a depender disso.
- **Lógica de seleção de atribuições duplicada intencionalmente, não
  extraída**: `LoadInitialCustomerOfflineDataUseCase._loadAssignments` espelha
  `ListCustomerPortfolioUseCase._loadAssignments` (mesmo switch por
  `CustomerVisibilityMode`). Optei por não refatorar `ListCustomerPortfolioUseCase`
  para compartilhar um componente comum nesta task, para não alterar um
  arquivo (e seus testes) fora do escopo declarado de TASK-054. Ver Riscos
  conhecidos.
- **Limpar o cache local em vez de falhar quando não há portfólio visível**:
  diferente de `ListCustomerPortfolioUseCase` (que retorna `PermissionFailure`
  para manter a UI de listagem informativa), a carga offline trata "sem
  portfólio visível" como sucesso com 0 clientes e cache local zerado — é o
  comportamento correto para uma rotina de carga em background, e evita
  manter no dispositivo uma carteira maior de um papel anterior.

## Riscos conhecidos

- `ListCustomerPortfolioUseCase` e `LoadInitialCustomerOfflineDataUseCase`
  mantêm duas cópias do mesmo algoritmo de seleção de atribuições por papel.
  Uma consolidação futura (extrair um caso de uso/serviço compartilhado) é
  recomendada, mas não foi feita aqui para não expandir o escopo desta task
  para arquivos/testes de TASK-051.
- Banco local sem criptografia de arquivo (SQLCipher ou equivalente) — a task
  só pede "não usar `shared_preferences`", o que foi cumprido, mas uma
  decisão formal sobre criptografia em repouso do arquivo SQLite ainda
  depende do ADR de TASK-105 (pendente).
- Suporte Web do banco local (`driftDatabase`) não está configurado (faltam
  os assets `sqlite3.wasm`/`drift_worker.js`); resolver `AppDatabase` em Web
  hoje lançaria um `ArgumentError` claro. Como nada ainda resolve esse tipo
  em produção, não há regressão, mas fica registrado para quando TASK-107
  conectar a carga offline à UI.
- `SharedPreferencesCustomerRepository` (usado por TASK-051/052) continua
  sendo a única fonte de dados de clientes usada pelas telas; a migração
  dessas telas para consultar o novo cache Drift quando offline é trabalho
  futuro, não desta task.

## Pendências

- Conectar `LoadInitialCustomerOfflineDataUseCase`/`CustomerLocalStoreRepository`
  a um fluxo de UI de download (VESTI-080/TASK-107).
- Migrar a leitura offline de TASK-051 (carteira)/TASK-052 (detalhe 360º)
  para consultar `CustomerLocalStoreRepository` quando sem conectividade.
- Empacotar os assets Web do Drift (`sqlite3.wasm`, `drift_worker.js`) quando
  o suporte Web do banco local for necessário.
- Avaliar consolidar a lógica de seleção de atribuições por papel (hoje
  duplicada entre `ListCustomerPortfolioUseCase` e este caso de uso) em um
  componente compartilhado.

## Evidências

Saídas reais de `flutter analyze`, `dart format --set-exit-if-changed .` e
`flutter test` coladas nas seções acima.

## Commit

Commit local único contendo implementação, testes e esta documentação.

## Push

Não realizado — push não autorizado nesta rodada.

## Hash do commit

Ver hash reportado na resposta final desta execução (`git rev-parse HEAD`).

## Branch

`main`

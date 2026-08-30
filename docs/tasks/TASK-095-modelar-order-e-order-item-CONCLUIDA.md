# TASK-095 — Concluída (2026-08-30)

## Resumo
Modelagem das entidades `Order`/`OrderItem` (EPIC-13), com todos os campos previstos na seção 9 de
`tasks.md`, endereços de entrega/cobrança capturados como snapshot, máquina de estados explícita de
`OrderStatus` validada por `OrderStatusTransitionValidator`, trilha de auditoria
`OrderStatusHistoryEntry`, DTOs/mappers Firestore e cache local Drift (`orders`/`order_items`) com os
campos padrão offline-first. Nenhuma regra de submissão, precificação ou aprovação foi implementada
nesta task — apenas a estrutura de base que o restante do EPIC-13 vai consumir.

## Agentes utilizados
- flutter-senior-architect

## Arquivos criados
- `lib/core/database/tables/orders_table.dart`
- `lib/core/database/tables/order_items_table.dart`
- `lib/features/orders/domain/entities/order.dart` (+ `order.freezed.dart`)
- `lib/features/orders/domain/entities/order_item.dart` (+ `order_item.freezed.dart`)
- `lib/features/orders/domain/entities/order_address.dart` (+ `order_address.freezed.dart`)
- `lib/features/orders/domain/entities/order_status_history_entry.dart` (+
  `order_status_history_entry.freezed.dart`)
- `lib/features/orders/domain/value_objects/order_status.dart`
- `lib/features/orders/domain/value_objects/order_sync_status.dart`
- `lib/features/orders/domain/services/order_status_transition_validator.dart`
- `lib/features/orders/data/dtos/order_dto.dart`
- `lib/features/orders/data/dtos/order_item_dto.dart`
- `lib/features/orders/data/dtos/order_address_dto.dart`
- `lib/features/orders/data/dtos/order_status_history_entry_dto.dart`
- `lib/features/orders/data/mappers/order_mapper.dart`
- `lib/features/orders/data/mappers/order_local_mapper.dart`
- `lib/features/orders/orders.dart` (barrel file da feature)
- `test/features/orders/domain/services/order_status_transition_validator_test.dart`
- `test/features/orders/domain/entities/order_status_history_entry_test.dart`
- `test/features/orders/data/mappers/order_mapper_test.dart`

## Arquivos alterados
- `lib/core/database/app_database.dart` (registro das tabelas `OrdersTable`/`OrderItemsTable`,
  migração de schema v9 → v10, `OrderWithItemsRow` e os métodos `replaceOrders`/`upsertOrder`/
  `replaceOrderItems`/`getOrdersForCompany`/`getOrderById`)
- `lib/core/database/app_database.g.dart` (regenerado via `build_runner` para as novas tabelas)
- `lib/core/database/database.dart` (exports das novas tabelas)
- `lib/app/injection.config.dart` (regenerado via `build_runner` para registrar `OrderMapper`,
  `OrderLocalMapper` e `OrderStatusTransitionValidator`)
- `test/core/database/app_database_test.dart` (teste de migração/cascade para `orders`/`order_items`
  e atualização do `schemaVersion` esperado para 10)
- `test/core/database/app_database_warehouses_test.dart` (ajuste do `schemaVersion` hardcoded
  esperado, de 9 para 10 — teste pré-existente que quebrou por causa do bump de schema desta task;
  correção feita nesta mesma rodada, dentro do escopo de validação da task)
- `docs/tasks/TASKS.md` (checkbox da TASK-095 já estava marcado `[x]` e progresso em 95/220 de uma
  sessão anterior; incluído no commit desta rodada junto com o restante do trabalho)

## Arquitetura utilizada
Feature-first + Clean Architecture (`lib/features/orders/{domain,data}`), sem camada `presentation`
nesta task (nenhuma tela é implementada aqui — isso fica para TASK-096 em diante). Entidades de
domínio são `freezed`, imutáveis, sem dependência de Flutter/Firebase/Drift. DTOs Firestore isolam a
conversão de erro/validação de payload (`ValidationException`). `OrderMapper` é o único ponto que
decide os códigos string de `OrderStatus`/`OrderSyncStatus`; `OrderLocalMapper` reaproveita esse
mapeamento para a persistência Drift, sem duplicar a tabela de códigos. Tabelas Drift seguem o
precedente já usado por `CustomersTable`/`PriceListsTable` (índices por tenant, JSON columns para
estruturas aninhadas sem necessidade de query SQL direta, tombstone via `deletedAt`). DI via
`@injectable`/`@lazySingleton`, registrado em `injection.config.dart` via `build_runner` — nada de
`GetIt.instance` espalhado.

## Regras de negócio implementadas
- Máquina de estados fechada (`OrderStatus`, 12 valores da seção 9.1) com matriz de transições
  válidas centralizada em `OrderStatusTransitionValidator` (`draft → pendingSync → submitted →
  underReview → approved|rejected → processing → invoiced|partiallyInvoiced → shipped → delivered`;
  `cancelled` alcançável de qualquer estado anterior a `shipped`; `delivered`/`cancelled` terminais).
  `validateTransition` lança `ValidationException` (`invalid_order_status_transition`) para qualquer
  par inválido — inclusive transição de um status para ele mesmo.
- `OrderItem.unitPrice`/`subtotal` são valores capturados no momento da adição, nunca getters
  recalculados — documentado explicitamente para as tasks seguintes (motor de preço, TASK-088) não
  reintroduzirem recálculo retroativo sem trilha de auditoria.
- `OrderAddress` é um snapshot próprio do pedido (não uma referência a `CustomerAddress`), para que a
  edição posterior do cadastro do cliente nunca altere silenciosamente um pedido já colocado.
- `OrderStatusHistoryEntry` modela status anterior (nulo apenas na primeira entrada), novo status,
  timestamp, `actorId` e motivo opcional — usado como trilha de auditoria de toda transição aceita.
- Nenhuma regra de submissão, aprovação ou cálculo definitivo de total foi implementada (fora do
  escopo desta task, por definição de `tasks.md`).
- Documentado explicitamente em `OrderStatusTransitionValidator` que a validação client-side nunca
  substitui a validação server-side equivalente na Cloud Function de submissão/mudança de status
  (dupla validação) — a implementação dessa Cloud Function é de uma task futura do EPIC-13.

## Regras Firebase implementadas
N/A — nenhuma Cloud Function ou Security Rule nova nesta task (o modelo é puramente estrutural;
autorização/validação server-side fica para as tasks de submissão/aprovação do EPIC-13).

## Analytics implementado
N/A — nenhum evento de analytics é emitido nesta task (não há fluxo de usuário/tela ainda).

## Crashlytics implementado
N/A — nenhum ponto de captura de erro específico desta task além das exceções de domínio já
existentes (`ValidationException`).

## Impacto offline
`OrdersTable`/`OrderItemsTable` são o cache local do agregado `Order`, com os campos padrão
offline-first (`organizationId`, `companyId`, `createdBy`/`updatedBy`, `version`, `syncStatus`,
`deletedAt` como tombstone). `OrderItemsTable.orderId` referencia `OrdersTable.id` com
`ON DELETE CASCADE`, testado explicitamente. Os métodos `replaceOrders`/`upsertOrder`/
`replaceOrderItems` em `AppDatabase` são as primitivas que a futura engine de sync/Outbox (EPIC-14)
vai consumir — nenhum comportamento de sync (Outbox, `pending → syncing → synced/failed/conflict`)
é implementado nesta task, apenas o valor `OrderSyncStatus` que o representará.

## Impacto multi-tenant
Toda entidade carrega `organizationId`/`companyId` obrigatórios, documentados como nunca inferidos
apenas pelo cliente — a validação real de tenant fica para a Cloud Function/Security Rule que vier a
persistir o pedido (fora do escopo desta task). Índices Drift (`idx_orders_org_company`,
`idx_order_items_org_company`) garantem que toda query local já nasce escopada por tenant. DTOs
Firestore mantêm `organizationId`/`companyId` duplicados no payload para que Security Rules futuras
possam validar o escopo sem confiar apenas no caminho da coleção.

## Testes criados
- `test/features/orders/domain/services/order_status_transition_validator_test.dart` — matriz
  exaustiva de todos os pares `(from, to)` de `OrderStatus` (144 combinações), cobrindo transições
  válidas/inválidas, auto-transição, terminalidade de `delivered`/`cancelled`, bloqueio de
  `shipped → cancelled` e do salto `draft → delivered`, e o comportamento de
  `validateTransition` (retorno normal vs. `ValidationException`).
- `test/features/orders/domain/entities/order_status_history_entry_test.dart` — round-trip
  `toJson`/`fromJson` de `OrderStatusHistoryEntryDto` (com e sem `previousStatus`/`reason`),
  rejeição de payload inválido (`newStatus` ausente, `changedAt` não-`Timestamp`), e round-trip via
  `OrderMapper.historyEntryToDto`/`historyEntryToEntity` para todo par `(previousStatus, newStatus)`
  possível.
- `test/features/orders/data/mappers/order_mapper_test.dart` — round-trip `Order` completo (todos os
  campos preenchidos) e mínimo (opcionais nulos/vazios) via `toDto`/`toEntity`; round-trip de
  `OrderStatus`/`OrderSyncStatus`; rejeição de código desconhecido; round-trip de `OrderItem` e de
  `OrderStatusHistoryEntry`.
- `test/core/database/app_database_test.dart` (teste adicionado) — migração cria `orders`/
  `order_items` na versão de schema 10; cascade de `ON DELETE CASCADE` de `order_items` ao remover o
  `order` pai via `replaceOrders`, escopado por `organizationId`/`companyId`.
- `test/core/database/app_database_warehouses_test.dart` (ajustado) — `schemaVersion` esperado
  corrigido de 9 para 10, para não quebrar por causa do bump de schema desta task.

## Comandos executados
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
Sucesso — `Formatted 1572 files (0 changed) in 4.54 seconds.`

## Resultado do analyzer
Sucesso — `No issues found! (ran in 14.9s)`

## Resultado dos testes
Sucesso após uma correção: na primeira execução, `flutter test` falhou em
`test/core/database/app_database_warehouses_test.dart` (`AppDatabase warehouses migration creates
warehouses table in schema version 8`), porque esse teste pré-existente tinha `schemaVersion`
hardcoded em 9 e esta task elevou o schema para 10. Corrigido o valor esperado para 10 (teste
pré-existente, não desta feature, mas quebrado por efeito colateral direto desta task). Após a
correção: `+2004 All tests passed!` (suíte completa, 2004 testes, 0 falhas).

## Decisões técnicas
- Endereços de entrega/cobrança são snapshots próprios do pedido (`OrderAddress`), não referências a
  `CustomerAddress`, para nunca variar silenciosamente com edições posteriores no cadastro do
  cliente — decisão documentada no próprio arquivo da entidade para as tasks seguintes não
  reintroduzirem uma referência por engano.
- `OrderItem.subtotal`/`unitPrice` são campos capturados (não getters derivados), preservando
  auditabilidade de preço mesmo que a tabela de preço mude depois.
- Estruturas aninhadas sem necessidade de query SQL direta (`deliveryAddress`/`billingAddress`,
  `attachmentUrls`, `statusHistory`) foram persistidas localmente como colunas de texto JSON no Drift,
  seguindo o mesmo precedente de `CustomersTable.tagsJson`/`customFieldsJson`; `OrderItemsTable` é a
  única estrutura aninhada que virou tabela filha própria, por ser a que telas futuras (grade,
  catálogo) precisarão consultar diretamente.
- `orderType`/`collectionId` foram modelados como `String?` livres (não enum fechado), pois
  `tasks.md` seção 9 não fixa seus valores possíveis — mesmo precedente de `Customer.classification`.
- `OrderStatusTransitionValidator` documenta explicitamente que a validação client-side é só uma
  camada de UX/guard, e que a Cloud Function de submissão/mudança de status (task futura) precisa
  replicar exatamente a mesma matriz — dupla validação, nunca confiança unilateral no client.

## Riscos conhecidos
- Nenhuma Cloud Function/Security Rule ainda valida `organizationId`/`companyId`/transição de status
  no backend — essa validação dupla é responsabilidade de uma task futura do EPIC-13 (submissão),
  ainda não implementada. Até lá, o modelo existe mas não é gravado por nenhum fluxo real de
  submissão.
- `test/core/database/app_database_warehouses_test.dart` tinha um valor de `schemaVersion` hardcoded
  que quebra a cada bump de schema; o mesmo padrão existe em outros testes de migração do
  repositório e pode voltar a quebrar em tasks futuras que também alterem `schemaVersion` — vale
  considerar, em uma task de manutenção futura, centralizar essa expectativa em uma constante única
  para não depender de números mágicos espalhados pelos testes de migração.

## Pendências
- Casos de uso, BLoC/Cubit, repositório e Cloud Function de submissão/aprovação/mudança de status
  (TASK-096 em diante) ainda não existem — esta task só entrega o modelo estrutural.
- Nenhuma tela consome ainda `Order`/`OrderItem` (sem impacto de UI nesta task).
- Engine de sync/Outbox real para `Order` (EPIC-14) ainda não existe; `OrderSyncStatus` e os métodos
  `replaceOrders`/`upsertOrder`/`replaceOrderItems` são apenas as primitivas que essa engine futura
  vai consumir.

## Evidências
- `flutter analyze` sem issues.
- `flutter test` — suíte completa: `+2004 All tests passed!`.
- Teste exaustivo da matriz de transições de `OrderStatusTransitionValidator` (144 combinações
  `(from, to)`) e teste de cascade Drift (`orders` → `order_items`) confirmam os critérios de aceite
  da task.

## Commit
Realizado nesta rodada (ver hash abaixo).

## Push
Não autorizado nesta rodada.

## Hash do commit
Ver saída de `git log -1` após o commit.

## Branch
`main`

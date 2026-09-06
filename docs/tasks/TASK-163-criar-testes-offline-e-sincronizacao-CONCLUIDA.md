# TASK-163 — Criar testes offline e de sincronização — CONCLUÍDA

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Data de conclusão:** 2026-09-06
**Agente utilizado:** `flutter-senior-architect` (executado diretamente nesta sessão, sem
sub-agentes adicionais — escopo era puramente de testes sobre uma camada já implementada).

## Resumo

A camada de sincronização/offline (Outbox, `SyncEngine`, `SyncScheduler`, `ConflictResolutionService`)
já implementada em EPIC-14 (TASK-108 a TASK-112) já possuía uma suíte de testes bastante extensa:

- `test/core/database/app_database_outbox_test.dart` — persistência da Outbox no Drift, incluindo um
  teste de fechar/reabrir o banco em disco.
- `test/core/sync/data/repositories/drift_outbox_repository_test.dart` — contrato do repositório.
- `test/core/sync/domain/sync_engine_test.dart` — push (sucesso, retry/backoff, idempotência,
  recuperação de operação órfã em `syncing`) e pull (cursor incremental, tenant isolation, skip de
  registro com Outbox pendente, falha de fetch).
- `test/core/sync/domain/sync_scheduler_test.dart` — start/stop, ciclo periódico e reconexão via
  `connectivity_plus`/`ConnectivityService` fake.
- `test/core/sync/domain/conflict_resolution_service_test.dart` e
  `conflict_policy_catalog_test.dart` — os três modos de política de conflito
  (`lastWriteWins`, `fieldMerge`, `manualResolution`), incluindo pedidos sempre bloqueando para
  resolução manual.
- `test/core/sync/data/repositories/drift_conflict_record_repository_test.dart` e
  `drift_conflict_audit_log_repository_test.dart`.

Ou seja: a maior parte do escopo de TASK-163 (critérios de aceite de "criação, edição, conflito"
isolados, retry/backoff, e os três modos de conflito) já estava coberta e **não foi duplicada**.

O único cenário obrigatório do backlog que faltava um teste automatizado explícito era o de
**"o app foi fechado e reaberto"** — ou seja, close/reopen do `AppDatabase` (não apenas dentro do
mesmo processo/instância em memória) combinado com uma nova instância de `SyncEngine`/
`ConflictResolutionService`, provando que nada do fluxo depende de estado em memória perdido no
fechamento do app. Esse é exatamente o cenário citado nas regras de negócio da task
("Reconexão após o app ser fechado/reaberto retoma a sincronização a partir do estado persistido, sem
depender de estado em memória perdido") e no teste obrigatório "criação de pedido offline sobrevive ao
fechamento do app".

Foi criado um novo arquivo de teste cobrindo esse gap, reutilizando os padrões de fakes já
estabelecidos em `sync_engine_test.dart` (mesma estrutura de `_FakePushHandler`/
`_FakeSyncPullSource`/`_RecordingCrashReporter`), mas usando `NativeDatabase` em arquivo (não
`.memory()`) para simular o fechamento real do processo entre duas "sessões" do app.

## Arquivos criados

- `test/core/sync/domain/sync_engine_offline_lifecycle_test.dart` — novo arquivo de teste, com 4
  casos, todos usando dois bancos Drift sequenciais sobre o mesmo arquivo em disco (sessão 1 = antes
  de fechar o app; sessão 2 = depois de reabrir):
  1. **Pedido criado offline sobrevive ao fechamento do app e sincroniza ao reconectar, sem
     duplicação** — enfileira a operação na sessão 1, fecha o banco, reabre em uma nova instância
     (`AppDatabase`, `DriftOutboxRepository`, `SyncEngine` novos), roda `runPush` e confirma
     `synced`; uma segunda chamada de `runPush` confirma que o item já sincronizado nunca é reenviado.
  2. **Backoff exponencial sobrevive ao fechamento do app** — sessão 1 sofre uma falha retryable
     (`attemptCount` vai a 1, `lastAttemptAt` persistido); o app fecha antes do backoff expirar;
     sessão 2 tenta `runPush` 1s depois (ainda dentro da janela de 2s) e confirma que **não** tenta de
     novo; tenta novamente 1s depois (completando a janela) e confirma que sincroniza, com
     `attemptCount` final igual a 2 — provando que o estado de retry não foi resetado pela reabertura.
  3. **Cursor de sincronização incremental sobrevive ao fechamento do app** — sessão 1 aplica uma
     página remota e persiste o cursor; o app fecha; sessão 2 (nova fonte simulando o mesmo backend)
     confirma que a próxima busca já usa o cursor persistido (não `null`) e que nada é reaplicado,
     inclusive em uma terceira reconexão subsequente.
  4. **Conflito de pedido detectado após reconexão do app fechado** — edição de pedido offline na
     sessão 1; ao "reconectar" na sessão 2 (nova instância de `ConflictResolutionService` sobre o
     banco reaberto), o valor remoto divergente em `discount` (campo financeiro) é sempre bloqueado
     para resolução manual (`ConflictResolutionBlockedManual`, `ConflictPolicy.manualResolution`),
     nunca resolvido automaticamente como last-write-wins, e a operação da Outbox migra para
     `conflict`.

## Arquivos alterados

- `docs/tasks/TASKS.md` — checkbox da TASK-163 marcado `[x]`; progresso atualizado de
  `162 / 220` para `163 / 220`.

Nenhum arquivo de produção (`lib/`) foi alterado — esta task era exclusivamente de testes sobre
comportamento já implementado.

## Testes criados (resumo dos casos)

| # | Cenário | Arquivo |
|---|---------|---------|
| 1 | Criação offline sobrevive ao fechamento do app e sincroniza ao reconectar (idempotente) | `sync_engine_offline_lifecycle_test.dart` |
| 2 | Backoff exponencial sobrevive ao fechamento do app (não reseta `attemptCount`/janela) | `sync_engine_offline_lifecycle_test.dart` |
| 3 | Cursor incremental sobrevive ao fechamento do app (não reprocessa após múltiplas reconexões) | `sync_engine_offline_lifecycle_test.dart` |
| 4 | Conflito de pedido após reconexão do app fechado exige resolução manual | `sync_engine_offline_lifecycle_test.dart` |

Testes pré-existentes reaproveitados como cobertura válida dos demais critérios de aceite (não
duplicados): push com sucesso, retry/backoff dentro do mesmo processo, idempotência de replay,
recuperação de operação órfã em `syncing` (falha no meio da sincronização), pull incremental por
cursor dentro do mesmo processo, rejeição cross-tenant, skip de registro com Outbox pendente, os três
modos de política de conflito, scheduler reagindo a reconexão de rede via `ConnectivityService` fake.

## Comandos executados e resultados reais

```
flutter test test/core/sync/domain/sync_engine_offline_lifecycle_test.dart
→ 00:00 +4: All tests passed!

flutter test test/core/sync/ test/core/database/app_database_outbox_test.dart
→ 00:02 +69: All tests passed!
  (um warning benigno e pré-existente do Drift sobre múltiplas instâncias de AppDatabase
  no teste "Outbox rows survive closing and reopening..." de app_database_outbox_test.dart,
  já presente antes desta task — não relacionado aos arquivos criados aqui.)

dart format --set-exit-if-changed test/core/sync/domain/sync_engine_offline_lifecycle_test.dart
→ 1ª execução: reformatou o arquivo (quebra de linha em duas declarações de `test(...)`)
→ 2ª execução: "Formatted 1 file (0 changed)" — limpo.

flutter analyze test/core/sync/domain/sync_engine_offline_lifecycle_test.dart
→ "No issues found!"
```

## Decisões técnicas

- **Não duplicar cobertura existente.** Antes de escrever qualquer teste, os arquivos de teste já
  existentes para Outbox/SyncEngine/ConflictResolutionService foram lidos integralmente para
  identificar exatamente o que faltava. O único gap real em relação à lista de "Testes obrigatórios"
  do backlog era o ciclo completo de fechar/reabrir o app.
- **Banco em arquivo, não em memória, para simular fechamento real do app.** Os testes novos usam
  `NativeDatabase(File(...))` (como o teste já existente em `app_database_outbox_test.dart`), abrindo
  duas instâncias sequenciais de `AppDatabase` (nunca simultâneas) sobre o mesmo arquivo — a segunda
  só é aberta depois de `await session1Db.close()` — para garantir que o estado lido na "sessão 2" vem
  do disco, não de qualquer instância em memória sobrevivente.
  Isso reproduz o warning inofensivo do Drift sobre "múltiplas instâncias de AppDatabase" que os
  próprios testes pré-existentes do repositório já toleram — comportamento esperado e documentado do
  padrão de teste, não um problema introduzido.
- **Reuso de fakes.** `_FakePushHandler`, `_FakeSyncPullSource` e `_RecordingCrashReporter` seguem
  exatamente o mesmo formato de `sync_engine_test.dart`, apenas com um `script`/`behavior`
  configurável por teste, para manter o estilo consistente com o resto da suíte.
- **Teste de conflito reaproveita `ConflictResolutionService` diretamente**, sem tentar "religar" o
  `SyncEngine.runPull` a essa resolução — essa integração (chamar `ConflictResolutionService` de
  dentro de `SyncEngine.runPull`) ainda não existe na implementação de produção (o próprio docstring
  de `ConflictResolutionService` documenta isso como "a future `SyncEngine` integration"), e essa
  integração está fora do escopo desta task, que é sobre testes, não sobre reimplementar/rewire a
  feature.

## Riscos e pendências conhecidos

- A integração direta entre `SyncEngine.runPull` e `ConflictResolutionService` ainda não existe no
  código de produção — hoje, quando `runPull` encontra um registro remoto para uma entidade com
  operação pendente na Outbox, ele apenas faz *skip* (nunca sobrescreve), mas não chama o serviço de
  resolução de conflito automaticamente. Isso é um comportamento pré-existente, não introduzido por
  esta task, e é sinalizado aqui apenas para visibilidade de uma eventual task futura de wiring
  (fora do escopo de TASK-163, que pede testes sobre o comportamento existente).
- Os testes de reabertura de banco usam arquivos temporários únicos por teste
  (`Directory.systemTemp`, com timestamp + contador), removidos em `tearDown`/`addTearDown` — nenhum
  arquivo de teste fica para trás em execução normal.

# TASK-105 — Criar ADR de banco local (Drift vs. Isar) — CONCLUÍDA

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ✅ Concluída em 2026-08-31
**Agente:** `flutter-senior-architect`

## Resumo

Produzido o ADR formal comparando Drift/SQLite vs. Isar para a persistência local do VestiPro, exigido
pela seção 5.2 de `tasks.md` e pela TASK-105.

Antes de codar, verifiquei se já existia implementação equivalente (passo obrigatório do protocolo) e
encontrei que a decisão por Drift já estava operacionalmente tomada e em uso extenso desde a TASK-003:

- ADR-0001 (`docs/adr/0001-dependencias-base.md`) já havia registrado `drift`/`drift_flutter`/
  `drift_dev` como dependências de banco local.
- `lib/core/database/app_database.dart` já define um `AppDatabase` real, `schemaVersion` 12, com 12
  migrações incrementais aplicadas ao longo de 10 tasks (EPIC-06, 08, 09, 11, 12, 13).
- 12 tabelas Drift reais já existem em `lib/core/database/tables/`, todas com os campos de
  sincronização da seção 5.3 (`organizationId`, `companyId`, `createdAt/By`, `updatedAt/By`,
  `deletedAt`, `version`, `syncStatus`).
- 17 arquivos de teste já exercitam esse banco (`test/core/database/**`, `test/features/**/data/**`),
  nenhum usa Isar.

Dado esse estado real do repositório, esta task formalizou a decisão retroativamente com os critérios
objetivos pedidos (queries relacionais, volume, migração, maturidade, Web, integração com
`freezed`/`build_runner`, testabilidade, isolamento multi-tenant), avaliou Isar como alternativa com os
mesmos critérios e confirmou Drift/SQLite como decisão definitiva — sem trocar de banco local.

## Decisão tomada

**Drift/SQLite** confirmado como o único banco local do VestiPro. Isar não é adotado. Qualquer reversão
futura exige um novo ADR explícito (restrição já registrada na própria TASK-105 e reforçada no ADR).

## Arquivos criados

- `docs/adr/0003-banco-local-drift.md` — ADR-0003, seguindo o mesmo padrão/numeração dos ADRs já
  existentes no repositório (`docs/adr/0001-*.md`, `docs/adr/0002-*.md`; não criei uma pasta paralela
  `docs/architecture/adr/` como o texto original da task sugeria, porque o repositório já tinha uma
  convenção de ADR em uso — segui a convenção real, não a hipotética).
- `docs/tasks/TASK-105-criar-adr-de-banco-local-CONCLUIDA.md` — este arquivo.

## Arquivos alterados

- `lib/core/database/README.md` — agora aponta para `docs/adr/0003-banco-local-drift.md` como fonte da
  verdade da decisão de banco local, e reforça que `AppDatabase` é a única classe/cadeia de migração
  local (nenhuma feature deve criar um segundo banco).
- `docs/tasks/TASKS.md` — checkbox da TASK-105 marcado como `[x]`; progresso atualizado de
  "104 / 220" para "105 / 220".

## Validações executadas

- `flutter test test/core/database/` — reexecutei a suíte já existente que serve de spike/prova de
  viabilidade da decisão (criação de schema, leitura/escrita, `ON DELETE CASCADE`, migração
  incremental de schema), rodando inteiramente sobre `NativeDatabase.memory()` (SQLite em memória, sem
  dependência nativa externa). Resultado real: **30 testes, todos passando** (`All tests passed!`),
  sem erro de plataforma.
- Não executei `dart format`/`flutter analyze`/`flutter test` (suíte completa) porque esta task não
  alterou nenhum código Dart de produção nem criou testes novos — apenas documentação (ADR) e um
  README. O único comando Dart relevante ao escopo (`flutter test test/core/database/`, a evidência de
  viabilidade pedida explicitamente pela task) foi executado com sucesso, como registrado acima.

## Riscos conhecidos e pendências

- Suporte Flutter Web pleno do Drift (`sqlite3.wasm` + worker via `drift_flutter`) continua pendente de
  verificação automatizada real em alvo Web (`flutter test -d chrome` ou equivalente); a suíte
  reexecutada nesta task roda apenas no target VM/nativo. Essa pendência já era conhecida desde o
  ADR-0001 e fica formalmente atribuída à TASK-106 (Modelar schema local Drift), não a esta task.
- O ADR-0003 documenta uma decisão já em uso, não uma migração de tecnologia — não há risco de quebra
  para as tasks já concluídas (EPIC-06 a EPIC-13), que continuam usando exatamente o mesmo
  `AppDatabase`.
- Nenhuma tabela/coluna nova foi criada nesta task; TASK-106 em diante deve seguir estendendo o mesmo
  `AppDatabase`/cadeia de migração, conforme já documentado nos comentários da própria classe e
  reforçado no ADR.

## Commit

Ver `git log -1` no momento da entrega desta task para o hash real do commit que inclui este arquivo,
`docs/adr/0003-banco-local-drift.md`, `lib/core/database/README.md` e `docs/tasks/TASKS.md`.

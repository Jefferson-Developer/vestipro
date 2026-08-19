# TASK-105 — Criar ADR de banco local (Drift vs. Isar)

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (arquitetura feature-first definida, pastas `lib/core/database/` e `lib/core/offline/` já existentes como destino da decisão)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Produzir um Architecture Decision Record (ADR) formal comparando Drift/SQLite vs. Isar para a persistência local do VestiPro, com decisão final documentada e justificada, para que as ~15 tasks seguintes do EPIC-14 (schema local, Outbox, motor de sincronização, conflitos) tenham uma base técnica única e sem ambiguidade.

## Escopo técnico

- Criar `docs/architecture/adr/ADR-0001-banco-local.md` seguindo um template de ADR padrão (título, status, contexto, alternativas consideradas, decisão, consequências).
- Avaliar critérios objetivos: suporte a queries relacionais complexas (joins entre pedidos, itens, variantes e tabelas de preço), volume esperado por carga offline (milhares de produtos/variantes e centenas de clientes por vendedor), necessidade de migrações versionadas, maturidade/manutenção do pacote, suporte real a Flutter Web (IndexedDB/sqlite3 wasm para Drift vs. suporte Web do Isar), integração com `freezed`/`build_runner` já usados no projeto e facilidade de escrever testes de repositório.
- Avaliar isolamento multi-tenant no banco local: viabilidade de índices/where obrigatórios por `organizationId`/`companyId` em cada tabela na tecnologia escolhida.
- Avaliar estratégia de migração de schema (versionamento incremental, rollback, custo de migração em produção).
- Registrar a decisão final e os trade-offs conscientemente aceitos (custo de manutenção de SQL, verbosidade de `drift_dev` vs. simplicidade do Isar, por exemplo).
- Criar/atualizar `lib/core/database/README.md` apontando para o ADR como fonte da verdade.

## Regras de negócio e restrições

- A decisão não pode ignorar suporte a Flutter Web — o VestiPro roda em iOS, Android e Web (seção 1 de `tasks.md`).
- A tecnologia escolhida deve conseguir representar todos os campos de sincronização da seção 5.3 (`id`, `organizationId`, `companyId`, `createdAt/By`, `updatedAt/By`, `deletedAt`, `version`, `syncStatus`) sem contorções.
- A decisão deve considerar volume real: catálogo com milhares de variantes e carteira de centenas de clientes por vendedor, não um cenário de poucos registros.
- Uma vez tomada, a decisão só pode ser revertida por um novo ADR explícito — nenhuma task futura pode trocar de banco local silenciosamente.

## Testes obrigatórios

- Spike/protótipo mínimo validando leitura e escrita de um schema de exemplo na tecnologia escolhida (teste automatizado criando uma tabela simples, inserindo e consultando um registro), como prova de viabilidade antes de comprometer as próximas tasks com a decisão.
- Teste automatizado confirmando que o pacote escolhido compila e executa em `flutter test` sem erro específico de plataforma (incluindo, quando possível, uma verificação relacionada ao alvo Web).

## Critérios de aceite

- ADR criado com contexto, alternativas comparadas por critério objetivo, decisão final e consequências assumidas.
- Protótipo mínimo de leitura/escrita funcionando e coberto por teste automatizado.
- Decisão referenciada de forma inequívoca pelas tasks seguintes (TASK-106 em diante).
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

# TASK-114 — Modelar Target

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization modelada — Target referencia `organizationId`/`companyId` e a estrutura de equipes/usuários dependente da organização)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade Target (meta comercial) cobrindo período e dimensão (vendedor, equipe, empresa, coleção, categoria), servindo de base para o cadastro de metas (TASK-115), o dashboard de atingimento (TASK-116) e as demais tasks do EPIC-15.

## Escopo técnico

- Criar a entidade de domínio `Target` (com `freezed`) contendo: `id`, `organizationId`, `companyId`, período (`startDate`, `endDate`, granularidade: mensal/trimestral/anual), `dimensionType` (enum: salesRep, team, company, collection, category), `dimensionId` (referência ao vendedor/equipe/empresa/coleção/categoria conforme `dimensionType`), `metricType` (enum: revenue, quantity, positivacao — extensível), `targetValue`, `currency`, `status` (draft/active/closed), `createdAt/By`, `updatedAt/By`, `deletedAt`, `version`, `syncStatus`.
- Criar `TargetDto` (camada `data`) e `TargetMapper`, seguindo a separação DTO/Entidade já usada no restante do projeto.
- Modelar a coleção Firestore `organizations/{organizationId}/targets/{targetId}` (conforme seção 20 de `tasks.md`) e a tabela Drift correspondente (`TargetsTable`) para a carga offline, integrando com o schema da TASK-106.
- Definir o contrato de repositório (`TargetRepository`) com métodos de consulta por dimensão + período (ex.: metas ativas de um vendedor no mês corrente, metas de uma equipe no trimestre).
- Validar unicidade lógica: não permitir duas metas ativas com a mesma combinação (`organizationId`, `companyId`, `dimensionType`, `dimensionId`, `metricType`, período sobreposto) — regra de validação no caso de uso de criação (antecipando a TASK-115).

## Regras de negócio e restrições

- `Target` sempre pertence a uma `organizationId` e, quando o `dimensionType` exigir (ex.: company, team), a um `companyId`/`teamId` consistente.
- `targetValue` nunca pode ser negativo; período sempre com `startDate` < `endDate`.
- Metas com período sobreposto para a mesma dimensão/métrica são inválidas (regra validada na criação, não apenas na UI).
- A entidade não calcula atingimento/progresso (isso é responsabilidade da TASK-116) — `Target` é apenas a definição da meta.

## Testes obrigatórios

- Teste de criação da entidade `Target` cobrindo valores válidos e inválidos (`targetValue` negativo, período invertido).
- Teste do mapper DTO ↔ Entidade.
- Teste de validação de sobreposição de período para a mesma dimensão/métrica.
- Teste de repositório (com fake/mock datasource) para consulta por dimensão + período.

## Critérios de aceite

- Entidade `Target` modelada com todos os campos de período/dimensão e de sincronização (seção 5.3).
- Coleção Firestore e tabela Drift correspondentes definidas.
- Validação de período/valor e de sobreposição implementada e testada.
- `flutter analyze` e `flutter test` passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

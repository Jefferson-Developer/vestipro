# TASK-053 — Implementar segmentação dinâmica de clientes

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-051 (Implementar carteira de clientes) — a segmentação reaproveita os filtros e a listagem já implementados na carteira.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir a criação de segmentos de clientes por critérios combináveis (região, potencial, última compra, categoria comprada), com filtros persistidos e reutilizáveis para campanhas, relatórios e ações comerciais direcionadas.

## Escopo técnico

- Entidade `CustomerSegment` (nome, `organizationId`, critérios combináveis serializados, criado por, visibilidade privada/compartilhada).
- Builder de critérios reaproveitando os filtros de TASK-051 (status, região, potencial, última compra) e adicionando categoria de produto comprada como filtro dinâmico, preparado para plugar quando o histórico de pedidos existir (EPIC-08/13).
- Persistência do segmento e aplicação como filtro rápido na carteira de clientes.
- Contagem de clientes que atendem ao segmento calculada sob demanda (preview antes de salvar).

## Regras de negócio e restrições

- Segmento sempre escopado por organização; nunca reutilizável entre organizações diferentes.
- Critérios combináveis via AND nesta versão; ausência de suporte a OR deve ser documentada como limitação conhecida.
- Segmento "privado" visível apenas ao criador; "compartilhado" visível à equipe/organização conforme RBAC.
- Alterar critérios de um segmento existente não deve afetar retroativamente relatórios já gerados a partir dele (preservar snapshot dos critérios usados, quando aplicável).

## Testes obrigatórios

- Testes de caso de uso: criar segmento, prever contagem de clientes, aplicar segmento como filtro.
- Teste de persistência e reaplicação de segmento salvo.
- Teste de RBAC: segmento privado não aparece para outro usuário; segmento compartilhado aparece.
- Teste de critério combinando três ou mais filtros simultaneamente.

## Critérios de aceite

- Usuário consegue criar, salvar e reaplicar segmentos com múltiplos critérios combinados.
- Segmentos respeitam o escopo de organização e a visibilidade (privado/compartilhado).
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

# TASK-051 — Implementar carteira de clientes

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — a listagem consulta a entidade Customer já definida; TASK-045 (Implementar vínculo de vendedores a carteiras) — a visibilidade da lista depende do vínculo vendedor-carteira já implementado.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Listar os clientes da carteira do representante autenticado (ou da carteira visível conforme o papel), com filtros por status, região, potencial e última compra, respeitando integralmente as regras de visibilidade do RBAC e do vínculo de carteiras.

## Escopo técnico

- Página `CustomerPortfolioPage` com lista paginada por cursor, busca por nome/documento e filtros combináveis (status, região/UF, potencial, faixa de última compra).
- `CustomerPortfolioBloc` com paginação preservando os itens já carregados, debounce de busca e cancelamento da busca anterior.
- Repositório de leitura escopado por organização + carteira do usuário: `SALES_REP` vê apenas sua carteira; `SALES_MANAGER` vê carteiras da equipe; `ADMIN`/`OWNER` vê o escopo mais amplo — reaproveitando o RBAC de TASK-029 e os vínculos de TASK-045.
- Card de cliente do Design System (TASK-021/023) exibindo nome, documento, status, potencial e última compra.
- Suporte a leitura offline usando os dados já baixados pela carga inicial (TASK-054), quando disponível.

## Regras de negócio e restrições

- Nunca construir a query de carteira confiando apenas em um filtro client-side — a visibilidade real deve ser resolvida a partir do vínculo vendedor-carteira e do papel do usuário, validado no repositório/backend.
- Vendedor sem vínculo de carteira não deve enxergar clientes de outros vendedores; falha na resolução da carteira deve gerar erro explícito, nunca uma lista vazia disfarçada de "sem clientes".
- Filtros devem ser combináveis (AND) e refletidos na URL no Flutter Web.

## Testes obrigatórios

- Testes de bloc: paginação sem perda de itens, busca com debounce/cancelamento, combinação de filtros, RBAC restringindo a carteira (vendedor vs. gestor vs. admin).
- Teste de repositório: query escopada por organização e carteira, negando acesso a clientes fora da carteira do usuário.
- Testes de widget: lista vazia (nenhum cliente na carteira), erro de carregamento, exibição offline com dados locais.

## Critérios de aceite

- Representante só visualiza clientes de sua carteira; gestor/admin visualizam conforme o escopo do papel.
- Filtros combináveis funcionam e persistem na navegação (Web).
- `flutter analyze`, `dart format` e testes passam; paginação nunca perde itens já carregados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

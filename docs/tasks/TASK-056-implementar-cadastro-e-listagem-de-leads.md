# TASK-056 — Implementar cadastro e listagem de leads

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-055 (Modelar Lead) — a tela e a listagem operam sobre a entidade e os casos de uso já definidos.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o formulário de cadastro de lead e a listagem com filtro por origem/status/responsável, incluindo a ação de qualificar/desqualificar diretamente na lista ou no detalhe do lead.

## Escopo técnico

- Página `LeadFormPage` com os campos de TASK-055 (nome/empresa, origem, responsável, dados de contato básicos).
- Página `LeadListPage` com filtros combináveis (origem, status, responsável), busca por nome e paginação por cursor.
- Ação contextual "Qualificar"/"Desqualificar" (com modal exigindo motivo) na lista e no detalhe do lead.
- Badge de status visual (novo/em contato/qualificado/desqualificado/convertido) usando tokens do Design System, nunca dependendo só de cor.
- Reaproveitamento de componentes do Design System (cards, chips de filtro, badges de TASK-021/022/023).

## Regras de negócio e restrições

- Apenas perfis autorizados (ex.: `SALES_REP`, `SALES_MANAGER`, `ADMIN`, `OWNER` conforme política) podem qualificar/desqualificar ou reatribuir o responsável, conforme RBAC.
- Desqualificar sem motivo deve ser bloqueado na UI antes mesmo de chamar o caso de uso (o domínio também valida, conforme TASK-055).
- A lista deve refletir imediatamente a mudança de status após uma ação, sem exigir atualização manual.

## Testes obrigatórios

- Teste de widget do formulário: submissão válida, campos obrigatórios ausentes.
- Teste de bloc da listagem: filtros combinados, paginação, busca com debounce.
- Teste da ação de qualificar/desqualificar refletindo no estado da lista sem atualização manual.
- Teste de RBAC ocultando as ações para perfil sem permissão.

## Critérios de aceite

- Cadastro de lead funcional com validação; listagem com filtros por origem/status/responsável.
- Qualificar/desqualificar funciona a partir da lista e do detalhe, respeitando o RBAC.
- `flutter analyze`, `dart format` e testes passam; estados de loading, erro e vazio tratados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

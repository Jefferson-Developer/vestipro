# TASK-042 — Implementar lista de usuários da organização

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (modelagem de Organization — escopo do tenant da listagem); TASK-029 (RBAC — define quem pode acessar a listagem administrativa)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a listagem administrativa de usuários da organização, com busca, filtro por role e status, e paginação — base para as demais telas administrativas de usuários (gestão de perfis, equipes, desativação, auditoria).

## Escopo técnico

- Criar `UserListPage` restrita a roles com permissão administrativa; a rota é ocultada na navegação para quem não tem permissão, mas a restrição real é validada no backend.
- Criar `UserListCubit`/`Bloc` com paginação por cursor sobre Firestore, busca por nome/e-mail com debounce, e filtros combináveis por role (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`) e por status (ativo/desativado, integrado com TASK-046).
- Renderizar como tabela administrativa em desktop/tablet (colunas: nome, e-mail, role, status, equipe) e como cards em mobile, conforme padrão do Design System.
- Adicionar ações contextuais de acesso rápido para "gerenciar perfil/permissão" (TASK-043) e "desativar usuário" (TASK-046) diretamente a partir da lista.
- Tratar estado vazio (nenhum usuário para o filtro aplicado) e estado de erro com opção de tentar novamente.

## Regras de negócio e restrições

- A listagem é sempre escopada pela organização ativa do usuário autenticado; nunca deve ser possível consultar usuários de outra organização.
- Usuário sem permissão administrativa não deve conseguir sequer montar a query de listagem — a validação de RBAC ocorre antes de disparar a busca, além da negação garantida no backend.

## Testes obrigatórios

- `bloc_test` cobrindo paginação, busca com debounce, filtros combinados (role + status), lista vazia e erro de rede.
- Testes de widget: renderização em tabela (desktop) e em cards (mobile), ocultação da tela para role sem permissão administrativa.
- Teste de Firestore Security Rules garantindo que uma query manipulada para outra organização é negada.

## Critérios de aceite

- Listagem funcional com busca, filtros combinados e paginação por cursor.
- Layout adaptado corretamente a mobile, tablet e desktop.
- Acesso restrito a perfis administrativos, validado tanto na UI quanto no backend.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

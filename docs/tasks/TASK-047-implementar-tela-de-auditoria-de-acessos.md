# TASK-047 — Implementar tela de auditoria de acessos

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-033 (auditoria administrativa — audit log central que esta tela consulta)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela de consulta ao audit log central criado na TASK-033, permitindo que `ADMIN`/`OWNER` filtrem e revisem ações administrativas (ator, ação, entidade afetada, timestamp) da organização.

## Escopo técnico

- Criar `AuditLogPage` consumindo o audit log central, exibido como tabela administrativa (colunas: data/hora, ator, ação, entidade afetada, detalhes) convertida em cards em mobile.
- Implementar filtros combináveis: intervalo de período, usuário/ator, tipo de ação (ex.: login, alteração de role, criação de organização, desativação de usuário, criação/revogação de convite).
- Implementar paginação por cursor — o audit log cresce indefinidamente e nunca deve ser carregado por completo de uma vez.
- Restringir o acesso a `ADMIN`/`OWNER`, ocultando a rota na navegação para os demais perfis, com a restrição real validada no backend (Firestore Security Rules/Cloud Function).
- Exportação avançada de logs fica fora do escopo desta task (tratada futuramente em EPIC-18/TASK-204); aqui a tela é apenas de consulta.

## Regras de negócio e restrições

- Nunca expor entradas de auditoria de outra organização — o escopo é sempre a organização ativa do usuário autenticado.
- A tela é somente leitura: nenhuma edição ou exclusão de entradas de auditoria é permitida pela interface.
- Cada entrada deve ser exibida de forma legível para humanos, nunca como JSON cru sem formatação.

## Testes obrigatórios

- Testes de widget: renderização em tabela (desktop) e cards (mobile), filtros combinados, paginação, estado vazio, ocultação da tela para roles não autorizadas.
- Teste de Firestore Security Rules garantindo que apenas `ADMIN`/`OWNER` conseguem ler a coleção de auditoria, e apenas da própria organização.
- Teste de paginação com grande volume de entradas simuladas, garantindo performance e ausência de duplicação entre páginas.

## Critérios de aceite

- Consulta ao audit log funcional, com filtros combináveis e paginação por cursor.
- Acesso restrito a `ADMIN`/`OWNER`, validado tanto na UI quanto no backend.
- Nenhuma entrada de outra organização é exposta, comprovado por teste.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

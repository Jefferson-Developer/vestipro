# TASK-044 — Implementar equipes comerciais

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (modelagem de Organization — Team pertence a uma Organization); TASK-042 (lista de usuários — fonte de seleção de membros e gestores)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a criação e edição de equipes comerciais (`Team`), agrupando vendedores e gestores, permitindo que um usuário pertença a múltiplas equipes quando isso for permitido pela organização.

## Escopo técnico

- Criar `TeamListPage` e `TeamFormPage` (criar/editar), reaproveitando a modelagem base de `Team` já definida em TASK-028 e focando nesta task na tela e nos casos de uso de gestão.
- Criar `CreateTeamUseCase`, `UpdateTeamUseCase`, `AddMemberToTeamUseCase`, `RemoveMemberFromTeamUseCase`.
- Seleção de gestor responsável (role `SALES_MANAGER`) e de membros (`SALES_REP`/`SALES_ASSISTANT`) via busca com multi-seleção, reaproveitando componentes do Design System.
- Suportar que um usuário pertença a mais de uma `Team` simultaneamente (ex.: vendedor atuando em duas linhas de produto ou regiões distintas), respeitando um limite configurável pela organização quando existir.
- Tratar estado vazio orientando a criação da primeira equipe e validar que uma `Team` não pode ser salva sem um gestor definido.

## Regras de negócio e restrições

- Toda `Team` pertence a uma Organization (e, quando aplicável, a uma Company/Branch específica) — nunca compartilhada entre tenants.
- Remover um membro de uma `Team` não afeta seu vínculo em outras equipes nem seu acesso geral à organização.
- Exclusão de uma `Team` com carteiras de clientes ou pedidos vinculados deve ser bloqueada, ou exigir realocação prévia dos vínculos — nunca deletar dados comerciais em cascata.

## Testes obrigatórios

- Testes de caso de uso: criação, edição, adição e remoção de membro, usuário associado a múltiplas equipes simultaneamente, tentativa de exclusão de `Team` com vínculo ativo (deve ser bloqueada).
- Testes de widget: formulário de criação/edição de equipe, seleção múltipla de membros, estado vazio, validação de gestor obrigatório.

## Critérios de aceite

- Equipes criadas e editadas corretamente, sempre escopadas à organização ativa.
- Usuário pode pertencer a múltiplas equipes sem gerar inconsistência.
- Exclusão de equipe com vínculos comerciais ativos é bloqueada, comprovado por teste.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

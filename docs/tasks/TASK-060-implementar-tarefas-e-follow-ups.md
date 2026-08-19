# TASK-060 — Implementar tarefas e follow-ups

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-059 (Implementar atividades CRM) — tarefas e follow-ups podem se originar de uma atividade registrada e compartilham o mesmo vínculo polimórfico a cliente/lead/oportunidade.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar tarefas e follow-ups com vencimento, prioridade, responsável e conclusão, com listagem de pendências do dia/semana — a base que a TASK-152 (notificações de CRM) consumirá futuramente.

## Escopo técnico

- Entidade `CrmTask` (id, organizationId, título, descrição, vínculo opcional a cliente/lead/oportunidade/atividade de origem, responsável (`userId`), data/hora de vencimento, prioridade (baixa/média/alta), status (pendente/concluída — "atrasada" é calculada, não persistida diretamente), data de conclusão).
- Casos de uso: `CreateCrmTask`, `CompleteCrmTask`, `RescheduleCrmTask`, `ListPendingTasksForToday`/`ForWeek`.
- Página/seção `CrmTaskListPage` (ou seção na home do representante) agrupando tarefas por "hoje", "esta semana" e "atrasadas".
- Destaque visual (badge/cor combinado com ícone, nunca só cor) para tarefas atrasadas.
- Marcação de conclusão rápida (um toque) a partir da lista.

## Regras de negócio e restrições

- Tarefa é considerada atrasada quando a data de vencimento é anterior ao momento atual e o status ainda é pendente — cálculo derivado, nunca um status gravado que possa ficar dessincronizado.
- Reagendar uma tarefa deve preservar o histórico da data original, para análise futura de atraso recorrente.
- Apenas o responsável (ou perfis com permissão de gestão, ex.: `SALES_MANAGER`/`ADMIN`) pode concluir ou reagendar a tarefa de outro usuário.
- Esta task não implementa notificações push — apenas o modelo, os casos de uso e a listagem; a entrega via notificação é escopo de TASK-152.

## Testes obrigatórios

- Teste de cálculo de "atrasada" com datas limite (exatamente agora, um segundo antes/depois).
- Teste de caso de uso: concluir tarefa, reagendar tarefa preservando a data original.
- Teste de RBAC: usuário sem permissão não consegue concluir tarefa de outro responsável.
- Teste de widget: agrupamento hoje/semana/atrasadas, marcação de conclusão em um toque.

## Critérios de aceite

- Tarefas com vencimento, prioridade, responsável e conclusão funcionam fim a fim.
- Listagem de pendências do dia/semana correta, com atrasadas destacadas visualmente sem depender só de cor.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)

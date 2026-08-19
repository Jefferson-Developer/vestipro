# TASK-152 — Implementar notificações de CRM

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-151 (central de notificações internas, onde as notificações de CRM são
exibidas), TASK-060 (tarefas e follow-ups, origem dos lembretes)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Gerar lembretes de atividades e follow-ups vencidos ou próximos do vencimento, entregues na central
de notificações (TASK-151) em um horário configurável, evitando que o vendedor perca compromissos
comerciais com clientes.

## Escopo técnico

- Cloud Function agendada (ou trigger em criação/atualização de tarefa/follow-up de TASK-060) que
  gera notificação categoria "CRM" quando uma atividade está próxima do vencimento ou já vencida.
- Categorizar na central de notificações (TASK-151): lembrete de follow-up, tarefa vencida,
  atividade próxima.
- Horário de envio configurável por usuário (ex.: lembretes apenas entre 8h e 18h no fuso do
  usuário) — a regra de janela de horário é a mesma implementada em TASK-155 (quiet hours), não deve
  ser duplicada aqui.
- Deep link para a atividade/oportunidade/cliente relacionado, reaproveitando o mecanismo de
  navegação de TASK-151.

## Regras de negócio e restrições

- Lembrete não é reenviado repetidamente para a mesma atividade vencida (regra de deduplicação/
  cooldown).
- Respeitar as preferências de comunicação do usuário (TASK-154): se notificações de CRM estiverem
  desativadas, a Function não gera push (o registro interno pode ser mantido conforme a preferência
  configurada).
- Notificação vai apenas para o vendedor responsável pela atividade; gestor com visibilidade da
  equipe pode recebê-la conforme RBAC, mas nunca outro vendedor sem relação com a atividade.

## Testes obrigatórios

- Teste da Function/trigger no Emulator: atividade vencendo gera notificação; atividade já notificada
  não duplica o envio.
- Teste de RBAC: notificação vai apenas ao responsável (e ao gestor, quando aplicável).
- Teste de respeito à preferência de comunicação desativada (integração com TASK-154).
- Teste de deep link para a atividade/oportunidade correta.
- Teste do horário configurável interagindo corretamente com o quiet hours (TASK-155).

## Critérios de aceite

- Vendedor recebe lembrete de follow-up/tarefa vencida ou próxima sem duplicidade.
- Notificação respeita as preferências e o horário configurados pelo usuário.
- Apenas o responsável (e gestor autorizado) recebe a notificação.
- Deep link leva diretamente à atividade relacionada.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
